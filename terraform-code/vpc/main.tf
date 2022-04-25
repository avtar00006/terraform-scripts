provider "aws" {
    profile = "default"
    region = "ap-northeast-3"
  
}

resource "aws_vpc" "challege" {
  cidr_block = "10.0.0.0/16"
    tags     = {
      "Name" = "challenge"
    }
}

# Create Web Public Subnet
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.challege.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web1"
  }
}

# Create Web Security Group
resource "aws_security_group" "web-sg1" {
  name        = "Web-SG"
  description = "inbound traffic"
  vpc_id      = aws_vpc.challege.id

  ingress {
    description = "HTTP from VPC"
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

  tags = {
    Name = "Web-SG"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.challege.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web2"
  }
}



# Create Web Server Security Group
resource "aws_security_group" "web-sg2" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.challege.id
  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg1.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webserver-SG"
  }
}

# Create Application Private Subnet
resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.challege.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application1"
  }
}

resource "aws_subnet" "application-subnet-2" {
  vpc_id                  = aws_vpc.challege.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application2"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.challege.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-3a"

  tags = {
    Name = "Database1"
  }
}

resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.challege.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-3b"

  tags = {
    Name = "Database2"
  }
}

# Create Database Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.challege.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg2.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-SG"
  }
}

resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg2.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.challege.id
}
