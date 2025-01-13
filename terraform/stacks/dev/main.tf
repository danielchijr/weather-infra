
module "vpc" {
  source     = "../../modules/vpc"
  aws_region = var.aws_region
  vpc_cidr   = var.vpc_cidr
}

resource "aws_iam_policy" "eks_cni_policy" {
  name        = "AmazonEKS_CNI_Policy"
  description = "Policy to grant necessary permissions for Amazon EKS CNI"

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "ec2:UnassignPrivateIpAddresses",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:AssignPrivateIpAddresses"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "IPV4"
      },
      {
        "Action" : "ec2:CreateTags",
        "Effect" : "Allow",
        "Resource" : "arn:aws:ec2:*:*:network-interface/*",
        "Sid" : "CreateTags"
      }
    ],
    "Version" : "2012-10-17"
  })
}



# Create an IAM role for EKS service
resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        },
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }

    EOF
}

# Attach the required policies to the EKS role
resource "aws_iam_role_policy_attachment" "eks_role_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
#   role       = aws_iam_role.eks_role.name

#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_policy" {
  role = aws_iam_role.eks_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_trust_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "eks_role_attachment" {
  name       = "eks-role-attachment"
  roles      = [aws_iam_role.eks_role.name]
  policy_arn = aws_iam_policy.eks_cni_policy.arn
}




module "eks" {
  source        = "../../modules/eks"
  aws_region    = var.aws_region
  cluster_name  = var.cluster_name
  infra_vpc     = module.vpc.infra_vpc
  infra_subnets = module.vpc.infra_subnets
  eks_role_arn  = aws_iam_role.eks_role.arn

}

# module "jenkins" {
#   source        = "../../modules/jenkins"
#   vpc_id        = module.vpc.infra_vpc.id
#   infra_subnets = module.vpc.infra_subnets
#   eks_role_arn  = aws_iam_role.eks_role.arn

#   depends_on = [module.eks]
# }


