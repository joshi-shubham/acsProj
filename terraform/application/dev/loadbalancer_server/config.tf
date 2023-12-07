provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "aafinal-project-backend"
    key            = "project/application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
