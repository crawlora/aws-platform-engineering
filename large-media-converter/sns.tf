resource "aws_sns_topic" "large-media-upload-updates" {
  name = "${local.name}-large-media-upload-updates"
}

resource "aws_sns_topic" "large-media-upload-event" {
  name   = "${local.name}-large-media-upload-event"
  policy = data.aws_iam_policy_document.s3_sns_notification.json
}

resource "aws_sns_topic_subscription" "video_submit_lambda" {
  topic_arn = aws_sns_topic.large-media-upload-event.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.video_submit_lambda.arn
}

resource "aws_sns_topic_subscription" "process_image" {
  topic_arn = aws_sns_topic.large-media-upload-event.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process_image.arn
}

resource "aws_sns_topic_subscription" "process_audio" {
  topic_arn = aws_sns_topic.large-media-upload-event.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process_audio.arn
}