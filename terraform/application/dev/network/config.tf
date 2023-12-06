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
    bucket         = "aafinal-project-backend"
    key            = "project/network/terraform.tfstate"
    region         = "us-east-1"
    profile = "voclabs/user2772561=rvsharma2@myseneca.ca"
    //cd ../dynamodb_table = "aafinal-state-locking"
  }
}

provider "aws" {
  region = "us-east-1"
}

