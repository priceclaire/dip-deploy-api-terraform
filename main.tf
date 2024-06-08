terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region  = "eu-north-1"
}

# provider "tls" {}

provider "local" {}

provider "http" {}

data "http" "myip" {
  url = "https://ipinfo.io/json"
}

module "vpc" {
  source = "./vpc"

  region                = var.region
  cidr_block            = var.cidr_block
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  app_name              = var.app_name
}

# resource "aws_vpc" "main" {
#   cidr_block       = "10.0.0.0/24"
#   instance_tenancy = "default"

#   tags = {
#     Name = "cwc-vpc"
#   }
# }

# resource "aws_subnet" "public-subnet" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.0.0/25"

#   availability_zone = "eu-north-1a"

#   tags = {
#     Name = "cwc-public-subnet"
#   }
# }

# resource "aws_subnet" "private-subnet" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.0.128/25"

#   availability_zone = "eu-north-1a"

#   tags = {
#     Name = "cwc-private-subnet"
#   }
# }

# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "cwc-igw"
#   }
# }

# resource "aws_route_table" "public-route-table" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   tags = {
#     Name = "cwc-public-route-table"
#   }
# }

# resource "aws_route_table_association" "public_subnet_association" {
#   subnet_id      = aws_subnet.public-subnet.id
#   route_table_id = aws_route_table.public-route-table.id
# }

# resource "aws_eip" "nat" {
#   vpc = true

#   depends_on = [aws_internet_gateway.gw]
# }

# resource "aws_nat_gateway" "gw_nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public-subnet.id

#   tags = {
#     Name = "cwc-natgw"
#   }

#   depends_on = [aws_internet_gateway.gw]
# }

# resource "aws_route_table" "private-route-table" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.gw_nat.id
#   }

#   tags = {
#     Name = "cwc-private-route-table"
#   }
# }

# resource "aws_route_table_association" "private_subnet_association" {
#   subnet_id      = aws_subnet.private-subnet.id
#   route_table_id = aws_route_table.private-route-table.id
# }

# resource "tls_private_key" "private_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

resource "aws_key_pair" "key" {
  key_name   = "cwc-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "cwc-key.pem"
}

resource "aws_security_group" "cwc_public_sg" {
  name        = "cwc_public_sg"
  description = "Allow SSH and TCP inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cwc_public_sg"
  }
}

resource "aws_instance" "public_instance" {
  ami           = "ami-0d3a2960fcac852bc"
  instance_type = "t3.micro"

  subnet_id   = module.vpc.public_subnet_ids[0]

  associate_public_ip_address = true

  key_name = aws_key_pair.key.key_name

  vpc_security_group_ids = [aws_security_group.cwc_public_sg.id]

  tags = {
    Name = "cwc-public-ec2"
  }
}

resource "aws_security_group" "cwc_private_sg" {
  name        = "cwc_private_sg"
  description = "Allow SSH traffic from bastion host,TCP inbound traffic from public subnet, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.cwc_bastion_host_sg.id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/25"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cwc_private_sg"
  }
}

resource "aws_instance" "private_instance" {
  ami           = "ami-0d3a2960fcac852bc"
  instance_type = "t3.micro"

  subnet_id   = module.vpc.private_subnet_ids[0]  

  associate_public_ip_address = false

  key_name = aws_key_pair.key.key_name

  vpc_security_group_ids = [aws_security_group.cwc_private_sg.id]

  tags = {
    Name = "cwc-private-ec2"
  }
}

resource "aws_security_group" "cwc_bastion_host_sg" {
  name        = "cwc_bastion_host_sg"
  description = "Allow SSH traffic from my IP address and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cwc_bastion_host_sg"
  }
}

resource "aws_instance" "bastion_host" {
  ami           = "ami-0d3a2960fcac852bc"
  instance_type = "t3.micro"

  subnet_id   = module.vpc.public_subnet_ids[0]

  associate_public_ip_address = true

  key_name = aws_key_pair.key.key_name

  vpc_security_group_ids = [aws_security_group.cwc_bastion_host_sg.id]

  tags = {
    Name = "cwc-bastion-host-ec2"
  }
}