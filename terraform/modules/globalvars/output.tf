output "default_tags" {
  value = {
    "Owner" = "Actual Enthusiasm"
    "App"   = "Web"
  }
}

output "prefix" {
  value = "project"
}

output "instance_type" {
  value = {
    production = "t3.small",
    staging    = "t2.micro"
  }
}

output "s3_dev_backend_bucket" {
  value = "cccastro2-project-backend-staging"
}
output "s3_prod_backend_bucket" {
  value = "cccastro2-project-backend-prod"
}

output "state_lock_table_prod" {
  value       = "terraform-state-lock-dynamo"
  description = "dynamodb table for state locking"
}

output "state_lock_table_staging" {
  value       = "terraform-state-lock-dynamo-staging"
  description = "dynamodb table for state locking"
}
