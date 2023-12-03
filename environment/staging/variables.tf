# Default tags
variable "default_tags" {
  default = {
    "assignment"="FINAL"
  }
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}

# Name prefix
variable "prefix" {
  type        = string
  default     = "final-project"
  description = "Name prefix"
}

# Provision public subnets in custom VPC
variable "public_subnet_cidrs" {
  default     = ["10.200.0.0/24","10.200.1.0/24","10.200.2.0/24"]
  type        = list(string)
  description = "Public Subnet CIDRs"
}

# Provision private subnets in custom VPC
variable "private_subnet_cidrs" {
  default     = ["10.200.3.0/24","10.200.4.0/24","10.200.5.0/24"]
  type        = list(string)
  description = "Private Subnet CIDR"
}

# VPC CIDR range
variable "vpc_cidr" {
  default     = "10.200.0.0/16"
  type        = string
  description = "VPC to host static web site"
}

# Variable to signal the current environment 
variable "env" {
  default     = "staging"
  type        = string
  description = "Deployment Environment"
}

variable "instance_type" {
  default = {
    "prod"    = "t3.medium"
    "test"    = "t3.micro"
    "staging" = "t2.micro"
    "dev"     = "t2.micro"
  }
  description = "Type of the instance"
  type        = map(string)
}

variable "ami" {
  description = "ami of ec2 instance"
  type        = string
  default     = "ami-0130c3a072f3832ff"
}


variable "service_ports" {
  type        = list(string)
  default     = ["80", "22","443"]
  description = "Ports that should be open on a webserver"
}

