resource "aws_security_group" "alb" {
  name_prefix = "${var.project}-alb-"
  description = "Public ALB security group"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = {
    Name = "${var.project}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "application" {
  name_prefix = "${var.project}-application-"
  description = "Private application security group"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = {
    Name = "${var.project}-application-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project}-rds-"
  description = "Private RDS security group"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = {
    Name = "${var.project}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Internet or approved sources can reach only the ALB.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = var.alb_ingress_cidrs

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from approved source ${each.value}"

  cidr_ipv4   = each.value
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.alb_ingress_cidrs

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from approved source ${each.value}"

  cidr_ipv4   = each.value
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# ALB sends traffic only to the application SG.
resource "aws_vpc_security_group_egress_rule" "alb_to_application" {
  security_group_id = aws_security_group.alb.id
  description       = "Application traffic from ALB"

  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
}

# Application accepts traffic only from the ALB SG.
resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id = aws_security_group.application.id
  description       = "Application traffic from ALB"

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
}

# Application sends database traffic only to the RDS SG.
resource "aws_vpc_security_group_egress_rule" "application_to_rds" {
  security_group_id = aws_security_group.application.id
  description       = "Database traffic from application"

  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
}

# RDS accepts database traffic only from the application SG.
resource "aws_vpc_security_group_ingress_rule" "rds_from_application" {
  security_group_id = aws_security_group.rds.id
  description       = "Database traffic from application"

  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
}