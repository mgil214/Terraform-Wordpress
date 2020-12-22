provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
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

