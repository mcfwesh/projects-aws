// create subnet groups
resource "aws_db_subnet_group" "h20up_db_subnet_group" {
  name       = "h20up_db_subnet_group"
  subnet_ids = [aws_subnet.h20up_db_subnet_a.id, aws_subnet.h20up_db_subnet_b.id, aws_subnet.h20up_db_subnet_c.id]
}

// create an rds postgres instance on free tier
resource "aws_db_instance" "h20up_db" {
  identifier             = "h20up-db"
  publicly_accessible    = "false"
  allocated_storage      = 10
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  storage_type           = "gp2"
  db_name                = "h20updb"
  username               = "h20up"
  password               = "h20uppassword"
  availability_zone      = element(data.aws_availability_zones.available.names, 0)
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.h20up_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.h20up_db_sg.id]

  tags = {
    Name = "dev_db"
  }
}
