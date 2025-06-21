# terraform/main.tf

# we configured the providers in providers.tf
# vpc - Isolated network for our application

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support =  true
  enable_dns_hostnames = true
  tags = {
    name = "React-sec-ops-VPC"
  }
}


# 2. subnets - we need public (for internet-facing resources like ALB/NAT) 
# and private (for secure resources like api/db)

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true  # enable to get public ips

  tags = {
    Name = "react-sec-ops-public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "react-sec-ops-public-subnet-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a" # same AZ as public_a
  map_public_ip_on_launch = true

  tags = {
    Name = "react-sec-ops-private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b" # same AZ as public_b
  map_public_ip_on_launch = true

  tags = {
    Name = "react-sec-ops-private-subnet-b"
  }
}

