output "default_tags" {
  value = {
    "Owner" = "Actual Enthusiasm"
    "App" = "Web"
  }
}

output "prefix" {
  value = "project"
}

output "instance_type" {
  value = {
    production = "t3.small",
    staging = "t2.micro"
  }
}

output "s3_dev_backend_bucket" {
  value = "sjoshi73-project-backend"
}
output "s3_prod_backend_bucket" {
  value = "acs730-assignment-revati333"
}

output state_lock_table {
  value       = "terraform-state-lock-dynamo"
  description = "dynamodb table for state locking"
}
