# S3 Triggered Lambdas

## Video Lambda

resource "aws_lambda_function" "video_submit_lambda" {
  function_name = "${local.name}-submit_video"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"

  image_config {
    command = ["submit_video.handler"]
  }
  timeout     = 60
  memory_size = 512

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      ENVIRONMENT               = var.environment
      SENTRY_DSN                = var.sentry_dsn
      SENTRY_TRACES_SAMPLE_RATE = var.sentry_traces_sample_rate

      MEDIACONVERT_ENDPOINT = var.mediaconvert_endpoint
      MEDIACONVERT_ROLE     = aws_iam_role.mediaconvert_role.arn
      DESTINATION_BUCKET    = local.output_bucket
      CONFIG_BUCKET         = aws_s3_bucket.media-config-bucket.bucket
      JOB_CONFIG            = aws_s3_object.job-config.key
      SNS_TOPIC_ARN         = aws_sns_topic.large-media-upload-updates.arn

      INPUT_FILE_SUFFIXES = jsonencode(var.video_file_suffixes)
      MAX_WIDTH           = var.video_max_width
      MAX_HEIGHT          = var.video_max_height
    }
  }
}

resource "aws_lambda_permission" "video_submit_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_submit_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.large-media-upload-event.arn
}

## Image Lambda

resource "aws_lambda_function" "process_image" {
  function_name = "${local.name}-process_image"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 20
  memory_size  = 512

  image_config {
    command = ["process_image.handler"]
  }


  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      ENVIRONMENT               = var.environment
      SENTRY_DSN                = var.sentry_dsn
      SENTRY_TRACES_SAMPLE_RATE = var.sentry_traces_sample_rate

      DESTINATION_BUCKET  = local.output_bucket
      SNS_TOPIC_ARN       = aws_sns_topic.large-media-upload-updates.arn
      INPUT_FILE_SUFFIXES = jsonencode(var.image_file_suffixes)
    }
  }
}

resource "aws_lambda_permission" "process_image" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_image.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.large-media-upload-event.arn
}

## Audio Lambda

resource "aws_lambda_function" "process_audio" {
  function_name = "${local.name}-process_audio"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 20
  memory_size  = 512

  image_config {
    command = ["process_audio.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      ENVIRONMENT               = var.environment
      SENTRY_DSN                = var.sentry_dsn
      SENTRY_TRACES_SAMPLE_RATE = var.sentry_traces_sample_rate

      DESTINATION_BUCKET  = local.output_bucket
      SNS_TOPIC_ARN       = aws_sns_topic.large-media-upload-updates.arn
      INPUT_FILE_SUFFIXES = jsonencode(var.audio_file_suffixes)
    }
  }
}

resource "aws_lambda_permission" "process_audio" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_audio.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.large-media-upload-event.arn
}

# Complete Lambda

resource "aws_lambda_function" "video_complete_lambda" {
  function_name = "${local.name}-complete_video"
  role          = aws_iam_role.job_complete_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 20
  memory_size  = 512

  image_config {
    command = ["complete_video.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      MEDIACONVERT_ENDPOINT = var.mediaconvert_endpoint
      SNS_TOPIC_ARN         = aws_sns_topic.large-media-upload-updates.arn
    }
  }
}

resource "aws_lambda_permission" "video_complete_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_complete_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.video_complete_lambda.arn

  depends_on = [aws_cloudwatch_event_rule.video_complete_lambda]
}

resource "aws_cloudwatch_event_rule" "video_complete_lambda" {
  name        = "${local.name}-video_complete_lambda"
  description = "Capture the mediaconvert stages"

  event_pattern = jsonencode({
    source = [
      "aws.mediaconvert"
    ]
    detail = {
      status = [
        "COMPLETE",
        "ERROR",
        "CANCELED",
        "INPUT_INFORMATION"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "video_complete_lambda" {
  rule = aws_cloudwatch_event_rule.video_complete_lambda.name
  arn  = aws_lambda_function.video_complete_lambda.arn

  depends_on = [aws_cloudwatch_event_rule.video_complete_lambda]
}


# API Gateway Lambdas

## Initialize Lambda

resource "aws_lambda_function" "initialize" {
  function_name = "${local.name}-initialize"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 10

  image_config {
    command = ["initialize.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      BUCKET_NAME         = aws_s3_bucket.media-input-bucket.bucket
      INPUT_FILE_SUFFIXES = jsonencode(local.all_suffixes)
    }
  }
}

## presigned_urls Lambda

resource "aws_lambda_function" "presigned_urls" {
  function_name = "${local.name}-presigned_urls"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 10

  image_config {
    command = ["presign_urls.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      BUCKET_NAME         = aws_s3_bucket.media-input-bucket.bucket
      INPUT_FILE_SUFFIXES = jsonencode(local.all_suffixes)
      URL_EXPIRES         = 3600
    }
  }
}

# finalize Lambda

resource "aws_lambda_function" "finalize" {
  function_name = "${local.name}-finalize"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 10

  image_config {
    command = ["finalize.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      BUCKET_NAME         = aws_s3_bucket.media-input-bucket.bucket
      INPUT_FILE_SUFFIXES = jsonencode(local.all_suffixes)
    }
  }
}

## Auth Lambda

resource "aws_lambda_function" "auth" {
  function_name = "${local.name}-auth"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 10

  image_config {
    command = ["auth.handler"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      AUTH_TOKEN  = local.auth_token
      AUTH_HEADER = var.auth_header
    }
  }
}

## Mediainfo Lambda

resource "aws_lambda_function" "mediainfo" {
  function_name = "${local.name}-mediainfo"
  role          = aws_iam_role.lambda_role.arn

  image_uri    = "${aws_ecr_repository.lambda_repository.repository_url}:${local.image_tag}"
  package_type = "Image"
  timeout      = 10

  image_config {
    command = ["mediainfo.handler"]
  }


  depends_on = [
    aws_iam_role_policy_attachment.iam_policy_for_job_complete_role,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_lambda,
    aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_mediaconvert,
    resource.null_resource.build_push_dkr_img,
  ]

  environment {
    variables = {
      INPUT_FILE_SUFFIXES = jsonencode(local.all_suffixes)
    }
  }
}