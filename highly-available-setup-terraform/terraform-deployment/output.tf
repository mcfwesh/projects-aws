output "h20up_db" {
  value = {
    db_name     = aws_db_instance.h20up_db.db_name
    db_username = aws_db_instance.h20up_db.username
    db_password = aws_db_instance.h20up_db.password
    db_host     = aws_db_instance.h20up_db.address
    db_port     = aws_db_instance.h20up_db.port
  }

  sensitive = true

}
