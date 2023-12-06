#  Define the provider
provider "aws" {
  region = "us-east-1"
}


# Use remote state to retrieve the data
data "terraform_remote_state" "network" { 
  backend = "s3"
  config = {
    bucket = "aafinal-project-backend"
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"   
    
  }
}

resource "aws_s3_bucket" "web_s3_bucket" {
  bucket = var.web-bucket
}

resource "aws_s3_bucket_ownership_controls" "web_s3_ownership_controls" {
  bucket = aws_s3_bucket.web_s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "web_s3_public_access_block" {
  bucket = aws_s3_bucket.web_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "web_s3_bucket_policy" {
  bucket = aws_s3_bucket.web_s3_bucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.web_s3_bucket.id}/*"
      
    }
  ]
}
EOF
  depends_on = [
    aws_s3_bucket_public_access_block.web_s3_public_access_block
  ]

}
