import bumpy, chroma, flatty/binny, os, pixie/blends, pixie/common,
    pixie/contexts, pixie/fileformats/bmp, pixie/fileformats/gif,
    pixie/fileformats/jpg, pixie/fileformats/png, pixie/fileformats/svg,
    pixie/fonts, pixie/images, pixie/masks, pixie/paints, pixie/paths, strutils, vmath

export blends, bumpy, chroma, common, contexts, fonts, images, masks, paints,
    paths, vmath

type
  FileFormat* = enum
    ffPng, ffBmp, ffJpg, ffGif

converter autoStraightAlpha*(c: ColorRGBX): ColorRGBA {.inline, raises: [].} =
  ## Convert a premultiplied alpha RGBA to a straight alpha RGBA.
  c.rgba()

converter autoPremultipliedAlpha*(c: ColorRGBA): ColorRGBX {.inline, raises: [].} =
  ## Convert a straight alpha RGBA to a premultiplied alpha RGBA.
  c.rgbx()

proc decodeImage*(
  data: string | seq[uint8]; width = 0; height = 0
): Image {.raises: [PixieError].} =
  ## Loads an image from memory.
  if data.len > 8 and data.readUint64(0) == cast[uint64](pngSignature):
    decodePng(data, width, height)
  elif data.len > 2 and data.readUint16(0) == cast[uint16](jpgStartOfImage):
    decodeJpg(data, width, height)
  elif data.len > 2 and data.readStr(0, 2) == bmpSignature:
    decodeBmp(data, width, height)
  elif data.len > 5 and
    (data.readStr(0, 5) == xmlSignature or data.readStr(0, 4) == svgSignature):
    decodeSvg(data, width, height)
  elif data.len > 6 and data.readStr(0, 6) in gifSignatures:
    decodeGif(data, width, height)
  else:
    raise newException(PixieError, "Unsupported image file format")

proc decodeMask*(data: string | seq[uint8]): Mask {.raises: [PixieError].} =
  ## Loads a mask from memory.
  if data.len > 8 and data.readUint64(0) == cast[uint64](pngSignature):
    newMask(decodePng(data))
  else:
    raise newException(PixieError, "Unsupported mask file format")

proc readImage*(
  filePath: string; width = 0; height = 0
): Image {.inline, raises: [PixieError].} =
  ## Loads an image from a file.
  try:
    decodeImage(readFile(filePath), width, height)
  except IOError as e:
    raise newException(PixieError, e.msg, e)

proc readMask*(filePath: string): Mask {.raises: [PixieError].} =
  ## Loads a mask from a file.
  try:
    decodeMask(readFile(filePath))
  except IOError as e:
    raise newException(PixieError, e.msg, e)

proc encodeImage*(image: Image, fileFormat: FileFormat): string {.raises: [PixieError].} =
  ## Encodes an image into memory.
  case fileFormat:
  of ffPng:
    image.encodePng()
  of ffJpg:
    image.encodeJpg()
  of ffBmp:
    image.encodeBmp()
  of ffGif:
    raise newException(PixieError, "Unsupported file format")

proc encodeMask*(mask: Mask, fileFormat: FileFormat): string {.raises: [PixieError].} =
  ## Encodes a mask into memory.
  case fileFormat:
  of ffPng:
    mask.encodePng()
  else:
    raise newException(PixieError, "Unsupported file format")

proc writeFile*(image: Image, filePath: string) {.raises: [PixieError].} =
  ## Writes an image to a file.
  let fileFormat = case splitFile(filePath).ext.toLowerAscii():
    of ".png": ffPng
    of ".bmp": ffBmp
    of ".jpg", ".jpeg": ffJpg
    else:
      raise newException(PixieError, "Unsupported file extension")

  try:
    writeFile(filePath, image.encodeImage(fileFormat))
  except IOError as e:
    raise newException(PixieError, e.msg, e)

proc writeFile*(mask: Mask, filePath: string) {.raises: [PixieError].} =
  ## Writes a mask to a file.
  let fileFormat = case splitFile(filePath).ext.toLowerAscii():
    of ".png": ffPng
    of ".bmp": ffBmp
    of ".jpg", ".jpeg": ffJpg
    else:
      raise newException(PixieError, "Unsupported file extension")

  try:
    writeFile(filePath, mask.encodeMask(fileFormat))
  except IOError as e:
    raise newException(PixieError, e.msg, e)
