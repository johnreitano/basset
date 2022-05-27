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

resource "null_resource" "setup_seed2" {
  depends_on = [aws_eip.seed[0], aws_eip.seed[1], aws_eip.seed[2]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = "cd ..; (git ls-files | tar -czvf /tmp/basset.tar.gz -T -)"
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
      "rm -rf ~/basset && mkdir ~/basset && cd ~/basset && tar -xzvf /tmp/basset.tar.gz",
      "cd ~/basset && terraform/modules/seed/setup.sh ${count.index} '${join(",", [for node in aws_eip.seed : node.public_ip])}' '${join(",", var.validator_ips)}'",
      "cd ~/basset && terraform/modules/seed/start.sh ${count.index}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}
