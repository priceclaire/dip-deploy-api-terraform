resource "aws_security_group" "db_sg" {
  name        = "${var.app_name}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic_db_private" {
  security_group_id             = aws_security_group.db_sg.id
  from_port                     = 5432
  to_port                       = 5432
  ip_protocol                   = "tcp"
  referenced_security_group_id  = var.private_sg_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic_db_bastion" {
  security_group_id             = aws_security_group.db_sg.id
  from_port                     = 5432
  to_port                       = 5432
  ip_protocol                   = "tcp"
  referenced_security_group_id  = var.bastion_sg_id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "postgres" {
  allocated_storage   = 10
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]  
}