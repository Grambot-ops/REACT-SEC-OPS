# terraform/networking.tf

# 1. Internet gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name =  "React-sec-ops-IGW"
  }
}

# 2. public route table - directs 0.0.0.0/0 to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "React-sec-ops-public-RT"
  }
}

# now we associate the route table we created to the subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# 3.Nat gateway for private Subnets (allows outbound, not inbound)
# needs an elastic ip

// says that this is deprecated it is no longer required but we are using it
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "react-sec-ops-NAT-EIP"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public_a.id
  depends_on = [ aws_internet_gateway.main ]

  tags = {
    Name = "react-sec-ops-NAT-GW"
  }
}

# 4. Private Route Table - directs 0.0.0.0/0 to the NAT GW
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
   name = "react-sec-ops-private-RT" 
  }
}

# now we associate the route table we created to the subnets
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}