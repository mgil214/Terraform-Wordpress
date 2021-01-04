variable "aws_region" {}
variable "aws_profile" {}

data "aws_availability_zones" "available" {}

variable "tfbucket_name" {}
variable "dynamo_table_name" {}

variable "local_ip" {}

variable "stg_cidr" {}
variable "prod_cidr" {}
//variable "stg_public_cidr" {}
//variable "stg_private_cidr" {}
//variable "prod_public_cidr" {}
//variable "prod_private_cidr" {}

variable "my_key_name" {}
variable "my_public_key" {}
variable "my_public_key_path" {}
variable "my_instance_type" {}
variable "my_ami" {}