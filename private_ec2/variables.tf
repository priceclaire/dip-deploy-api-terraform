variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "lb_sg_id" {
  description = "The security group ID of the load balancer"
  type        = string
}

variable "private_subnet_ids" {
  description = "The private subnet IDs"
  type        = list(string)
}

variable "ec2_profile_name" {
  description = "The name of the EC2 instance profile"
  type        = string
}