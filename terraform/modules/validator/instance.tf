resource "aws_instance" "validator" {
  count                       = 3
  ami                         = var.ami
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.validator.id
  key_name                    = var.ssh_keypair
  vpc_security_group_ids      = [aws_security_group.validator.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-${count.index}"
  }

}
resource "aws_eip" "validator" {
  count    = 3
  instance = aws_instance.validator[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-eip-${count.index}"
  }
}

locals {
  validator_ips_str = join(",", [for node in aws_eip.validator : node.public_ip])
}

resource "null_resource" "setup_validator" {
  depends_on = [aws_eip.validator[0], aws_eip.validator[1], aws_eip.validator[2]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      rm -f /tmp/basset.tar.gz
      cd ..
      git ls-files | tar -czf /tmp/basset.tar.gz -T -
    EOF
  }

  provisioner "file" {
    source      = "/tmp/basset.tar.gz"
    destination = "/tmp/basset.tar.gz"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo provisioning validator node ${count.index}",
      "pkill bassetd",
      "rm -rf ~/basset",
      "mkdir ~/basset",
      "cd ~/basset",
      "tar -xzf /tmp/basset.tar.gz",
      "terraform/modules/validator/setup-validator.sh ${count.index} '${local.validator_ips_str}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" != "0" ]]; then
        mkdir -p "/tmp/genesis-${random_id.id[0].hex}/"
        echo "node ${count.index}: here1"
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[count.index].public_ip}:.basset/config/gentx/gentx-\*.json "/tmp/genesis-${random_id.id[0].hex}/"
        echo "node ${count.index}: here2"
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa "/tmp/genesis-${random_id.id[0].hex}/\*" ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/gentx/
        echo "node ${count.index}: here3"
      fi
      EOF
  }
}

resource "random_id" "id" {
  count       = var.num_instances
  byte_length = 8
}


resource "null_resource" "start_validator" {
  depends_on = [null_resource.setup_validator[0], null_resource.setup_validator[1], null_resource.setup_validator[2], ]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" != "0" ]]; then
        sleep 30 # wait for genesis file to be generated on primary validator
        mkdir -p "/tmp/genesis-${random_id.id[count.index].hex}/"
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/genesis.json "/tmp/genesis-${random_id.id[count.index].hex}/genesis.json"        
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa "/tmp/genesis-${random_id.id[count.index].hex}/genesis.json" ubuntu@${aws_eip.validator[count.index].public_ip}:.basset/config/genesis.json
        rm -rf "${random_id.id[count.index].hex}"
      fi
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo provisioning validator node ${count.index}",
      "terraform/modules/validator/start-validator.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }
}
