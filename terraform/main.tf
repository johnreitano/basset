module "validator" {
  source      = "./modules/validator"
  env         = var.env
  project     = var.project
  ssh_keypair = var.ssh_keypair
  vpc_id      = aws_vpc.vpc.id
  igw_id      = aws_internet_gateway.igw.id
  subnet_cidr = var.validator_subnet_cidr
  ami         = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances = var.num_validator_instances
}

module "seed" {
  source      = "./modules/seed"
  env         = var.env
  project     = var.project
  ssh_keypair = var.ssh_keypair
  vpc_id      = aws_vpc.vpc.id
  igw_id      = aws_internet_gateway.igw.id
  subnet_cidr = var.seed_subnet_cidr
  ami         = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances = var.num_seed_instances
}

module "explorer" {
  source      = "./modules/explorer"
  env         = var.env
  project     = var.project
  ssh_keypair = var.ssh_keypair
  vpc_id      = aws_vpc.vpc.id
  igw_id      = aws_internet_gateway.igw.id
  subnet_cidr = var.explorer_subnet_cidr
  ami         = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
}

