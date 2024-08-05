resource "aws_s3_object" "job-config" {
  bucket = aws_s3_bucket.media-config-bucket.bucket
  key    = "job-config.json"

  content = jsonencode({
    Role                 = ""
    Priority             = 0
    StatusUpdateInterval = "SECONDS_60"

    AccelerationSettings = {
      Mode = "PREFERRED"
    }

    Settings = {
      AdAvailOffset = 0

      TimecodeConfig = {
        Source = "ZEROBASED"
      }

      Inputs = [
        {
          FileInput = "s3://${aws_s3_bucket.media-input-bucket.bucket}/"

          FilterEnable   = "AUTO"
          PsiControl     = "USE_PSI"
          FilterStrength = 0
          DeblockFilter  = "DISABLED"
          DenoiseFilter  = "DISABLED"
          TimecodeSource = "ZEROBASED"

          VideoSelector = {
            ColorSpace = "FOLLOW"
          }

          AudioSelectors = {
            "Audio Selector 1" = {
              DefaultSelection = "DEFAULT"
              SelectorType     = "PID"
            }
          }
        }
      ]

      OutputGroups = [{
        CustomName = "mp4"
        Name       = "File Group"

        OutputGroupSettings = {
          Type = "FILE_GROUP_SETTINGS"
          FileGroupSettings = {
            Destination = "s3://${local.output_bucket}/"
          }
        }

        Outputs = [{

          ContainerSettings = {
            Container = "MP4"
            Mp4Settings = {
              CslgAtom      = "INCLUDE"
              FreeSpaceBox  = "EXCLUDE"
              MoovPlacement = "PROGRESSIVE_DOWNLOAD"
            }
          },

          AudioDescriptions = [
            {
              AudioTypeControl = "FOLLOW_INPUT"
              CodecSettings = {
                Codec = "AAC"
                AacSettings = {
                  AudioDescriptionBroadcasterMix = "NORMAL"
                  Bitrate                        = var.video_audio_bitrate
                  CodecProfile                   = "LC"
                  RateControlMode                = "CBR"
                  RawFormat                      = "NONE"
                  SampleRate                     = var.video_audio_sample_rate
                  Specification                  = "MPEG4"
                  CodingMode                     = "CODING_MODE_2_0"
                }
              }
              LanguageCodeControl = "FOLLOW_INPUT"
            }
          ]

          VideoDescription = {
            ScalingBehavior   = "DEFAULT"
            TimecodeInsertion = "DISABLED"
            AntiAlias         = "ENABLED"
            Sharpness         = var.video_sharpness
            AfdSignaling      = "NONE"
            DropFrameTimecode = "ENABLED"
            DropFrameTimecode = "ENABLED"
            RespondToAfd      = "NONE"
            ColorMetadata     = "INSERT"


            CodecSettings = {
              Codec = "H_264"
              H264Settings = {
                InterlaceMode                       = "PROGRESSIVE"
                NumberReferenceFrames               = 3
                Syntax                              = "DEFAULT"
                Softness                            = 0
                GopClosedCadence                    = 1
                GopSize                             = 48
                Slices                              = 1
                GopBReference                       = "DISABLED"
                SlowPal                             = "DISABLED"
                SpatialAdaptiveQuantization         = "ENABLED"
                TemporalAdaptiveQuantization        = "ENABLED"
                FlickerAdaptiveQuantization         = "DISABLED"
                EntropyEncoding                     = "CABAC"
                Bitrate                             = var.video_codec_bitrate
                FramerateControl                    = "SPECIFIED"
                RateControlMode                     = "CBR"
                CodecProfile                        = "HIGH"
                Telecine                            = "NONE"
                MinIInterval                        = 0
                AdaptiveQuantization                = "HIGH"
                CodecLevel                          = "LEVEL_5_2"
                FieldEncoding                       = "PAFF"
                SceneChangeDetect                   = "ENABLED"
                QualityTuningLevel                  = "SINGLE_PASS_HQ"
                FramerateConversionAlgorithm        = "DUPLICATE_DROP"
                UnregisteredSeiTimecode             = "DISABLED"
                GopSizeUnits                        = "FRAMES"
                ParControl                          = "INITIALIZE_FROM_SOURCE"
                NumberBFramesBetweenReferenceFrames = 3
                RepeatPps                           = "DISABLED"
                HrdBufferSize                       = var.video_codec_bitrate * 2
                HrdBufferInitialFillPercentage      = 90
                FramerateNumerator                  = 25
                FramerateDenominator                = 1
              }
            }
          }
        }]

        },
        {
          CustomName = "thumbnails"
          Name       = "File Group"

          OutputGroupSettings = {
            Type = "FILE_GROUP_SETTINGS"
            FileGroupSettings = {
              Destination = "s3://${local.output_bucket}/"
            }
          }

          Outputs = [{

            ContainerSettings = {
              Container = "RAW"
            }

            VideoDescription = {
              CodecSettings = {
                Codec = "FRAME_CAPTURE"
                FrameCaptureSettings = {
                  FramerateNumerator   = 30
                  FramerateDenominator = 30
                  MaxCaptures          = 1
                  Quality              = 80
                }
              }
            }
          }]
        }
      ]
    }

  })
}