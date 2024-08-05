variable "environment" {
  type    = string
  default = "dev"
}

variable "name" {
  type    = string
  default = "lmu"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# MediaConvert

variable "mediaconvert_endpoint" {
  type        = string
  description = "MediaConvert endpoint"
}

# Buckets

variable "input_bucket_delete_after_days" {
  type        = number
  description = "Number of days after which to delete input files"
  default     = 1
}

variable "output_bucket" {
  type        = string
  description = "S3 bucket for MediaConvert outputs"
  default     = ""
}

variable "output_bucket_arn" {
  type        = string
  description = "S3 bucket for MediaConvert outputs"
  default     = ""
}

# Image File Settings

variable "image_file_suffixes" {
  type        = list(string)
  description = "List of image file suffixes"
  default = [
    ".bmp",
    ".jpg", ".jpeg",
    ".png",
    ".tif", ".tiff",
    ".webp",
    ".svg",
    ".gif"
  ]
}

# Video Conversion Settings

variable "video_file_suffixes" {
  type        = list(string)
  description = "List of video file suffixes"
  default = [
    ".3g2", ".3gp",
    ".asf", ".wmv",
    ".avi",
    ".f4v", ".flv",
    ".hls",
    ".imf",
    ".j2k",
    ".mkv", ".mk3d", ".mka", ".mks",
    ".mov", ".qt",
    ".mp4", ".m4v", ".h264", ".m4p",
    ".mpeg", ".mpg", ".m1v", ".m2v", ".mts", ".m2ts", ".ts", ".mp2", ".mpv",
    ".m2ts", ".ts", ".mts",
    ".mxf",
    ".vob",
    ".webm",
    ".yuv"
  ]
}

# Audio File Suffixes

variable "audio_file_suffixes" {
  type        = list(string)
  description = "List of audio file suffixes"
  default = [
    ".aac",
    ".ac3",
    ".aiff", ".aif", ".aifc",
    ".amr",
    ".au",
    ".flac",
    ".m4a",
    ".mp2",
    ".mp3",
    ".ogg",
    ".wav",
    ".wma"
  ]
}

variable "video_max_width" {
  type        = number
  description = "Max width for video"
  default     = 1800
}

variable "video_max_height" {
  type        = number
  description = "Max height for video"
  default     = 1800
}

variable "video_sharpness" {
  type        = number
  description = "Sharpness for video"
  default     = 50
}

variable "video_audio_bitrate" {
  type        = number
  description = "Audio bitrate for video"
  default     = 128000
}

variable "video_audio_sample_rate" {
  type        = number
  description = "Audio sample rate for video"
  default     = 48000
}

variable "video_codec_bitrate" {
  type        = number
  description = "Codec bitrate for video"
  default     = 1500000
}

# Video Detection Lambda Settings

variable "force_image_rebuild" {
  type        = bool
  default     = false
  description = "Force rebuild of the docker image for the submit lambda"
}

variable "sentry_dsn" {
  type        = string
  description = "Sentry DSN for the lambdas"
  default     = ""
}

variable "sentry_traces_sample_rate" {
  type        = number
  description = "Sentry traces sample rate for the lambdas"
  default     = 1.0
}

# Authorization Settings

variable "auth_token" {
  type        = string
  description = "Authorization key for the lambdas"
  default     = ""
}

variable "auth_header" {
  type        = string
  description = "Name of the authorization header"
  default     = "authorization"
}