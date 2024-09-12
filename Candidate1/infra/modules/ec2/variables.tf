variable "instance_name" {
  description = "Name of EC2 instance"
}

variable "instance_type" {
  description = "Instance type to use to build EC2 instance"
}

variable "ami_id" {
  description = "AMI to use to build EC2 instance"
  default     = "ami-0147bd0a180d521bd" # Amazon Linux 2 AMI
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be created"
}

variable "key_name" {
  description = "Key pair name to allow SSH access"
}

variable "security_group_id" {
  description = "ID of security group to assign to EC2 instance"
}