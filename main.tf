provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# ----------------------------------------------------
# VPC
# ----------------------------------------------------
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example-vpc"
  }
}

# ----------------------------------------------------
# Internet Gateway
# ----------------------------------------------------
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# ----------------------------------------------------
# Subnets
# ----------------------------------------------------
# Public Subnet
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-public-subnet-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-public-subnet-1c"
  }
}

# Private Subnet
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "example-private-subnet-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "example-private-subnet-1c"
  }
}

# ----------------------------------------------------
# Route Tables & Associations
# ----------------------------------------------------
# Public Route Table (IGWへのルーティング)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-public-rt"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-private-rt"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}

# ----------------------------------------------------
# Security Group
# ----------------------------------------------------
resource "aws_security_group" "instance" {
  name        = "terraform-example-instance"
  description = "Security group for example EC2 instance"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-example-instance"
  }
}

# ----------------------------------------------------
# EC2 Instance
# ----------------------------------------------------
resource "aws_instance" "example" {
  ami                    = "ami-06380d26ad7176f2c"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup python3 -m http.server 8080 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

# ----------------------------------------------------
# Outputs
# ----------------------------------------------------
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.example.public_ip
}

output "public_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.example.public_ip}:8080"
}