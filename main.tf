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


resource "aws_vpc" "stg_public_vpc" {
  cidr_block           = var.stg_public_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "stage_public"
  }
}

resource "aws_vpc" "stg_private_vpc" {
  cidr_block           = var.stg_private_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "stage_private"
  }
}

resource "aws_vpc" "prod_public_vpc" {
  cidr_block           = var.prod_public_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "production_public"
  }
}

resource "aws_vpc" "prod_private_vpc" {
  cidr_block           = var.prod_private_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "production_private"
  }
}

resource "aws_internet_gateway" "stg_gateway" {
  vpc_id = aws_vpc.stg_public_vpc.id
  tags = {
    Name = "stg_gateway"
  }
}

resource "aws_internet_gateway" "prod_gateway" {
  vpc_id = aws_vpc.prod_public_vpc.id
  tags = {
    Name = "prod_gateway"
  }
}

resource "aws_route_table" "stg_public_route" {
  vpc_id = aws_vpc.stg_public_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stg_gateway.id
  }
  tags = {
    Name = "stg_public"
  }
}

resource "aws_default_route_table" "stg_private_route" {
  default_route_table_id = aws_vpc.stg_private_vpc.default_route_table_id
  tags = {
    Name = "stg_private"
  }
}

resource "aws_route_table" "prod_public_route" {
  vpc_id = aws_vpc.prod_public_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_gateway.id
  }
  tags = {
    Name = "prod_public"
  }
}

resource "aws_default_route_table" "prod_private_route" {
  default_route_table_id = aws_vpc.prod_private_vpc.default_route_table_id
  tags = {
    Name = "prod_private"
  }
}

resource "aws_subnet" "stg_public_subnet" {
  vpc_id                  = aws_vpc.stg_public_vpc.id
  cidr_block              = var.stg_public_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "stg_public"
  }
}

resource "aws_subnet" "stg_private_subnet" {
  vpc_id                  = aws_vpc.stg_private_vpc.id
  cidr_block              = var.stg_private_cidr
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "stg_private"
  }
}


resource "aws_subnet" "prod_public_subnet" {
  vpc_id                  = aws_vpc.prod_public_vpc.id
  cidr_block              = var.prod_public_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "prod_public"
  }
}

resource "aws_subnet" "prod_private_subnet" {
  vpc_id                  = aws_vpc.prod_private_vpc.id
  cidr_block              = var.prod_private_cidr
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "prod_private"
  }
}


resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = aws_subnet.stg_public_subnet.id
  route_table_id = aws_route_table.stg_public_route.id
}

resource "aws_route_table_association" "wp_private1_assoc" {
  subnet_id      = aws_subnet.stg_private_subnet.id
  route_table_id = aws_default_route_table.stg_private_route.id
}


resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = aws_subnet.prod_public_subnet.id
  route_table_id = aws_route_table.prod_public_route.id
}

resource "aws_route_table_association" "wp_private2_assoc" {
  subnet_id      = aws_subnet.prod_private_subnet.id
  route_table_id = aws_default_route_table.prod_private_route.id
}


resource "aws_security_group" "stg_public_sg" {
  name        = "stg_public_sg"
  description = "Used for the elastic load balancer for public access"
  vpc_id      = aws_vpc.stg_public_vpc.id

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


resource "aws_security_group" "stg_private_sg" {
  name        = "stg_private_sg"
  description = "Used for private instances"
  vpc_id      = aws_vpc.stg_private_vpc.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = [var.stg_private_cidr, aws_instance.wordpress_stg.private_ip]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.stg_private_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prod_public_sg" {
  name        = "prod_public_sg"
  description = "Used for the elastic load balancer for public access"
  vpc_id      = aws_vpc.prod_public_vpc.id

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


resource "aws_security_group" "prod_private_sg" {
  name        = "prod_private_sg"
  description = "Used for private instances"
  vpc_id      = aws_vpc.prod_private_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.prod_private_cidr]
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

resource "aws_instance" "wordpress_stg" {
  instance_type = var.my_instance_type
  ami           = var.my_ami
  key_name = aws_key_pair.auth_key.id
  vpc_security_group_ids = [ aws_security_group.stg_private_sg.id, aws_security_group.stg_public_sg.id ]
  #  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.id
  subnet_id = aws_subnet.stg_public_subnet.id
  tags = {
    Name = "wordpress_stg"
  }

}

//resource "aws_instance" "wordpress_prod" {
//  instance_type = var.my_instance_type
//  ami           = var.my_ami
//
//  tags = {
//    Name = "wordpress_prod"
//  }
//
//  key_name = aws_key_pair.auth_key.id
//  vpc_security_group_ids = [
//  aws_security_group.prod_public_sg.id]
//  #  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.id
//  subnet_id = aws_subnet.prod_public_subnet.id
//}


resource "aws_efs_file_system" "stg_efs" {
  creation_token = "stg_wordpress_efs_mount"
  performance_mode = "generalPurpose"

  tags = {
    Name = "Stage Wordpress Static Content"
  }
}

//resource "aws_efs_file_system" "prod_efs" {
//  creation_token = "prod_wordpress_efs_mount"
//  performance_mode = "generalPurpose"
//
//  tags = {
//    Name = "Prod Wordpress Static Content"
//  }
//}

resource "aws_efs_mount_target" "stg_efs_mount" {
  file_system_id = aws_efs_file_system.stg_efs.id
  subnet_id = aws_subnet.stg_public_subnet.id
  security_groups = [ aws_security_group.stg_private_sg.id ]
}
