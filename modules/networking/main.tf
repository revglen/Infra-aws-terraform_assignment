resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = var.name
  }
}

# Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  
  tags = {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Tier = "Private"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Tier = "Public"
  }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = var.azs[count.index]
  
  tags = {
    Name = "${var.name}-database-${var.azs[count.index]}"
    Tier = "Database"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  
  tags = {
    Name = "${var.name}-igw"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.public_subnets)
  tags = {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.name}-nat-${var.azs[count.index]}"
  }
  
  depends_on = [aws_internet_gateway.this]
}

# Route Tables
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.this.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }
  
  tags = {
    Name = "${var.name}-private-rt-${var.azs[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  
  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnets)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.this.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    #security_groups = [aws_security_group.nginx.id]
    cidr_blocks = ["0.0.0.0/0"]
  }

  #not in production
  # ingress {
  #   from_port       = 22
  #   to_port         = 22
  #   protocol        = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.name}-app-sg"
  }
}

resource "aws_security_group" "nginx" {
  name        = "${var.name}-nginx-sg"
  description = "Security group for NGINX servers"
  vpc_id      = aws_vpc.this.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.name}-nginx-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.this.id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.name}-db-sg"
  }
}