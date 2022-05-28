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

resource "null_resource" "create_genesis_block" {
  count      = var.should_generate_genesis_file ? 1 : 0
  depends_on = [aws_eip.validator[0]]

  provisioner "local-exec" {
    command = "cd ..; rm -f /tmp/basset.tar.gz; git ls-files | tar -czf /tmp/basset.tar.gz -T -"
  }
  provisioner "file" {
    source      = "/tmp/basset.tar.gz"
    destination = "/tmp/basset.tar.gz"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[0].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo generating genesis block on primary validator",
      "rm -rf ~/basset && mkdir ~/basset && cd ~/basset && tar -xzvf /tmp/basset.tar.gz",
      "cd ~/basset && terraform/modules/validator/generate-genesis-file.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[0].public_ip
    }
  }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/genesis.json genesis.json"
  }
}

locals {
  validator_ips_str = join(",", [for node in aws_eip.validator : node.public_ip])
}

resource "null_resource" "setup_validator" {
  depends_on = [aws_eip.validator[0], aws_eip.validator[1], aws_eip.validator[2]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = "cd ..; rm -f /tmp/basset.tar.gz; git ls-files | tar -czf /tmp/basset.tar.gz -T -"
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
      "rm -rf ~/basset && mkdir ~/basset && cd ~/basset && tar -xzf /tmp/basset.tar.gz",
      "cd ~/basset && terraform/modules/validator/setup-validator.sh ${count.index} '${local.validator_ips_str}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }
}

