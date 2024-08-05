resource "aws_iam_role" "lambda_role" {
  name               = "${local.name}-lambda-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "${local.name}-lambda-policy"
  path        = "/"
  description = "AWS IAM Policy for LMU Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "arn:aws:logs:*:*:*",
        Effect   = "Allow",
      },
      {
        Action = [
          "sns:Publish",
        ],
        Resource = "arn:aws:sns:*",
        Effect   = "Allow",
      },
      {
        Action = [
          "s3:*",
        ],
        Resource = "arn:aws:s3:::*",
        Effect   = "Allow",
      },
      {
        Action   = "mediaconvert:CreateJob",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "iam:PassRole",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_iam_role" "mediaconvert_role" {
  name               = "${local.name}-mediaconvert-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "mediaconvert.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_mediaconvert" {
  name        = "${local.name}-mediaconvert-policy"
  path        = "/"
  description = "AWS IAM Policy for LMU mediaconvert"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
        ],
        Resource = "arn:aws:s3:::*",
        Effect   = "Allow",
      },
      {
        Action   = "execute-api:Invoke",
        Resource = "*",
        Effect   = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_mediaconvert" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = aws_iam_policy.iam_policy_for_mediaconvert.arn
}


resource "aws_iam_role" "job_complete_role" {
  name               = "${local.name}-complete-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "job_complete_role" {
  name        = "${local.name}-complete-policy"
  path        = "/"
  description = "AWS IAM Policy for LMU Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "arn:aws:logs:*:*:*",
        Effect   = "Allow",
      },
      {
        Action = [
          "sns:Publish",
        ],
        Resource = "arn:aws:sns:*",
        Effect   = "Allow",
      },
      {
        Action = [
          "s3:*",
        ],
        Resource = "arn:aws:s3:::*",
        Effect   = "Allow",
      },
      {
        Action   = "mediaconvert:GetJob",
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iam_policy_for_job_complete_role" {
  role       = aws_iam_role.job_complete_role.name
  policy_arn = aws_iam_policy.job_complete_role.arn
}

resource "aws_iam_policy" "iam_policy_for_api_gateway" {
  name        = "${local.name}-api_gateway-policy"
  description = "AWS IAM Policy for LMU api_gateway"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "execute-api:Invoke",
        Resource = "*",
        Effect   = "Allow",
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_sns_notification" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.media-input-bucket.arn]
    }
  }
}