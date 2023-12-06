# Default tags
variable "default_tags" {
  default = {
    "assignment" = "FINAL"
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
  default     = "ami-0230bd60aa48260c6"
}


variable "service_ports_webservers" {
  type        = list(string)
  default     = ["80", "443", "22"]
  description = "Ports that should be open on a webserver"
}

variable "service_ports_loadbalancer" {
  type        = list(string)
  default     = ["80", "443"]
  description = "Ports that should be open on a webserver"
}



