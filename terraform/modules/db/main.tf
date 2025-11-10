# resource "aws_s3_bucket" "us_east_bucket" {
#     bucket = var.S3_bucket_name
# }

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "nkydigitech-${var.projectname}-dbsubnet-group-${terraform.workspace}"
  subnet_ids = var.db_subnet_ids
  tags = var.tags
}

resource "aws_db_instance" "mysql_rds" {
  identifier = "mysql-${terraform.workspace}"
  allocated_storage    = 10
  db_name              = var.dbname
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpass
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [var.priv_sg_id]
  multi_az = false
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  tags = var.tags
}

# resource "random_password" "rds_password" {
#   length  = 16
#   special = true
#   override_special = "_%#*?!"  # exclude '/', '@', '"', and space
# }

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "my-rds-password-${terraform.workspace}"
  tags = var.tags
}

# Put the generated password into the secret
resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.dbuser
    password = var.dbpass
    dbname   = var.dbname
  })
}


