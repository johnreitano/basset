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

resource "null_resource" "setup_primary_validator" {
  count      = var.num_instances == 0 ? 0 : 1
  depends_on = [aws_eip.validator[0], aws_instance.validator[0]]
  provisioner "local-exec" {
    command = "cd ..; rm -f /tmp/basset-0.tar.gz; git ls-files | tar -czvf /tmp/basset-0.tar.gz -T -"
  }
  provisioner "file" {
    source      = "/tmp/basset-0.tar.gz"
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
      "echo setting up primary validator",
      "rm -rf ~/basset && mkdir ~/basset && cd ~/basset && tar -xzvf /tmp/basset.tar.gz",
      "cd ~/basset && terraform/modules/validator/setup.sh 0 ${aws_eip.validator[0].public_ip} ${aws_eip.validator[1].public_ip} ${aws_eip.validator[2].public_ip}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[0].public_ip
    }
  }
  # provisioner "local-exec" {
  #   command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.basset/config/genesis.json genesis_0.json"
  # }
}

resource "null_resource" "setup_secondary_validators" {
  depends_on = [null_resource.setup_primary_validator[0]]

  for_each = { for i in range(1, max(var.num_instances, 1)) : i => i }

  provisioner "local-exec" {
    command = "cd ..; git ls-files | tar -czvf /tmp/basset.tar.gz -T -)"
  }

  provisioner "file" {
    source      = "/tmp/basset-${each.value}.tar.gz"
    destination = "/tmp/basset.tar.gz"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[each.value].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo provisioning validator node ${each.value}",
      "rm -rf ~/basset && mkdir ~/basset && cd ~/basset && tar -xzvf /tmp/basset.tar.gz",
      "cd ~/basset && terraform/modules/validator/setup.sh ${each.value} ${aws_eip.validator[0].public_ip} ${aws_eip.validator[1].public_ip} ${aws_eip.validator[2].public_ip}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[each.value].public_ip
    }
  }
}


resource "null_resource" "start_validators" {
  depends_on = [null_resource.setup_primary_validator[0], null_resource.setup_secondary_validators[0], null_resource.setup_secondary_validators[1]]
  count      = var.num_instances
  provisioner "remote-exec" {
    inline = [
      "cd ~/basset && terraform/modules/validator/start.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.validator[count.index].public_ip
    }
  }
}
