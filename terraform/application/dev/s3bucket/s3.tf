#  Define the provider
provider "aws" {
  region = "us-east-1"
}


# Use remote state to retrieve the data
data "terraform_remote_state" "network" { 
  backend = "s3"
  config = {
    bucket = "sjoshi73-project-backend"
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"   
    
  }
}
#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-enable-bucket-logging
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
  #tfsec:ignore:aws-s3-block-public-acls
  block_public_acls       = false
  #tfsec:ignore:aws-s3-block-public-policy
  block_public_policy     = false
  #tfsec:ignore:aws-s3-ignore-public-acls
  ignore_public_acls      = false
  #tfsec:ignore:aws-s3-no-public-buckets
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
