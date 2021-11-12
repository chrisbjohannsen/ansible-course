
provider "aws" {
  region  = "us-west-2"
  alias   = "west"
}

resource "aws_vpc" "ansible_course" {
  provider             = aws.west
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "ansible_vpc"
    Terraform = true
  }
}

resource "aws_internet_gateway" "igw_ansible" {
  provider = aws.west
  vpc_id   = aws_vpc.ansible_course.id

  tags = {
    Terraform = true
  }
}

resource "aws_subnet" "sn_west_1" {
  provider          = aws.west
  availability_zone = "us-west-2a"
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.ansible_course.id

  tags = {
    Terraform = true
  }
}

resource "aws_route_table" "internet_route" {
  provider = aws.west
  vpc_id   = aws_vpc.ansible_course.id
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.igw_ansible.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }
  ]

  tags = {
    Terraform = true
  }
}

resource "aws_main_route_table_association" "set-default-rt-assoc" {
  provider       = aws.west
  vpc_id         = aws_vpc.ansible_course.id
  route_table_id = aws_route_table.internet_route.id
}

resource "aws_security_group" "allow_ssh" {
  provider = aws.west
  vpc_id   = aws_vpc.ansible_course.id

  ingress = [{
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    description      = ""
    self             = false
  }]

  egress = [{
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = {
    Name      = "ssh-ingress-sg"
    Terraform = true
  }
}

resource "aws_eip" "web_ip" {
  # instance = aws_instance.web_server_1.id
  vpc = true
  tags = {
    Terraform = true
  }
}

resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.webserver_1.id
  allocation_id = aws_eip.web_ip.id
}

data "aws_ami" "ubuntu" {
  provider    = aws.west
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "webserver_1" {
  provider      = aws.west
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_west_1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name = "ansible-course"

  tags = {
    Terraform = true
    Name      = "webserver-1"
  }
}
