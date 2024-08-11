resource "aws_ecr_repository" "repository" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "ecr_life_cycle_policy" {
  repository = aws_ecr_repository.repository.name
  depends_on = [aws_ecr_repository.repository]

  policy = <<EOF
{
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 50 images and remove rest",
        "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
        
      }
    }
  ]
}
EOF
}
