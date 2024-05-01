provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAZI2LDJX2NLUJIRQ5"
  secret_key = "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"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id #refrencing vpc id
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Prod RT"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    name = "Prod Subnet"
  }
}

resource "aws_route_table_association" "connection-RT-subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "sg" {
  name        = "security_group"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = " security_group"
  }
}
resource "aws_network_interface" "server-nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg.id]

}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.igw]
}
resource "aws_instance" "server-instance" {
  ami               = "ami-04b70fa74e45c3917"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "Linux-vm-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c echo my very first web server > /var/www/html/index.html'
                EOF

  tags = {
    Name = "my-web-server"
  }
}