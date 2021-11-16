
provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "ansible_course" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "ansible_vpc"
    Terraform = true
  }
}

resource "aws_internet_gateway" "igw_ansible" {
  vpc_id   = aws_vpc.ansible_course.id

  tags = {
    Terraform = true
  }
}

resource "aws_subnet" "sn_west_1" {
  availability_zone = "us-west-2a"
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.ansible_course.id

  tags = {
    Terraform = true
  }
}

resource "aws_route_table" "internet_route" {
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
  vpc_id         = aws_vpc.ansible_course.id
  route_table_id = aws_route_table.internet_route.id
}

resource "aws_security_group" "allow_ssh" {
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
    }, {
    from_port        = 80
    to_port          = 80
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
  vpc = true

  tags = {
    Terraform = true
  }
}

resource "aws_eip" "web_ip_2" {
  vpc = true

  tags = {
    Terraform = true
  }
}
resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.webserver_1.id
  allocation_id = aws_eip.web_ip.id
}

resource "aws_eip_association" "web_ip_assoc_2" {
  instance_id   = aws_instance.webserver_2.id
  allocation_id = aws_eip.web_ip_2.id
}

data "aws_ami" "ubuntu" {
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_west_1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = "ansible-course"

  tags = {
    Terraform = true
    Name      = "webserver-1"
  }
}

resource "aws_instance" "webserver_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_west_1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = "ansible-course"

  tags = {
    Terraform = true
    Name      = "webserver-2"
  }
}

resource "aws_elb" "web_lb" {
  name = "web-traffic-lb"

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = [aws_instance.webserver_1.id, aws_instance.webserver_2.id]
  subnets   = [aws_subnet.sn_west_1.id]

  tags = {
    Terraform = true
    Name      = "webr-elb-1"
  }
}

resource "aws_ebs_volume" "backup_drive" {
  type = "gp3"
  size = "10"
  
  availability_zone = "us-west-2a"

  tags = {
    Terraform = true
    Name = "backup"
  }
}

resource "aws_volume_attachment" "webserver_1_backup" {
  device_name = "/dev/xvdc"
  volume_id = aws_ebs_volume.backup_drive.id
  instance_id = aws_instance.webserver_1.id
}


