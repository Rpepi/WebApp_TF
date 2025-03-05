
resource "aws_vpc" "main-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "webapp-vpc"
    }
}

resource "aws_internet_gateway" "vpc-gw" {
    vpc_id = aws_vpc.main-vpc.id
    tags = {
      Name = "webapp-igw"
    }
}

resource "aws_subnet" "public_a" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-3a"
    map_public_ip_on_launch = true
    tags = {
      Name = "public-subnet-a"
    }
}

resource "aws_subnet" "public_b" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-west-3b"
    map_public_ip_on_launch = true
    tags = {
      Name = "public-subnet-b"
    }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-gw.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Association Route Table aux Subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}