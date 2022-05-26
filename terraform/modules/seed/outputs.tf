output "ip_addresses" {
  value = [for i in range(var.num_instances) : aws_eip.seed[i].public_ip]
}
