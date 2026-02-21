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

resource "aws_subnet" "dev_private_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "dev-private-subnet"
  }
}

resource "aws_subnet" "dev_public_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "dev-nat-eip"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_nat_gateway" "dev_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.dev_public_subnet.id
  tags  = {
    Name = "dev-nat-gw"
  }
  depends_on = [aws_internet_gateway.dev_igw]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.dev_nat_gw.id
  }

  tags = {
    Name = "dev_private_route_table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
  tags = {
    Name = "dev-public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id    = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id    = aws_subnet.dev_private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# --- Security --- #

resource "aws_security_group" "web_sg" {
  name         = "web-server-sg"
  description  = "Allow SSH and HTTP traffic"
  vpc_id       = aws_vpc.dev_vpc.id

  ingress {
    description      = "Allow HTTP traffic from the Load Balancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]

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

resource "aws_security_group" "bastion_sg" {
  name          = "bastion-sg"
  vpc_id        = "aws_vpc.dev_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.runner)ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }
  tags = {
    Name = "dev-bastion-sg" 
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

# --- COMPUTE --- #

resource "aws_instance" "web_server_dev"{
  count                  = 1
  ami                    = "ami-05efc83cb5512477c" # Amazon Linux 2 AMI for us-east-2 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.dev_public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "dev-web-server-${count.index}"
  }
}

resource "aws_instance" "monitoring_server" {
  count                   = var.deploy_monitoring_server ? 1 : 0
  ami                     = "ami-0c55b159cbfafe1f0" 
  instance_type           = "t2.micro"

  subnet_id               = aws_subnet.dev_private_subnet.id
  vpc_security_group_ids  = [aws_security_group.web_sg.id]
  key_name                = aws_key_pair.deployer.key_name

  tags = {
    Name = "dev-web-server-${count.index}"
  }
}

resource "aws_instance" "bastion" {
  ami                     = "ami-0c55b159cbfafe1f0"
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.dev_public_subnet.id
  vpc_security_group_ids  = [aws_security_group.bastion_sg.id]
  key_name                = aws_key_pair.deployer.key_name
  tags = {
    Name = "dev-bastion-host" 
  }
}

# --- ANSIBLE --- #

resource "local_file" "ansible_inventory_dev" {
  content = templatefile("${path.module}/inventory.tpl", {
    webservers             = aws_instance.web_server_dev
    monitoring_servers     = aws_instance.monitoring_server
  })
  filename = "${path.root}/../../ansible/inventory/dev.ini"
}
