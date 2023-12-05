provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "sjoshi73-project-backend"
    key    = "project/application/terraform.tfstate"
    region = "us-east-1"
  }
}
