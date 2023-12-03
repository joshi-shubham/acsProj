# Instance type
variable "instance_type" {
  # default = {
  #   "prod"    = "t3.medium"
  #   "test"    = "t3.micro"
  #   "staging" = "t2.micro"
  #   "dev"     = "t2.micro"
  # }
  description = "Type of the instance"
  type        = map(string)
}

# Variable to signal the current environment 
variable "env" {
  # default     = "staging"
  type        = string
  description = "Deployment Environment"
}
variable "ami" {
  description = "ami of ec2 instance"
  type        = string
  # default     = "ami-0130c3a072f3832ff"
}


variable "service_ports" {
  type        = list(string)
  # default     = ["80", "22","443"]
  description = "Ports that should be open on a webserver"
}


