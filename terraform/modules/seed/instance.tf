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

resource "null_resource" "provision_instance" {
  count = var.num_instances
  # depends_on = [aws_eip.seed[count.index], aws_instance.seed[count.index]]

  provisioner "file" {
    source      = "modules/seed/setup.sh"
    destination = "/tmp/setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.seed[count.index].public_ip
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "echo provisioning seed node ${count.index}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}
