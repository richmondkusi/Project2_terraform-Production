# configuring our network for Tenacity IT
resource "aws_vpc" "Prod-VPC" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}"
    Environment = "Test"
  }
}





# Using Data source for my Availability Zone
data "aws_availability_zones" "az" {

}



# Creating 2 public subnets
resource "aws_subnet" "web-pub-sub" {
  vpc_id            = aws_vpc.Prod-VPC.id
  count             = length(var.web_pub_sub_cidrs)
  cidr_block        = var.web_pub_sub_cidrs[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name        = "web-pub-sub ${count.index + 1}"
    Environment = "Test"
  }
}

# Creating 2 private subnets
resource "aws_subnet" "app-priv-sub" {
  vpc_id            = aws_vpc.Prod-VPC.id
  count             = length(var.app_priv_sub_cidrs)
  cidr_block        = var.app_priv_sub_cidrs[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name        = "app-priv-sub ${count.index + 1}"
    Environment = "Test"
  }
}





# Creating a public route table

resource "aws_route_table" "web-pub-RT" {
  vpc_id = aws_vpc.Prod-VPC.id

  tags = {
    Name        = "web-pub-RT"
    Environment = "Test"
  }
}

# public route table association

resource "aws_route_table_association" "Pub-sub-assoc" {
  count          = length(var.web_pub_sub_cidrs)
  subnet_id      = element(aws_subnet.web-pub-sub[*].id, count.index)
  route_table_id = aws_route_table.web-pub-RT.id
}



# Creating a private route table

resource "aws_route_table" "app-priv-RT" {
  vpc_id = aws_vpc.Prod-VPC.id

  tags = {
    Name        = "app-priv-RT"
    Environment = "Test"
  }
}

# private route table association

resource "aws_route_table_association" "Priv-sub-assoc" {
  count          = length(var.app_priv_sub_cidrs)
  subnet_id      = element(aws_subnet.app-priv-sub[*].id, count.index)
  route_table_id = aws_route_table.app-priv-RT.id
}



# creating internet gateway

resource "aws_internet_gateway" "web-igw" {
  vpc_id = aws_vpc.Prod-VPC.id

  tags = {
    Name        = "Prod-igw"
    Environment = "Test"
  }
}

# internet gateway association with public route table
resource "aws_route_table" "web-pub-RTb" {
  vpc_id = aws_vpc.Prod-VPC.id

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.web-igw.id
  }
}

# Elastic IP
resource "aws_eip" "app-eip" {

  vpc = true
}

# creating a NAT Gateway

resource "aws_nat_gateway" "app-Nat-gateway" {
  depends_on = [
    aws_eip.app-eip
  ]
  allocation_id = aws_eip.app-eip.id
  subnet_id     = aws_subnet.web-pub-sub[0].id

  tags = {
    Name = "app-Nat-gateway"
  }
}

# Creating Route Table Association of the NAT Gateway with Private subnet
resource "aws_nat_gateway" "NAT-Gateway-Association" {
  depends_on = [
    aws_internet_gateway.web-igw
  ]

  # Private Subnet ID for adding the route table to the DHP server of Private subnet
  connectivity_type = "private"
  subnet_id         = aws_subnet.app-priv-sub[1].id
}



#Creation of Prod Security Group
resource "aws_security_group" "prod-sg" {
  name        = "prod-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Prod-VPC.id

  ingress {
    description = "SSH access from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-sg"
  }
}





# Creation of web servers
resource "aws_instance" "web-server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = ["${aws_security_group.prod-sg.id}"]
  subnet_id              = element(var.web_pub_sub_ids, count.index)
  count                  = var.instance_count


  tags = {
    Name = "web-server ${count.index + 1}"
  }
}

# Creation of app servers
resource "aws_instance" "app-server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = ["${aws_security_group.prod-sg.id}"]
  subnet_id              = element(var.app_priv_sub_ids, count.index)
  count                  = var.instance_count


  tags = {
    Name = "app-server-${count.index + 1}"
  }
}


#Creating a datadase security group
resource "aws_security_group" "rdssg" {
  name   = "rdssg"
  vpc_id = aws_vpc.Prod-VPC.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.prod-sg.id}"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# Subnet group creation
resource "aws_db_subnet_group" "dbsubgp" {
  name       = "dbsubgp"
  subnet_ids = var.all-subnet-ids

  tags = {
    Name = "dbsubgp"
  }
}

# Creating a database using MYSQL
resource "aws_db_instance" "mydb1" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "mydb1"
  username               = "hope"
  password               = "hopeforall"
  vpc_security_group_ids = ["${aws_security_group.rdssg.id}"]
  parameter_group_name   = "default.mysql5.7"
  availability_zone      = data.aws_availability_zones.az.names[1]
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.dbsubgp.name


  tags = {
    "Name" = "mydb1"
  }
}
