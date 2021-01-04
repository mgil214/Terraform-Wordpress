aws_region  = "us-west-2"
aws_profile = "cli-user"

tfbucket_name     = "mgil214-tfstate"
dynamo_table_name = "terraform-state-lock"

stg_public_cidr   = "10.0.1.0/24"
stg_private_cidr  = "10.0.2.0/24"
prod_public_cidr  = "10.0.3.0/24"
prod_private_cidr = "10.0.4.0/24"

local_ip = "176.213.239.172/32"

my_instance_type   = "t2.micro"
my_ami             = "ami-0e472933a1395e172"
my_key_name        = "m_linux_key"
my_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcufYYpebsy9m8WplbcLk1Tp/3GCVLkhbQALh0WYW0dC1sMBHbRSF8VpzeMpDogurUHt7KP8CBVq7ZvEFmcQdYCwR19TW/WWq9bPMu1mUIUG/xNzaJpARa3jk9T1WM4EtuErHuJ14VnJr6LynkSflovgEJrdAUaOOe77r/xcfLmWZF/fv3daouzxtmq7PYOydMhMroonFJmiSF9CYWPlJ7wJOf0YJfGolXcJSIjQeJGTnNPoHrTAo3wckj2Rq9shYUXbWiRAq3yKxqXVGM3LHWvshTpeky7NPYQoYTnz/Kffo0ZYpBI3KkH1tvhdJMaPXjGyH56UEmR4k5tsj+fFyN marat@linux"
my_public_key_path = "/home/marat/.ssh/aws-key.pem"