terraform {
  backend "s3" {
    bucket         = "dev-tf-state-bucket"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "dev-terraform-state-lock"
    encrypt        = true
  }
}
