terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "cccastro2-project-backend-prod"
    key            = "project/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"

  }
}

provider "aws" {
  region = "us-east-1"
}

