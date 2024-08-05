class LambdaException(Exception):
    """Base class for Lambda exceptions."""


class UnsupportedPayloadException(LambdaException):
    """Raised when the payload is not supported."""


class NoEventBodyException(UnsupportedPayloadException):
    """Raised when event.body is not defined."""


class UnsupportedTypeException(LambdaException):
    """Raised when the media type is not supported."""


class UnsupportedFileException(UnsupportedTypeException):
    """Raised when the file extension is not supported."""


class UnsupportedExtensionException(UnsupportedTypeException):
    """Raised when the file extension is not supported."""


class FFProbeException(LambdaException):
    """Raised when ffprobe fails to return a valid response."""


class InputFormatException(FFProbeException):
    """Raised when the input file is not in a supported format."""


class MediaInfoException(LambdaException):
    """Raised when mediainfo fails to return a valid response."""


class ElementalConvertException(LambdaException):
    """Raised when Elemental MediaConvert fails to process the video."""
