provider "aws" {
    profile = "default"
    region = "ap-northeast-3"
  
}

#VPC
resource "aws_vpc" "challege" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "challenge"
  }
}

# Public Subnet for Web
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.challege.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web1"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  =aws_vpc.challege.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Web2"
  }
}

# Application Public Subnet
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

#Database Private Subnet
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

resource "aws_subnet" "database-subnet" {
  vpc_id            = aws_vpc.challege.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-3a"

  tags = {
    Name = "Database"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.challege.id

  tags = {
    Name = "Gateway"
  }
}

# Create Web layber route table
resource "aws_route_table" "web1" {
  vpc_id = aws_vpc.challege.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Web1"
  }
}

#Web Subnet association with Web1
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web1.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web1.id
}

#EC2 Instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-066342ea9221bf7a6"
  instance_type          = "t2.nano"
  availability_zone      = "ap-northeast-3a"
  vpc_security_group_ids = [aws_security_group.web1.id]
  #vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id
 

  tags = {
    Name = "Web Server"
  }

}

resource "aws_instance" "webserver2" {
  ami                    = "ami-066342ea9221bf7a6"
  instance_type          = "t2.nano"
  availability_zone      = "ap-northeast-3b"
  vpc_security_group_ids = [aws_security_group.web2.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  

  tags = {
    Name = "Web Server"
  }

}

# Create Web Security Group
resource "aws_security_group" "web1" {
  name        = "Web-SG"
  description = "Allow HTTP inbound traffic"
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

# Create Application Security Group
resource "aws_security_group" "web2" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.challege.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web1.id]
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
    security_groups = [aws_security_group.web2.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}

resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web1.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.challege.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "challenge"
  username               = "admin"
  password               = "ad"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]

  tags = {
    Name = "DB subnet group"
  }
}

output "lb_dns_name" {
  description = "DNS"
  value       = aws_lb.external-elb.dns_name
}