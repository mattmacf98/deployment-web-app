terraform {
  required_version = ">= 1.1.3"
}

provider "aws" {
  version = ">= 2.28.1"
  region = "us-west-2"
}

resource "aws_security_group" "db_instance_sg" {
  name        = "db_instance_sg-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main_db" {
  instance_class = "db.t3.micro"
  allocated_storage = 5
  engine = "postgres"
  username = var.db_username
  password = var.db_password
  vpc_security_group_ids = [aws_security_group.db_instance_sg.id]
  db_name = "to_do"
  publicly_accessible = true
  skip_final_snapshot = true
  tags = {
    Name = "to-do production database"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "deployment_server" {
  ami = "ami-0a70b9d193ae8a799"
  instance_type = "t2.medium"
  key_name = "remotebuild"
  user_data = file("server_build.sh")
  security_groups = [aws_security_group.instance_sg.name]
  tags = {
    Name = "to-do deployment server"
  }
  # root disk
  root_block_device {
    volume_size = "15"
    volume_type = "gp2"
    delete_on_termination = true
  }
}

output "ec2_global_ips" {
  value = [aws_instance.deployment_server.*.public_ip]
}

output "db_endpoint" {
  value = aws_db_instance.main_db.*.endpoint
}
