resource "aws_ecr_repository" "lambda_repository" {
  name                 = "${local.name}-lambda"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }

  force_delete = true
  tags         = var.tags
}

resource "aws_ecr_lifecycle_policy" "ecr_life_cycle_policy" {
  repository = aws_ecr_repository.lambda_repository.name
  depends_on = [aws_ecr_repository.lambda_repository]

  policy = <<EOF
{
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 10 images and remove rest",
        "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
        
      }
    }
  ]
}
EOF
}


locals {
  aws_account = data.aws_caller_identity.current.account_id
  aws_region  = data.aws_region.current.name
  aws_profile = split("/", data.aws_caller_identity.current.arn)[1]

  ecr_reg = "${local.aws_account}.dkr.ecr.${local.aws_region}.amazonaws.com"

  ecr_repo = aws_ecr_repository.lambda_repository.name

  dkr_img_src_path   = "${path.module}/lambdas"
  dkr_img_src_sha256 = sha256(join("", [for f in fileset(".", "${local.dkr_img_src_path}/**") : filebase64(f)]))
  image_tag          = substr(local.dkr_img_src_sha256, 0, 8)

  dkr_build_cmd = <<-EOT
      docker buildx build --platform linux/amd64 \
            -t ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag} \
            -f ${local.dkr_img_src_path}/Dockerfile \
            ${local.dkr_img_src_path}

      aws ecr get-login-password --region ${local.aws_region} | 
          docker login --username AWS --password-stdin ${local.ecr_reg}

      docker push ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag}
    EOT

}

resource "null_resource" "build_push_dkr_img" {
  triggers = {
    detect_docker_source_changes = var.force_image_rebuild == true ? timestamp() : local.dkr_img_src_sha256
  }
  provisioner "local-exec" {
    command = local.dkr_build_cmd
  }

  depends_on = [aws_ecr_repository.lambda_repository]
}

output "trigged_by" {
  value = null_resource.build_push_dkr_img.triggers
}