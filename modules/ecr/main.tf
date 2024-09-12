resource "aws_ecr_repository" "repo" {
  name = "${var.app_name}-${var.tier}-ecr"

  force_delete = true
}