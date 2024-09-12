variable "app_name" {
  description = "The name of the application"
  type        = string
}   

variable "vpc_id" {
  description = "The value of vpc id"
  type        = string
}

variable "subnet_id" {
  description = "The value of subnet id"
  type        = string
}

variable "ec2_profile_name" {
  description = "The name of the ec2 profile"
  type        = string
}