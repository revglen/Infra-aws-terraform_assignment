resource "aws_db_instance" "postgres" {
  identifier             = "${var.name}-postgres"
  instance_class         = "db.t3.micro"  # Free tier eligible
  allocated_storage      = 20             # Free tier max
  max_allocated_storage  = 50             # Allow autoscaling if needed
  engine                 = "postgres"
  #engine_version         = "17.4"         # Keep this blank as the latest version will be used
  username               = var.username
  password               = var.password
  db_name                = var.db_name
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  storage_type          = "gp2"
  backup_retention_period = 1
  performance_insights_enabled = false
  deletion_protection   = false
  multi_az             = false
  storage_encrypted    = false  # Free tier doesn't support encryption
  apply_immediately    = true

  # Latest minor version auto-upgrade
  auto_minor_version_upgrade = true
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids
}