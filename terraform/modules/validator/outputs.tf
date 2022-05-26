output "ip_addresses" {
  value = [for i in range(var.num_instances) : aws_eip.validator[i].public_ip]
}
