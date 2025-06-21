# terraform/database.tf

# 1. Store DB Credentials securely in Secrets Manager
resource "aws_secretsmanager_secret" "db_creds" {
  name = "ReactSecOps/DbCredentials"
}

# Note: In a real project, you'd use random_password. For simplicity
# and to avoid extra providers, we will hardcode them here.
# this is a tradeoff for the lab environment.
resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    username = "masteradmin"
    password = "ReactSecOps156!" 
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = "webappdb"
  })
}

# 2. DB Subnet Group - Tells RDS which subnets to live in
resource "aws_db_subnet_group" "main" {
  name       = "react-sec-deploy-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "React-Sec-Deploy DB Subnet Group"
  }
}

# 3. The RDS PostgreSQL Database Instance
resource "aws_db_instance" "main" {
  identifier           = "react-sec-deploy-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro" # Small instance for the lab
  db_name              = "webappdb"
  username             = jsondecode(aws_secretsmanager_secret_version.db_creds.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot  = true
  publicly_accessible  = false # important Ensure it's not on the public internet
}