data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_app_subnet_cidrs[count.index]

  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-private-app-${count.index + 1}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_db_subnet_cidrs[count.index]

  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-private-db-${count.index + 1}"
    Tier = "database"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"

      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project}-private-app-route-table"
  }
}

resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id = aws_subnet.private_app[count.index].id

  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-database-route-table"
  }
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.private_db)

  subnet_id = aws_subnet.private_db[count.index].id

  route_table_id = aws_route_table.database.id
}


resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${var.project}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id

  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}
