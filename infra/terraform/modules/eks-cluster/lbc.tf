# IRSA role for the AWS Load Balancer Controller (installed by Argo CD).
# Policy: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/v2.17.1/docs/install/iam_policy.json
locals {
  oidc_host = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

data "aws_iam_policy_document" "lbc_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.name}-lbc"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "lbc" {
  name   = "${var.name}-lbc"
  policy = file("${path.module}/lbc-iam-policy.json")
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}
