resource "aws_s3_bucket" "media-config-bucket" {
  bucket = "${local.name}-media-config-bucket"
}

# Input Bucket

resource "aws_s3_bucket" "media-input-bucket" {
  bucket = "${local.name}-media-input-bucket"

  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.bucket

  rule {
    id     = "delete-after-${var.input_bucket_delete_after_days}-day"
    status = "Enabled"
    expiration {
      days = var.input_bucket_delete_after_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.input_bucket_delete_after_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

  }
}

resource "aws_s3_bucket_accelerate_configuration" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.id
  status = "Enabled"
}

resource "aws_s3_bucket_cors_configuration" "media-input-bucket" {
  bucket = aws_s3_bucket.media-input-bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_origins = ["*"]

    allowed_methods = ["PUT", "POST", "GET"]

    expose_headers = ["ETag"]
  }
}

resource "aws_s3_bucket_notification" "media_input_bucket_notification" {
  bucket = aws_s3_bucket.media-input-bucket.id

  topic {
    topic_arn = aws_sns_topic.large-media-upload-event.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_function.video_submit_lambda,
    aws_lambda_function.process_image,
    aws_lambda_function.process_audio,
    aws_s3_bucket.media-input-bucket
  ]
}

# Output Bucket

resource "aws_s3_bucket" "media-output-bucket" {
  bucket        = "${local.name}-media-output-bucket"
  force_destroy = true

  count = var.output_bucket == "" ? 1 : 0
}

resource "aws_s3_bucket_ownership_controls" "media-output-bucket" {
  bucket = aws_s3_bucket.media-output-bucket[0].bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  count = var.output_bucket == "" ? 1 : 0
}

resource "aws_s3_bucket_public_access_block" "media-output-bucket" {
  bucket = aws_s3_bucket.media-output-bucket[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  count = var.output_bucket == "" ? 1 : 0
}