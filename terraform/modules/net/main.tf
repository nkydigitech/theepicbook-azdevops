resource "aws_vpc" "epicbook_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.epicbook_vpc.id

  tags = var.tags
}

resource "aws_subnet" "epicbook_pubsub" {
  vpc_id     = aws_vpc.epicbook_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = var.tags
}

resource "aws_subnet" "mysql_privsub1" {
  vpc_id     = aws_vpc.epicbook_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${var.aws_region}a"

  tags = var.tags
}

resource "aws_subnet" "mysql_privsub2" {
  vpc_id     = aws_vpc.epicbook_vpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${var.aws_region}c"

  tags = var.tags
}

# Security Group: Allow SSH & HTTP
resource "aws_security_group" "public_sg" {
  name        = "nkydigitech-${var.projectname}-server-sg-${terraform.workspace}"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.epicbook_vpc.id # Replace with your VPC ID, or remove if using default VPC

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "private_sg" {
  name        = "nkydigitech-${var.projectname}-mysql-sg-${terraform.workspace}"
  description = "allow 3306 only"
  vpc_id      = aws_vpc.epicbook_vpc.id # Replace with your VPC ID, or remove if using default VPC

  ingress {
    description = "database"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.epicbook_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = var.tags
}

# 5. Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.epicbook_pubsub.id
  route_table_id = aws_route_table.public_rt.id
}


