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

resource "null_resource" "setup_validator_and_generate_gentx" {
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
      "echo setting up validator node and generating gentx",
      "pkill bassetd",
      "rm -rf ~/basset",
      "mkdir ~/basset",
      "cd ~/basset",
      "tar -xzf /tmp/basset.tar.gz",
      "terraform/modules/validator/build-client.sh",
      "terraform/modules/validator/configure-validator.sh ${count.index} '${local.validator_ips_str}'",
      "terraform/modules/validator/generate-gentx.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  # copy gentxs to first validator node from other secondary validator nodes
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" != "0" ]]; then
        rm -rf /tmp/gentx
        mkdir /tmp/gentx
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[count.index].public_ip}:.basset/config/gentx/* /tmp/gentx/
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/gentx/* ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/gentx/
      fi
      EOF
  }
}

resource "null_resource" "generate_genesis_file" {
  depends_on = [null_resource.setup_validator_and_generate_gentx[0], null_resource.setup_validator_and_generate_gentx[1], null_resource.setup_validator_and_generate_gentx[2]]
  count      = var.num_instances == 0 ? 0 : 1

  provisioner "remote-exec" {
    inline = [
      "echo generating genesis file on validator node 0",
      "cd ~/basset",
      "terraform/modules/validator/generate-genesis-file.sh",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[0].public_ip
    }
  }

  # copy genesis file to temporary file for later use
  provisioner "local-exec" {
    command = <<-EOF
      rm -f /tmp/genesis.json
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/genesis.json /tmp/genesis.json
    EOF
  }
}


resource "null_resource" "start_validator" {
  depends_on = [null_resource.generate_genesis_file[0]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" != "0" ]]; then
        # for secondary validator nodes, get copy of genesis
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/genesis.json ubuntu@${aws_eip.validator[count.index].public_ip}:.basset/config/genesis.json
      fi
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo provisioning validator node ${count.index}",
      "cd ~/basset",
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
