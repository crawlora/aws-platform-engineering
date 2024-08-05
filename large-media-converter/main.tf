# Build based on:
# - https://docs.aws.amazon.com/pdfs/solutions/latest/video-on-demand-on-aws-foundation/video-on-demand-on-aws-foundation.pdf
# - https://aws.amazon.com/solutions/implementations/video-on-demand-on-aws/?nc1=h_ls
# - https://medium.com/akava/deploying-containerized-aws-lambda-functions-with-terraform-7147b9815599
# - https://gist.github.com/mhmdio/fc0ba674ae1059f7422cc21dec335526
# - https://www.techtoaster.io/how-to-build-and-push-a-docker-image-to-ecr-with-terraform/
# - https://stackoverflow.com/questions/2677317/how-to-read-remote-video-on-amazon-s3-using-ffmpeg

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.environment}-${var.name}"
  tags = merge({
    Name        = var.name
    Environment = var.environment
  }, var.tags)
}

resource "random_password" "auth_token" {
  length  = 24
  special = false
}

locals {
  output_bucket     = var.output_bucket == "" ? aws_s3_bucket.media-output-bucket[0].bucket : var.output_bucket
  output_bucket_arn = var.output_bucket_arn == "" ? aws_s3_bucket.media-output-bucket[0].arn : var.output_bucket_arn
  auth_token        = var.auth_token == "" ? random_password.auth_token.result : var.auth_token
  all_suffixes      = concat(var.image_file_suffixes, var.video_file_suffixes, var.audio_file_suffixes)
}