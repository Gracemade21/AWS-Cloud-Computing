data "aws_vpc" "default_vpc" {
    default = true
}

/*data "aws_subnet" "default_subnet"{
    id = data.aws_vpc.default_vpc.id
}*/

data "aws_subnet" "subnet_us-east-1a" {
    id = "subnet-0afb67a7f948255ea"
  
}

data "aws_subnet" "subnet_us-east-1b" {
    id = "subnet-02f94b02e19758ca6"
  
}


#resource "aws_subnet" "subnet_us-east-1a" {
/*  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = "172.31.80.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_us-east-1b" {
  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
*/

resource "aws_security_group" "securitygrp1" {
    name = var.aws_security_group
}

resource "aws_security_group_rule" "ssh-rule" {
    security_group_id = aws_security_group.securitygrp1.id
    type = "ingress"

    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port   = 22
    protocol = "tcp"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.securitygrp1.id

  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Create a VPC
resource "aws_vpc" "gl_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "gl-vpc"
  }
  
}

#Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.gl_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
  
}

#Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id      = aws_vpc.gl_vpc.id
  cidr_block  = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags ={
    Name = "private"
  }
  
}

#Create an internet Gateway
resource "aws_internet_gateway" "gl_igw" {
  vpc_id = aws_vpc.gl_vpc.id
  tags = {
    Name = "gl-igw"
  }
  
}

#Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.gl_vpc.id
  tags = {
    Name = "public-crt"
  }

}

#Create a route in the public route table
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gl_igw.id

}

# Associate the public with the publc route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
  
}

#Create a security group for the public instance
resource "aws_security_group" "public_sg" {
  name = "public-sg"
  description = "Security group for public instance"
  vpc_id      = aws_vpc.gl_vpc.id
  
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  
}
}

#Create a security group for the the private instance
resource "aws_security_group" "private_sg" {
  name = "private-sg"
  description = "Opens security groups for ssh and mysql only from the public subnet"
  vpc_id = aws_vpc.gl_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]
  }

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]
  
}
}

