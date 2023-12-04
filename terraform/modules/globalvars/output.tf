output "default_tags" {
  value = {
    "Owner" = "Actual Enthusiasm"
    "App" = "Web"
  }
}

output "prefix" {
  value = "Project"
}

output "instance_type" {
  value = {
    production = "t3.small",
    staging = "t2.micro"
  }
}

output "s3_dev_backend_bucket" {
  value = "revati333-project-backend"
}
output "s3_prod_backend_bucket" {
  value = "acs730-assignment-revati333"
}
