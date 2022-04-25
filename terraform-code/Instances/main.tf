#EC2 Instance webservers
resource "aws_instance" "webserver1" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.nano"
  availability_zone      = "ap-northeast-3a"
  vpc_security_group_ids = [aws_security_group.web1.id]
  subnet_id              = aws_subnet.web-subnet-1.id
  
  tags = {
    Name = "Web Server"
  }

}

resource "aws_instance" "webserver2" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.nano"
  availability_zone      = "ap-northeast-3b"
  vpc_security_group_ids = [aws_security_group.web2.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  
  tags = {
    Name = "Web Server"
  }

}