resource "aws_ssm_parameter" "db_host" {
  name  = "/react-app/db-host"
  type  = "String"
  value = aws_db_instance.h20up_db.address
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/react-app/db-port"
  type  = "String"
  value = aws_db_instance.h20up_db.port
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/react-app/db-name"
  type  = "String"
  value = aws_db_instance.h20up_db.db_name
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/react-app/db-username"
  type  = "String"
  value = aws_db_instance.h20up_db.username
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/react-app/db-password"
  type  = "SecureString"
  value = aws_db_instance.h20up_db.password
}

