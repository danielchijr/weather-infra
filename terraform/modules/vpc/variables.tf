variable "aws_region" {
  type        = string
  description = "Default region for aws provider"
}

variable "vpc_cidr" {
  type        = string
  description = "Cidr block for created vpc"
  default     = "10.0.0.0/16"
}


# variable "availability_zones" {}