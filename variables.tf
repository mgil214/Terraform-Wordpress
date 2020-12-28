variable "aws_region" {}
variable "aws_profile" {}

data "aws_availability_zones" "available" {}

variable "tfbucket_name" {}
variable "dynamo_table_name" {}

variable "stg_public_cidr" {}
variable "stg_private_cidr" {}
variable "prod_public_cidr" {}
variable "prod_private_cidr" {}

