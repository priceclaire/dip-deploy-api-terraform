output "security_group_id" {
  value = aws_security_group.private_sg.id
}

output "instance_ids" {
  value = aws_instance.private_instance[*].id
}