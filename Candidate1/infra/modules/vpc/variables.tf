variable "region" {
  description = "Which AWS region are we provisioning resources in?"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "subnet_cidr_1" {
  description = "The CIDR block for the first subnet"
  type        = string
}

variable "subnet_cidr_2" {
  description = "The CIDR block for the second subnet"
  type        = string
}
