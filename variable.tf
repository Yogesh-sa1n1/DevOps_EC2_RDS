variable "ami" {
    type = string 
    description = "EC2 AMI"
}

variable "instance_type" {
    description ="Ec2 instance_type"
    type = string
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "12345678"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "docker_username" {}
variable "docker_password" {}
variable "image_name" {}
variable "image_tag" {
  default = "latest"
}

