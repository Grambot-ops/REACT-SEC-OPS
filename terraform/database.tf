# terraform/database.tf

# 1. Generate a secure, random password for the database.
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_`{|}~" # Characters supported by RDS
}

# 2. Store ONLY the credentials (username/password) in Secrets Manager.
# This resource no longer depends on the database instance, breaking the cycle.
resource "aws_secretsmanager_secret" "db_creds" {
  name = "ReactSecOps/DbCredentials"
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    username = "masteradmin"
    password = random_password.db_password.result
  })
}

# 3. DB Subnet Group - Tells RDS which subnets to live in (no change here)
resource "aws_db_subnet_group" "main" {
  name       = "react-sec-ops-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "React-Sec-Ops DB Subnet Group"
  }
}

# 4. The RDS PostgreSQL Database Instance
# Now, this resource can be created because its dependency (the secret) can be created first.
resource "aws_db_instance" "main" {
  identifier           = "react-sec-ops-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.14"
  instance_class       = "db.t3.micro" # Small instance for the lab
  db_name              = "webappdb"    # We define the dbname here directly
  username             = jsondecode(aws_secretsmanager_secret_version.db_creds.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot  = true
  publicly_accessible  = false # CRITICAL: Ensure it's not on the public internet
}