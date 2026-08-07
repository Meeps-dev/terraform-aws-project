resource "aws_iam_role" "backend" {
  name_prefix = "${var.project}-${var.environment}-backend-"

  assume_role_policy = data.aws_iam_policy_document.backend_assume_role.json

  tags = merge(
    var.tags,
    {
      project     = var.project
      environment = var.environment
      Name        = "${var.project}-${var.environment}-backend-role"
    }
  )
}

resource "aws_iam_instance_profile" "backend" {
  name_prefix = "${var.project}-${var.environment}-backend-"
  role        = aws_iam_role.backend.name

  tags = merge(
    var.tags,
    {
      project     = var.project
      environment = var.environment
    }
  )
}

resource "aws_instance" "backend" {
  ami           = data.aws_ami.amazon_linux_2023.id
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

  tags = merge(
    var.tags,
    {
      project     = var.project
      environment = var.environment
      Name        = "${var.project}-${var.environment}-backend"
      Role        = "backend"
    }
  )

  volume_tags = merge(
    var.tags,
    {
      project     = var.project
      environment = var.environment
      Name        = "${var.project}-${var.environment}-backend-root"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy.runtime_access,
  ]
}

resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.backend.id
  port             = var.application_port
}
