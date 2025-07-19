provider "aws"{
    access_key = " "// paste access key here
    secret_key = ""  // paste secret key here
    region= "us-east-1"
}

# First create VPC
resource "aws_vpc" "main"{
    cidr_block = "10.0.0.0/16"
    instance_tenancy ="default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "main-vpc"
    }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "main-igw"
    }
}

# Creating Public Subnet 
resource "aws_subnet" "publicSubnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "publicSubnet"
    }
}

# Creating Private Subnet 
resource "aws_subnet" "privateSubnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
     availability_zone = "us-east-1a"
    tags = {
        Name = "privateSubnet"
    }
}

# Creating Second Private Subnet in a different AZ
resource "aws_subnet" "privateSubnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "privateSubnet2"
  }
}

# Creating Route Table
resource "aws_route_table" "publicRouteTable"{
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags= {
        Name ="publicRouteTable"
    }
}

# Associate Public Route Table
resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.publicSubnet.id
    route_table_id = aws_route_table.publicRouteTable.id
}

#Generate Key value Pair
resource "tls_private_key"  "keyPair"{
  algorithm    = "RSA"
  rsa_bits     = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name   = "javaServer"
  public_key = tls_private_key.keyPair.public_key_openssh
}
resource "local_file" "pemFile" {
  content         = tls_private_key.keyPair.private_key_pem
  filename        = "${path.module}/ec2_rds.pem"
  file_permission = "0600"
}

resource "aws_security_group" "web_sg" {
    name = "web-sg"
    description = "Allow SSH and HTTP"
    vpc_id = aws_vpc.main.id
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"        # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"] # all IPv4
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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
    Name = "web-sg"
  }
}






# Creating security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

#Create RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.privateSubnet.id,
    aws_subnet.privateSubnet2.id
  ]

  tags = {
    Name = "RDS subnet group"
  }
}


#Create the RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier              = "mydb-instance"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false

  tags = {
    Name = "MySQL-RDS"
  }
}


resource "aws_instance" "ec2_instance"{
    ami = var.ami
    instance_type = var.instance_type
    key_name = aws_key_pair.generated_key.key_name
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    subnet_id = aws_subnet.publicSubnet.id
    associate_public_ip_address = true
    user_data = templatefile("${path.module}/init.sh.tpl", {
  DB_HOST = aws_db_instance.mysql.address
  DB_USER = var.db_username
  DB_PASS = var.db_password
  DOCKER_USERNAME = var.docker_username
    DOCKER_PASSWORD = var.docker_password
    IMAGE_NAME      = var.image_name
    IMAGE_TAG       = var.image_tag
})
    tags = {
        Name = "Ec2_RDS"
    }
}





