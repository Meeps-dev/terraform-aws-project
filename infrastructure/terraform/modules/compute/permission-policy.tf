resource "aws_iam_role_policy" "runtime_access" {
  name = "${var.project}-${var.environment}-backend-runtime"
  role = aws_iam_role.backend.id

  policy = data.aws_iam_policy_document.runtime_access.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.backend.name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
