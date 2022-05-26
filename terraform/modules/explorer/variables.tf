variable "env" {
  description = "Deployment Environment"
}

variable "project" {
  description = "Project name"
}

variable "vpc_id" {
  description = "The vpc id for the project"
}

variable "igw_id" {
  description = "The id of the internet gatewy used by the project"
}

variable "subnet_cidr" {
  description = "The cidr for the subnet"
}

variable "ssh_keypair" {
  description = "SSH keypair to use for EC2 instance"
}

variable "ami" {
  description = "the ami to use for instances"
}
