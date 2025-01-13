resource "aws_vpc" "infra_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "infra-vpc"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "infra_subnets" {
  count             = 2
  vpc_id            = aws_vpc.infra_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.infra_vpc.cidr_block, 4, count.index + 1)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "infra-subnet-${count.index + 1}"
  }
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "infra_igw" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "infra-igw"
  }
}

# Create a route table for the VPC
resource "aws_route_table" "infra_route_table" {
  vpc_id = aws_vpc.infra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra_igw.id
  }

  tags = {
    Name = "infra-route-table"
  }
}

# Associate the route table with the subnets
resource "aws_route_table_association" "infra_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.infra_subnets[count.index].id
  route_table_id = aws_route_table.infra_route_table.id
}
