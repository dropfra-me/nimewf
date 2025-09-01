type
  # From libewf/definitions.h
  Format* = enum
    fmtUnknown = 0x00, fmtEncase1 = 0x01, fmtEncase2 = 0x02,
    fmtEncase3 = 0x03, fmtEncase4 = 0x04, fmtEncase5 = 0x05,
    fmtEncase6 = 0x06, fmtEncase7 = 0x07,
    fmtSmart = 0x0e, fmtFtkImager = 0x0f,
    fmtLogicalEncase5 = 0x10, fmtLogicalEncase6 = 0x11, fmtLogicalEncase7 = 0x12,
    fmtLinen5 = 0x25, fmtLinen6 = 0x26, fmtLinen7 = 0x27,
    fmtEwf = 0x70, fmtEwfx = 0x71

  MediaType* = enum
    mediaRemovable = 0x00, mediaFixed = 0x01, mediaOptical = 0x03,
    mediaSingleFiles = 0x0e, mediaMemory = 0x10

  MediaFlag* = enum
    mediaPhysical = 0x02, mediaFastBloc = 0x04, mediaTableau = 0x08

  CompressionFlag* = enum
    compressEmptyBlock = 0x01

  # Compression level accepts -1..2; use a range + named constants for ergonomics.
  CompressionLevel* = range[-1..2]

const
  clDefault* = CompressionLevel(-1)
  clNone*    = CompressionLevel(0)
  clFast*    = CompressionLevel(1)
  clBest*    = CompressionLevel(2)

const
  allCompressionFlags = [compressEmptyBlock]
  allMediaFlags = [mediaPhysical, mediaFastBloc, mediaTableau]

# Enumerations for safe mapping from numeric values without hole-conversion warnings
const
  allFormats*: array[18, Format] = [
    fmtUnknown,
    fmtEncase1, fmtEncase2, fmtEncase3, fmtEncase4, fmtEncase5, fmtEncase6, fmtEncase7,
    fmtSmart, fmtFtkImager,
    fmtLogicalEncase5, fmtLogicalEncase6, fmtLogicalEncase7,
    fmtLinen5, fmtLinen6, fmtLinen7,
    fmtEwf, fmtEwfx
  ]

  allMediaTypes*: array[5, MediaType] = [
    mediaRemovable, mediaFixed, mediaOptical, mediaSingleFiles, mediaMemory
  ]

proc toU8*[T](s: set[T]): uint8 =
  ## Convert a set of enum flags to a uint8 bitmask.
  ## Supports enums with holes by iterating a curated list per type.
  var v: uint8 = 0
  when T is CompressionFlag:
    for f in allCompressionFlags:
      if f in s: v = v or uint8(ord(f))
  elif T is MediaFlag:
    for f in allMediaFlags:
      if f in s: v = v or uint8(ord(f))
  else:
    {.error: "toU8 only supports CompressionFlag and MediaFlag".}
  v

proc fromU8*[T](mask: uint8): set[T] =
  ## Convert a uint8 bitmask to a set of enum flags.
  ## Supports only known flag enums via curated lists.
  result = {}
  when T is CompressionFlag:
    for f in allCompressionFlags:
      if (mask and uint8(ord(f))) != 0'u8: result.incl(f)
  elif T is MediaFlag:
    for f in allMediaFlags:
      if (mask and uint8(ord(f))) != 0'u8: result.incl(f)
  else:
    {.error: "fromU8 only supports CompressionFlag and MediaFlag".}

proc findEnumByOrd*[T](x: uint8, vals: openArray[T], default: T): T {.inline.} =
  ## Returns the enum value whose ordinal equals x, or default if none match.
  for v in vals:
    if uint8(ord(v)) == x: return v
  default
