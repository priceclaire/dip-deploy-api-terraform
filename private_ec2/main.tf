resource "aws_security_group" "private_sg" {
  name        = "${var.app_name}-private-sg"
  description = "Private security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_traffic_from_lb_to_api" {
  security_group_id             = aws_security_group.private_sg.id
  from_port                     = 3000
  to_port                       = 3000
  ip_protocol                   = "tcp"
  referenced_security_group_id  = var.lb_sg_id
}
resource "aws_vpc_security_group_ingress_rule" "allow_traffic_from_lb_to_frontend" {
  security_group_id             = aws_security_group.private_sg.id
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
  referenced_security_group_id  = var.lb_sg_id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_private" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "private_instance" {
  count         = 2
  ami           = "ami-0d3a2960fcac852bc"
  instance_type = "t3.micro"

  subnet_id   = var.private_subnet_ids[count.index]  

  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  iam_instance_profile = var.ec2_profile_name

  user_data = file("./docker-script.sh")

  tags = {
    Name = "${var.app_name}-private-ec2-${count.index + 1}"
  }
}