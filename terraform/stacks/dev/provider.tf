provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "EKS:Environment" = var.environment_name
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your kubeconfig file
}

