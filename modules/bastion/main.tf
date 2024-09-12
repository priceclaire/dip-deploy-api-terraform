resource "aws_security_group" "bastion_sg" {
  name        = "${var.app_name}-bastion-sg"
  description = "Bastion security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-bastion-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_bastion" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "bastion_host" {
  ami           = "ami-0d3a2960fcac852bc"
  instance_type = "t3.micro"

  subnet_id   = var.subnet_id

  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  iam_instance_profile = var.ec2_profile_name

  tags = {
    Name = "${var.app_name}-bastion-host"
  }
}