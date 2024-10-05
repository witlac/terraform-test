//Practica de IaC Especializacion en Ingenieria de Software
//Cristian Jhair Mejia Navarro

resource "aws_vpc" "cloud2_vpc_terraform" {
    cidr_block = "30.0.0.0/16"

    tags = {
      Name = "cloud2_vpc_terraform"
    }
}

resource "aws_subnet" "terraform_subnet1_public" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.1.0/24"

  tags = {
    Name = "subnet_public1"
  }
}

resource "aws_subnet" "terraform_subnet2_public" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.2.0/24"

  tags = {
    Name = "subnet_public2"
  }
}

resource "aws_subnet" "terraform_subnet1_private" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.3.0/24"

  tags = {
    Name = "subnet_private1"
  }
}

resource "aws_subnet" "terraform_subnet2_private" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.4.0/24"

  tags = {
    Name = "subnet_private2"
  }
}

resource "aws_internet_gateway" "gwInternet" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id

  tags = {
    Name = "gwInternet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gwInternet.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.terraform_subnet1_public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.terraform_subnet2_public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.terraform_subnet1_private.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.terraform_subnet2_private.id
  route_table_id = aws_route_table.private_route_table.id
}