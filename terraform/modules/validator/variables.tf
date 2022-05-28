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

variable "should_generate_genesis_file" {
  description = "true indicates that a new genesis block should be generated"
  type        = bool
  default     = false
}

variable "num_instances" {
  description = "the number of instances"
  type        = number
}

variable "ami" {
  description = "the ami to use for instances"
}
