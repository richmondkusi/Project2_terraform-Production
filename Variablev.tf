variable "region" {
  default     = "eu-west-2"
  description = "making region a variable"
}

variable "project_name" {
  default = "Prod-VPC"

}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "making vpc_cidr a variable"
}

variable "instance_tenancy" {
  default     = "default"
  description = "making instance tenancy a variable"
}



variable "web_pub_sub_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_priv_sub_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "enable_dns_hostnames" {
  default = true
}

variable "web_pub_sub_ids" {
  default = ["subnet-0d28c62b2d24681e7", "subnet-0c60af21ed68b0014"]
  type    = list(any)
}

variable "app_priv_sub_ids" {
  default = ["subnet-032695f64bd36f174", "subnet-05a2c9636aa235526"]
  type    = list(any)
}

variable "all-subnet-ids" {
  type    = list(any)
  default = ["subnet-0d28c62b2d24681e7", "subnet-0c60af21ed68b0014", "subnet-032695f64bd36f174", "subnet-05a2c9636aa235526"]
}


variable "vpc_security_group_ids" {
  default = "aws_security_group.prod-sg.id"
}

variable "key_name" {
  default = "rock-key-pair"
}

variable "ami" {
  default = "ami-0a145236ee857b126"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_count" {
  default = "2"
}
