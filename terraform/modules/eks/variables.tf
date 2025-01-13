
variable "aws_region" {
  type        = string
  description = "Default region for aws provider"
}

variable "cluster_name" {
  type        = string
  description = "Name of EKS cluster"
}

variable "infra_vpc" {}

variable "infra_subnets" {}

variable "eks_role_arn" {}

