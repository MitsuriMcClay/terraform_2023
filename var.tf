#Vpc Cidr Block
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

#Availability Zone
variable "availability_zone" {

  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

#Subnet Cidr Block
variable "subnet_cidr_block" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

#Tags
variable "tags" {
  default = "terraform_sample_mitsuri"
}
