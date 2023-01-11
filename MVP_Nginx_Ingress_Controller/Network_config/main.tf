terraform {
  required_providers{
    aws ={
        source = "hashicorp/aws"
        version = ">=2.7.0"
        configuration_aliases = [ aws ]
    }
  }
}

resource "aws_vpc" "clouda-commerce"{
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags ={
        Name = "clouda-commerce"
    }
}

resource "aws_subnet" "clcom-private-1" {
  vpc_id            = aws_vpc.clouda-commerce.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "${data.aws_region.current.id}a"

  tags = {
    "Name"                                      = "clouda-commerce-private-1"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}-Green" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}-Blue" = "owned"
  }
}

resource "aws_subnet" "clcom-private-2" {
  vpc_id            = aws_vpc.clouda-commerce.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "${data.aws_region.current.id}b"

  tags = {
    "Name"                                      = "clouda-commerce-private-2"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}-Green" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}-Blue" = "owned"
  }
}

resource "aws_subnet" "clcom-public-1" {
  vpc_id                  = aws_vpc.clouda-commerce.id
  cidr_block              = "10.0.32.0/20"
  availability_zone       = "${data.aws_region.current.id}a"
  map_public_ip_on_launch = false

  tags = {
    "Name"                                      = "clouda-commerce-public-1"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}-Green" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}-Blue" = "owned"
  }
}

resource "aws_subnet" "clcom-public-2" {
  vpc_id                  = aws_vpc.clouda-commerce.id
  cidr_block              = "10.0.48.0/20"
  availability_zone       = "${data.aws_region.current.id}b"
  map_public_ip_on_launch = false

  tags = {
    "Name"                                      = "clouda-commerce-public-2"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}-Green" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}-Blue" = "owned"
  }
}

resource "aws_internet_gateway" "clcom-gw" {
  vpc_id = aws_vpc.clouda-commerce.id

  tags = {
    Name = "clcom-gw"
  }
}

resource "aws_eip" "clcom-eip" {
  count = 2
  vpc      = true
  tags = {
    Name = "clcom-eip${count.index}"
  }
  depends_on = [
    aws_internet_gateway.clcom-gw
  ]
}

resource "aws_nat_gateway" "clouda-commerce-nat-1" {
  allocation_id = aws_eip.clcom-eip[0].allocation_id
  subnet_id     = aws_subnet.clcom-public-1.id

  tags = {
    Name = "clouda-commerce-nat-1"
  }
  depends_on = [aws_internet_gateway.clcom-gw]
}

resource "aws_nat_gateway" "clouda-commerce-nat-2" {
  allocation_id = aws_eip.clcom-eip[1].allocation_id
  subnet_id = aws_subnet.clcom-public-2.id

  tags = {
    Name = "clouda-commerce-nat-2"
  }
  depends_on = [aws_internet_gateway.clcom-gw] 
}


resource "aws_route_table" "clcom-private-rtb-a" {
  vpc_id = aws_vpc.clouda-commerce.id

  route{
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.clouda-commerce-nat-1.id
  }

  tags = {
    Name = "clouda-commerce-private-rtb-a"
  }
}

resource "aws_route_table" "clcom-private-rtb-b" {
  vpc_id = aws_vpc.clouda-commerce.id

  route{
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.clouda-commerce-nat-2.id
  }

  tags = {
    Name = "clouda-commerce-private-rtb-b"
  }
}

resource "aws_route_table" "clcom-public-rtb" {
  vpc_id = aws_vpc.clouda-commerce.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clcom-gw.id
  }

  tags = {
    Name = "clouda-commerce-public-rtb"
  }
  depends_on = [
    aws_internet_gateway.clcom-gw
  ]
}

resource "aws_route_table_association" "clcom-private-1" {
  subnet_id      = aws_subnet.clcom-private-1.id
  route_table_id = aws_route_table.clcom-private-rtb-a.id
}

resource "aws_route_table_association" "clcom-private-2" {
  subnet_id      = aws_subnet.clcom-private-2.id
  route_table_id = aws_route_table.clcom-private-rtb-b.id
}

resource "aws_route_table_association" "clcom-public-1" {
  subnet_id      = aws_subnet.clcom-public-1.id
  route_table_id = aws_route_table.clcom-public-rtb.id
}

resource "aws_route_table_association" "clcom-public-2" {
  subnet_id      = aws_subnet.clcom-public-2.id
  route_table_id = aws_route_table.clcom-public-rtb.id
}

