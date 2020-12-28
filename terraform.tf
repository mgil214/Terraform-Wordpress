terraform {
  backend “s3” {
  encrypt = true
  bucket = var.tfbucket_name
  dynamodb_table = var.table_name
  region = var.aws_region
  key = /
  }
}