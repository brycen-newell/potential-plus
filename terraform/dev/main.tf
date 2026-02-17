provider "aws" {
  region = var.aws_region
}

# --- Networking Resources --- #

resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dev-vpc"
  }
}

resource "aws_subnet" "dev_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
  tags = {
    Name = "dev-public-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id    = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.dev_route_table.id
}

# --- Security --- #

resource "aws_security_group" "web_sg" {
  name         = "web-server-sg"
  description  = "Allow SSH and HTTP traffic"
  vpc_id       = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow SSH traffic from GitHub runner for Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.runner_ip}/32"]
  }

  ingress {
    description      = "Allow HTTP traffic from the Load Balancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-web-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

# --- COMPUTE --- #

resource "aws_instance" "web_server_dev" {
  ami                    = "ami-05efc83cb5512477c" # Amazon Linux 2 AMI for us-east-2 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.dev_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "dev-web-server"
  }
}

# --- ANSIBLE --- #

resource "local_file" "ansible_inventory_dev" {
  content  = "[webservers]\n${aws_instance.web_server_dev.public_ip} ansible_user=ec2-user"
  filename = "${path.root}/../../ansible/inventory/dev.ini"
}
