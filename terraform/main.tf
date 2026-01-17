provider "aws" {
  region = "eu-west-3"
}

################################
# -_-_-_- DATA SOURCES -_-_-_- #
################################

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"] # Debian
}

#################################
# -_-_-_-_- RESOURCES -_-_-_-_- #
#################################

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "home-lab" {
  key_name   = "home-lab"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = pathexpand("~/.ssh/aws-home-lab.pem")
  file_permission = "0400"
}

resource "aws_eip" "cluster_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "cluster_eip_association" {
  instance_id    = aws_instance.cluster.id
  allocation_id  = aws_eip.cluster_eip.id
}

resource "aws_security_group" "cluster_sg" {
  name        = "cluster-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  vpc_id      = "vpc-0c73afefcb9683ebd" #   eu-west-3

  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Using 0.0.0.0/0 for demo purposes; restrict to local IP for prod would be a good idea
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_cluster_sg"
  }
}

resource "aws_instance" "cluster" {
  ami                     = data.aws_ami.debian.id
  instance_type           = "t3.micro"
  vpc_security_group_ids  = [resource.aws_security_group.cluster_sg.id]
  key_name                = aws_key_pair.home-lab.key_name
  subnet_id               = "subnet-0546fd4a2df0c1115" # eu-west-3a

  tags = {
    Name = "dawn-treader-cluster"
  }
}

#################################
# -_-_-_-_-_ OUTPUT -_-_-_-_-_- #
#################################

output "ssh_command" {
  value = "ssh -i ~/.ssh/aws-home-lab.pem admin@${aws_eip.cluster_eip.public_ip}"
}