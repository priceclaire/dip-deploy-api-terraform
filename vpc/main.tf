data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
    count       = 2
    vpc_id      = aws_vpc.main.id
    cidr_block  = var.public_subnet_cidrs[count.index]

    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name    = "${var.app_name}-public-subnet-${count.index + 1}"
    }
}

resource "aws_subnet" "private-subnet" {
    count       = 2
    vpc_id      = aws_vpc.main.id
    cidr_block  = var.private_subnet_cidrs[count.index]

    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name    = "${var.app_name}-private-subnet-${count.index + 1}"
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.app_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
    count           = 2
    subnet_id       = aws_subnet.public-subnet[count.index].id
    route_table_id  = aws_route_table.public-route-table.id
}

resource "aws_eip" "nat" {
    count = 2

    depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "gw_nat" {
    count           = 2
    allocation_id   = aws_eip.nat[count.index].id
    subnet_id       = aws_subnet.public-subnet[count.index].id

    tags = {
        Name = "${var.app_name}-natgw-${count.index + 1}"
    }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "private-route-table" {
    count   = 2
    vpc_id  = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.gw_nat[count.index].id
     }

    tags = {
        Name = "${var.app_name}-private-route-table-${count.index + 1}"
    }
}

resource "aws_route_table_association" "private_subnet_association" {
    count           = 2
    subnet_id       = aws_subnet.private-subnet[count.index].id
    route_table_id  = aws_route_table.private-route-table[count.index].id
}