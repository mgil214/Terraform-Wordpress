provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.tfbucket_name

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_dynamodb_table" "dynamodb-state-lock" {
  name = var.dynamo_table_name
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = { Name = "DynamoDB Terraform State Lock Table" }
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

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
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


resource "aws_security_group" "stg_private_sg" {
  name        = "stg_private_sg"
  description = "Used for private instances"
  vpc_id      = aws_vpc.stg_private_vpc.id

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

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
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