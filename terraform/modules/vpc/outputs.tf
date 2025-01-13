output "infra_vpc" {
  value = aws_vpc.infra_vpc
}

output "infra_subnets" {
  value = aws_subnet.infra_subnets
}


output "infra_subnet_ids" {
  value = aws_subnet.infra_subnets[*].id
}