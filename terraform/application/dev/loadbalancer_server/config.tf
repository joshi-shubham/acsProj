provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket     = "aafinal-project-backend"
    key        = "project/application/terraform.tfstate"
    region     = "us-east-1"
    profile    = "AROA2OTTT4HOZUB2Y7PEG:user2772561=rvsharma2@myseneca.ca"
    secret_key = "cU1wpEy+X/gv8GAUgB6IMQ/AD/6tX5tmMSLbQor7"
    access_key = "ASIA2OTTT4HO5PERD6LF"
    token      = "FwoGZXIvYXdzEC8aDMr3XwETaM7eLg/8yiLGAeNMatxXGtc1k45a+d08SK7Jj/HnYNeZDu9EWgy0NI8OD+vjfs2Qj7m+cgvoU7yIOauZEvCA1EZooyTXUgCDUDlQeOSSF99ZclnhBUoki9i11uRzIg4LM+O3Bnp4pPnJEx/S3uD6xW18bLFGugqDxmgnxgAZ7iJmVLYzNBkWZTHwMHm2fayB7YnLcFMwLIwKLSSUIEUBBZoMeKe+EtveGi5VsByaPe+zZU42d//pFBJvpXDV4AopJN2ENF0yhkUdbkn/s9PznCihiMCrBjItDI0uU4n/EuURGAd/HdWyb9TdG/qcZYtyx2ZFM/wQAJCjqjNGdtb6BXGEJLQY"
    dynamodb_table = "aafinal-state-locking"
  }
}
