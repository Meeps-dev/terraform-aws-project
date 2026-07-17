###desired state 

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "day64_test" {
  bucket        = "meeps-week10-day64-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "meeps-week10-day64-test"
    purpose = "terraform-lifecycle-learning"
  }
}