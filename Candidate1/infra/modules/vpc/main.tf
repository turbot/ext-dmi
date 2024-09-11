# Delete the default VPC in the region
# Handled in ../../preliminary/default_vpc.tf

# Create the VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create Subnets
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "subnet-2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "internet-gateway"
  }
}

# ... and route table with associations for getting any resouces placed in the subnets to the internet
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "subnet_1_association" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "subnet_2_association" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.rt.id
}

# Security group with SSH and Internet Access
resource "aws_security_group" "ssh_sg" {
  vpc_id      = aws_vpc.this.id
  name        = "ssh-sg"
  description = "Allow SSH and internet access"

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "allow-ssh-and-egress"
  }
}
