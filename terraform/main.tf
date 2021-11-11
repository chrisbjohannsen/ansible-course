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

# resource "aws_network_interface" "eni_1" {
#   subnet_id = aws_subnet.sn_west-1.id
# }

# resource "aws_network_interface" "eni_2" {
#   subnet_id = aws_subnet.sn_west-1.id
# }

resource "aws_instance" "webserver_1" {
  provider               = aws.west
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  tags = {
    Name = "webserver-1"
  }

  # network_interface {
  #   network_interface_id = aws_network_interface.eni_1.id
  #   device_index         = 0
  # }
}

# resource "aws_instance" "webserver_2" {
#   provider      = aws.west
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.micro"

#   tags = {
#     Name = "webserver-2"
#   }

#   network_interface {
#     network_interface_id = aws_network_interface.eni_2.id
#     device_index         = 1
#   }

# }

