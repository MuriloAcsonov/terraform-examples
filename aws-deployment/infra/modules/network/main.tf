resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-igw"
  }
}

resource "aws_eip" "nat_eip" {
  count      = length(aws_subnet.public_subnet) 

  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}   

resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.public_subnet)

  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  depends_on    = [aws_internet_gateway.ig, aws_subnet.public_subnet]

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-nat"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  
  count                   = length(var.public_subnets_cidr)

  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  
  count                   = length(var.private_subnets_cidr)
  
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  count         = length(var.availability_zones)

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-route-table"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-public-route-table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway" {
  count         = length(var.availability_zones)

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)

  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count           = length(var.private_subnets_cidr)

  subnet_id       = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

}