variable "region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  default     = "default"
  type        = string
}
variable "env" {
  description = "The env - either 'testnet' or 'mainnet' -- used as suffix of resource names"
  default     = "testnet"
  type        = string
}

variable "project" {
  description = "The name of this project -- used as prefix of resource names"
  default     = "basset"
  type        = string
}

variable "ssh_keypair" {
  description = "SSH keypair to use for EC2 instances"
  default     = "john-pubkey"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
  default     = "10.0.0.0/16"
}

variable "seed_subnet_cidr" {
  description = "CIDR block for seed subnet"
  default     = "10.0.1.0/24"
}

variable "validator_subnet_cidr" {
  description = "CIDR block for validator subnet"
  default     = "10.0.2.0/24"
}

variable "explorer_subnet_cidr" {
  description = "CIDR block for db subnet"
  default     = "10.0.3.0/24"
}

variable "num_validator_instances" {
  description = "number of validator instances"
  default     = 1
}

variable "num_seed_instances" {
  description = "number of seed instances"
  default     = 1
}

