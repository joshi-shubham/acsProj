variable "vpc_cidr" {
  type        = string
  default     = "10.200.0.0/16"
  description = "VPC Cidr Block"
}

variable "env" {
  type        = string
  default     = "staging"
  description = "Environment of the application"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.200.0.0/24", "10.200.1.0/24", "10.200.3.0/24"]
  description = "description"
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.200.4.0/24", "10.200.5.0/24", "10.200.6.0/24"]
  description = "description"
}


