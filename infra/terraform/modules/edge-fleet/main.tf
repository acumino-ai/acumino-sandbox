# Identity used by edge site clusters to ship logs to CloudWatch.
# Access keys are created per site by scripts/bootstrap-edge-site.sh.
resource "aws_iam_user" "edge" {
  name = "edge-fleet"
  tags = var.tags
}

data "aws_iam_policy_document" "edge" {
  statement {
    actions   = ["logs:*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "edge" {
  name   = "edge-logs"
  user   = aws_iam_user.edge.name
  policy = data.aws_iam_policy_document.edge.json
}

variable "tags" {
  type    = map(string)
  default = {}
}

output "user_name" {
  value = aws_iam_user.edge.name
}
