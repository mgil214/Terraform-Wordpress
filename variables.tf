variable "aws_region" {}
variable "aws_profile" {}

data "aws_availability_zones" "available" {}

variable "tfbucket_name" {}
variable "dynamo_table_name" {}

variable "local_ip" {}

variable "vpc_cidr" {}

variable "my_key_name" {}
variable "my_public_key" {}
variable "my_public_key_path" {}
variable "my_instance_type" {}
variable "my_ami" {}

variable "elb_healthy_threshold" {}
variable "elb_unhealthy_threshold" {}
variable "elb_timeout" {}
variable "elb_interval" {}