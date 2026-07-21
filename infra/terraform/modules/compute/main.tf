data "aws_partition" "current" {}

resource "aws_iam_role" "backend" {
  name_prefix = "${var.project}-${var.environment}-backend-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-backend-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.backend.name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "backend" {
  name_prefix = "${var.project}-${var.environment}-backend-"
  role        = aws_iam_role.backend.name
}

resource "aws_instance" "backend" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.application_security_group_id]

  associate_public_ip_address = false
  monitoring                  = var.detailed_monitoring
  iam_instance_profile        = aws_iam_instance_profile.backend.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    application_port = var.application_port
  })

  user_data_replace_on_change = true

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "${var.project}-${var.environment}-backend"
    Role = "backend"
  }

  volume_tags = {
    Name = "${var.project}-${var.environment}-backend-root"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]
}

resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.backend.id
  port             = var.application_port
}