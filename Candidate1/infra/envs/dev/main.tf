# Specify the Terraform version
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS provider configuration for the dev environment
provider "aws" {
  region  = var.aws_region
  profile = "turbot"
}


module "vpc" {
  source         = "../../modules/vpc"
  vpc_cidr_block = "10.0.0.0/16"
  vpc_name       = "dev-vpc"
  subnet_cidr_1  = "10.0.1.0/24"
  subnet_cidr_2  = "10.0.2.0/24"
  region         = var.aws_region
}

# Generate an SSH key pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an EC2 key pair in AWS using the generated key
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-ec2-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.my_key.private_key_pem
  filename = "${path.module}/my-ec2-key.pem"

  # Set file permissions to be secure
  file_permission = "0400"
}

module "ec2_instance" {
  source            = "../../modules/ec2"
  instance_name     = var.instance_name
  instance_type     = var.instance_type
  subnet_id         = module.vpc.subnet_2_id
  security_group_id = module.vpc.ssh_sg_id
  key_name          = aws_key_pair.my_key_pair.key_name

  depends_on = [aws_key_pair.my_key_pair]
}