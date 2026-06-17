# ---------------------------------------------------------------------------
# Instance role for the app tier. Grants exactly two things:
#   1. SSM Session Manager access (so we never open an SSH port)
#   2. Read-only access to the one database secret it needs
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Managed policy that enables Session Manager (shell access without SSH keys).
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "secret_read" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db.arn]
  }
}

resource "aws_iam_role_policy" "secret_read" {
  name   = "${local.name_prefix}-read-db-secret"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.secret_read.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.app.name
}
