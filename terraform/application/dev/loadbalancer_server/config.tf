provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "cccastro2-project-backend-staging"
    key            = "project/application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
