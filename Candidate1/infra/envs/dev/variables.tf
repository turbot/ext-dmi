variable "aws_region" {
  description = "Which AWS region are we provisioning resources in?"
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of EC2 instance"
  default     = "MyInstance-Dev"
}

variable "instance_type" {
  description = "Instance type to use to build EC2 instance"
  default     = "t3.micro"
}