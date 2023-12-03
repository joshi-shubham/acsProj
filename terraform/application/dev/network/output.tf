output "vpc_id" {
  value = module.vpc_dev.vpc_id
}

output "public_subnet_id" {
  value = module.vpc_dev.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc_dev.private_subnet_id
}

output "public_route_tables" {
  value = module.vpc_dev.public_route_tables
}

output "private_route_tables" {
  value = module.vpc_dev.private_route_tables
}

output "vpc_cidr" {
  value = var.vpc_cidr
}
