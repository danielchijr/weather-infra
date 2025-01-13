
resource "aws_security_group" "https_sg" {
  name        = "eks-https-sg"
  description = "Security group for HTTPS and HTTP access to EKS cluster"
  vpc_id      = var.infra_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-https-sg"
  }
}


# Create a security group for SSH access
resource "aws_security_group" "ssh_sg" {
  name        = "eks-ssh-sg"
  description = "Security group for SSH access to EKS cluster"
  vpc_id      = var.infra_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-ssh-sg"
  }
}

# Create an EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids = var.infra_subnets[*].id

    security_group_ids = [
      aws_security_group.https_sg.id,
      aws_security_group.ssh_sg.id
    ]
  }
}



data "tls_certificate" "eks_cert" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.example.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.example.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "example" {
  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
  name               = "example-vpc-cni-role"
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example.name
}



resource "aws_eks_addon" "cni_addon" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni" 

  addon_version = "v1.13.4-eksbuild.1" 
  resolve_conflicts_on_create = "OVERWRITE"
  # resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "coredns_addon" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  # addon_version               = "v1.10.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"

  # configuration_values = jsonencode({
  #   replicaCount = 4
  #   resources = {
  #     limits = {
  #       cpu    = "100m"
  #       memory = "150Mi"
  #     }
  #     requests = {
  #       cpu    = "100m"
  #       memory = "150Mi"
  #     }
  #   }
  # })
}

resource "aws_launch_template" "ami_lt" {
  name_prefix   = "ami-lt"
  instance_type = "m5.large"
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
    }
  }

  network_interfaces {
    associate_public_ip_address = true
  }
}

resource "aws_eks_node_group" "managed_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "managed-node-group"
  node_role_arn   = var.eks_role_arn
  subnet_ids = var.infra_subnets[*].id

  scaling_config {
    desired_size = 6
    max_size     = 6
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    name = aws_launch_template.ami_lt.name
    version = "1"
  }
}



# Configure kubectl to communicate with the cluster
resource "null_resource" "kubectl_config" {
  depends_on = [aws_eks_cluster.eks_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name} --region ${var.aws_region}"
  }
}
