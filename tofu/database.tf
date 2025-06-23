# infrastructure/database.tf

# --- Secrets Manager ---
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-db-creds"
  description = "Database credentials for the Aurora cluster"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master_password.result
    # We will let RDS manage host, port, dbname in its own secret integration later
  })
}

resource "random_password" "master_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# --- Aurora Database ---
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-sng"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-aurora-sng"
  }
}

resource "aws_rds_cluster" "aurora_pg" {
  cluster_identifier      = "${var.project_name}-aurora-pg-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "16.3" # Using a stable, supported version
  database_name           = "${var.project_name}db"
  master_username         = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  master_password         = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.database.id]
  skip_final_snapshot     = true
  # In a real production environment, you'd set this to false and have a final_snapshot_identifier.
  # For the Learner Lab, skipping is easier to clean up.
}

resource "aws_rds_cluster_instance" "aurora_pg_instance" {
  count              = 1 # For cost savings in the lab, we'll just run one instance
  identifier         = "${var.project_name}-aurora-pg-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_pg.id
  instance_class     = "db.t3.medium" # Choose a small instance type for the lab
  engine             = aws_rds_cluster.aurora_pg.engine
  engine_version     = aws_rds_cluster.aurora_pg.engine_version
}