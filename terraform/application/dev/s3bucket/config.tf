terraform {
  backend "s3" {
    bucket = "aafinal-project-backend"
    key    = "project/web-bucket/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}