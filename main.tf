provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.tfbucket_name
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}


resource "aws_dynamodb_table" "dynamodb-state-lock" {
  name           = var.dynamo_table_name
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "wordpress_vpc"
  }
}

resource "aws_internet_gateway" "wp_gateway" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = {
    Name = "wordpress_gateway"
  }
}

resource "aws_route_table" "wp_public_route" {
  vpc_id = aws_vpc.wp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_gateway.id
  }
  tags = {
    Name = "wp_public"
  }
}

resource "aws_default_route_table" "wp_private_route" {
  default_route_table_id = aws_vpc.wp_vpc.default_route_table_id
  tags = {
    Name = "wp_private"
  }
}

resource "aws_subnet" "wp_public_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.vpc_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "wp_public"
  }
}

resource "aws_subnet" "wp_private_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.vpc_cidr
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "wp_private"
  }
}


resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = aws_subnet.wp_public_subnet.id
  route_table_id = aws_route_table.wp_public_route.id
}

resource "aws_route_table_association" "wp_private1_assoc" {
  subnet_id      = aws_subnet.wp_private_subnet.id
  route_table_id = aws_default_route_table.wp_private_route.id
}


resource "aws_security_group" "wp_public_sg" {
  name        = "wp_public_sg"
  description = "Used for the elastic load balancer for public access"
  vpc_id      = aws_vpc.wp_vpc.id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "wp_private_sg" {
  name        = "wp_private_sg"
  description = "Used for private instances"
  vpc_id      = aws_vpc.wp_vpc.id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }

  #EFS
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = [var.vpc_cidr, aws_instance.wp_instance.id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth_key" {
  key_name   = var.my_key_name
#  public_key = var.my_public_key
  public_key = file(var.my_public_key_path)
}


resource "aws_instance" "wp_instance" {
  instance_type = var.my_instance_type
  ami           = var.my_ami
  key_name = aws_key_pair.auth_key.id
  vpc_security_group_ids = [
    aws_security_group.wp_public_sg.id
  ]
  #  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.id
  subnet_id = aws_subnet.wp_public_subnet.id
  tags = {
    Name = "wordpress_stg"
  }

}

resource "aws_efs_file_system" "wp_efs" {
  creation_token = "wordpress_efs_mount"
  performance_mode = "generalPurpose"

  tags = {
    Name = "Stage Wordpress Static Content"
  }
}

resource "aws_efs_mount_target" "wp_efs_mount" {
  file_system_id = aws_efs_file_system.wp_efs.id
  subnet_id = aws_subnet.wp_private_subnet.id
  security_groups = [ aws_security_group.wp_private_sg.id ]
}


resource "aws_elb" "wp_wp_elb" {
  name            = "stage-wordpress-elb"
  subnets         = [ aws_subnet.wp_public_subnet.id ]
  security_groups = [aws_security_group.wp_public_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    target              = "TCP:80"
    interval            = var.elb_interval
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "Stage Wordpress ELB"
  }
}
