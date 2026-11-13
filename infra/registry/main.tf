resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # Sandbox: allows cleanup of the exercise, including images.
  encryption_configuration { encryption_type = "AES256" }
  image_scanning_configuration { scan_on_push = true }
}
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({ rules = [{
    rulePriority = 1
    description  = "Expire untagged images after 1 day; retain tagged releases for rollback"
    selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 1 }
    action       = { type = "expire" }
  }] })
}
output "repository_url" { value = aws_ecr_repository.app.repository_url }
