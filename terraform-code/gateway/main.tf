provider "aws" {
    profile = "default"
    region = "ap-northeast-3"
  
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = data.aws_vpc.challenge.id

  tags = {
    Name = "IGW"
  }
}

# Create Web layber route table
resource "aws_route_table" "web" {
  vpc_id = "aws_vpc.challege.id"


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Web-Route"
  }
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = "aws_subnet.web-subnet-1.id"
  route_table_id = aws_route_table.web.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = "aws_subnet.web-subnet-2.id"
  route_table_id = aws_route_table.web.id
}