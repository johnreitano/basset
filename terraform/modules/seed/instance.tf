resource "aws_instance" "seed" {
  count                       = 3
  ami                         = var.ami
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.seed.id
  key_name                    = var.ssh_keypair
  vpc_security_group_ids      = [aws_security_group.seed.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-${count.index}"
  }
}

resource "aws_eip" "seed" {
  count    = 3
  instance = aws_instance.seed[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-eip-${count.index}"
  }
}

locals {
  seed_ips_str      = join(",", [for node in aws_eip.seed : node.public_ip])
  validator_ips_str = join(",", var.validator_ips)
}

resource "null_resource" "setup_seed" {
  depends_on = [aws_eip.seed[0], aws_eip.seed[1], aws_eip.seed[2]]
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
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo provisioning seed node ${count.index}",
      "pkill bassetd",
      "rm -rf ~/basset",
      "mkdir ~/basset",
      "cd ~/basset",
      "tar -xzf /tmp/basset.tar.gz",
      "terraform/modules/seed/setup-seed.sh ${count.index} '${local.seed_ips_str}' '${local.validator_ips_str}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}
