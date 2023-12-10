variable "vpc_cidr" {
  type        = string
  default     = "10.250.0.0/16"
  description = "VPC Cidr Block"
}

variable "env" {
  type        = string
  default     = "prod"
  description = "Environment of the application"
}

variable "public_subnet_cidr_blocks_prod" {
  type        = list(string)
  default     = ["10.250.0.0/24", "10.250.1.0/24", "10.250.3.0/24"]
  description = "Public IP Subnets"
}

variable "private_subnet_cidr_blocks_prod" {
  type        = list(string)
  default     = ["10.250.4.0/24", "10.250.5.0/24", "10.250.6.0/24"]
  description = "Public IP Subnets"
}


