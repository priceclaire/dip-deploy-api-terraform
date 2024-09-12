variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "bastion_sg_id" {
  description = "The ID of the bastion security group"
  type        = string
}