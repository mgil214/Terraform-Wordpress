aws_region  = "us-west-2"
aws_profile = "cli-user"

tfbucket_name = "mgil214-tfstate"
dynamo_table_name = "terraform-state-lock"

stg_public_cidr  = "10.0.1.0/24"
stg_private_cidr  = "10.0.2.0/24"
prod_public_cidr = "10.0.3.0/24"
prod_private_cidr = "10.0.4.0/24"

local_ip = "176.213.239.172/32"

my_instance_type = "t2.micro"
my_ami           = "ami-0e472933a1395e172"
my_key_name          = "cli-user"
my_public_key_path   = "/home/marat/.ssh/id_rsa.pub"