//Practica de IaC Especializacion en Ingenieria de Software
//Cristian Jhair Mejia Navarro

resource "aws_vpc" "cloud2_vpc_terraform" {
    cidr_block = "30.0.0.0/16"

    tags = {
      Name = "cloud2_vpc_terraform"
    }
}

resource "aws_subnet" "terraform_subnet1_public" {
  vpc_id                  = aws_vpc.cloud2_vpc_terraform.id
  cidr_block              = "30.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_public1"
  }
}

resource "aws_subnet" "terraform_subnet2_public" {
  vpc_id                  = aws_vpc.cloud2_vpc_terraform.id
  cidr_block              = "30.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_public2"
  }
}

resource "aws_subnet" "terraform_subnet1_private" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.3.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "subnet_private1"
  }
}

resource "aws_subnet" "terraform_subnet2_private" {
  vpc_id     = aws_vpc.cloud2_vpc_terraform.id
  cidr_block = "30.0.4.0/24"
  availability_zone = "us-east-1f"

  tags = {
    Name = "subnet_private2"
  }
}

resource "aws_internet_gateway" "gwInternet" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id

  tags = {
    Name = "gwInternet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gwInternet.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.cloud2_vpc_terraform.id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.terraform_subnet1_public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.terraform_subnet2_public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.terraform_subnet1_private.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.terraform_subnet2_private.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "allow_ftp" {
  name        = "allow-ftp"
  description = "Allow inbound FTP traffic on port 20"
  vpc_id      = aws_vpc.cloud2_vpc_terraform.id

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
    from_port   = 3306
    to_port     = 3306
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
    Name = "allow-ftp"
  }
}

resource "aws_instance" "instance_1" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ftp.id]
  subnet_id              = aws_subnet.terraform_subnet1_public.id
  key_name               = "cloud2"
  user_data              =  file("docker_run.sh")

  tags = {
    Name = "instance_1"
  }
}

resource "aws_instance" "instance_2" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ftp.id]
  subnet_id              = aws_subnet.terraform_subnet2_public.id
  key_name               = "cloud2"
  user_data              =  file("docker_run.sh")
  tags = {
    Name = "instance_2"
  }
}

resource "aws_lb" "web_lb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ftp.id]
  subnets            = [aws_subnet.terraform_subnet1_public.id, aws_subnet.terraform_subnet2_public.id]

  enable_deletion_protection = false

  tags = {
    Name = "web-load-balancer"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "OK"
    }
  }
}
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloud2_vpc_terraform.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
  }

  tags = {
    Name = "web-target-group"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment_instance_1" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id       = aws_instance.instance_1.id
  port            = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_instance_2" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id       = aws_instance.instance_2.id
  port            = 80
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.terraform_subnet1_public.id, aws_subnet.terraform_subnet2_public.id]

  tags = {
    Name = "my-db-subnet-group"
  }
}

resource "aws_db_instance" "rdsdb" {
  allocated_storage       = 20   
  storage_type            = "gp2"  
  engine                  = "mysql" 
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"  
  db_name                 = "mydb"
  username                = "admin"
  password                = "admin123" 
  multi_az                = false 
  publicly_accessible     = false
  backup_retention_period = 7 
  final_snapshot_identifier = "mydb-final-snapshot" 
  availability_zone       = "us-east-1a"

  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
}

