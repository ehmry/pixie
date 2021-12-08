import chroma, flatty/binny, pixie/common, pixie/images

# See: https://en.wikipedia.org/wiki/BMP_file_format

const bmpSignature* = "BM"

proc decodeBmp*(
  data: string; width = 0; height = 0
): Image {.raises: [PixieError].} =
  ## Decodes bitmap data into an Image.

  # BMP Header
  if data[0 .. 1] != "BM":
    raise newException(PixieError, "Invalid BMP data")

  let
    bmpWidth = data.readInt32(18).int
    bmpHeight = data.readInt32(22).int
    bits = data.readUint16(28).int
    compression = data.readUint32(30).int
  var
    offset = data.readUInt32(10).int

  if bits notin [32, 24]:
    raise newException(PixieError, "Unsupported BMP data format")

  if compression notin [0, 3]:
    raise newException(PixieError, "Unsupported BMP data format")

  let channels = if bits == 32: 4 else: 3
  if bmpWidth * bmpHeight * channels + offset > data.len:
    raise newException(PixieError, "Invalid BMP data size")

  result = newImage(bmpWidth, bmpHeight)

  for y in 0 ..< result.height:
    for x in 0 ..< result.width:
      var rgba: ColorRGBA
      if bits == 32:
        rgba.r = data.readUint8(offset + 0)
        rgba.g = data.readUint8(offset + 1)
        rgba.b = data.readUint8(offset + 2)
        rgba.a = data.readUint8(offset + 3)
        offset += 4
      elif bits == 24:
        rgba.r = data.readUint8(offset + 2)
        rgba.g = data.readUint8(offset + 1)
        rgba.b = data.readUint8(offset + 0)
        rgba.a = 255
        offset += 3
      result[x, result.height - y - 1] = rgba.rgbx()

  if width notin {0, bmpWidth} or height notin {0, bmpHeight}:
    result = resize(result, width, height)

proc decodeBmp*(
  data: seq[uint8]; width = 0; height = 0
): Image {.inline, raises: [PixieError].} =
  ## Decodes bitmap data into an Image.
  decodeBmp(cast[string](data), width, height)

proc encodeBmp*(image: Image): string {.raises: [].} =
  ## Encodes an image into the BMP file format.

  # BMP Header
  result.add("BM") # The header field used to identify the BMP
  result.addUint32(0) # The size of the BMP file in bytes.
  result.addUint16(0) # Reserved.
  result.addUint16(0) # Reserved.
  result.addUint32(122) # The offset to the pixel array.

  # DIB Header
  result.addUint32(108) # Size of this header
  result.addInt32(image.width.int32) # Signed integer.
  result.addInt32(image.height.int32) # Signed integer.
  result.addUint16(1) # Must be 1 (color planes).
  result.addUint16(32) # Bits per pixels, only support RGBA.
  result.addUint32(3) # BI_BITFIELDS, no pixel array compression used
  result.addUint32(32) # Size of the raw bitmap data (including padding)
  result.addUint32(2835) # Print resolution of the image
  result.addUint32(2835) # Print resolution of the image
  result.addUint32(0) # Number of colors in the palette
  result.addUint32(0) # 0 means all colors are important
  result.addUint32(uint32(0x000000FF)) # Red channel.
  result.addUint32(uint32(0x0000FF00)) # Green channel.
  result.addUint32(uint32(0x00FF0000)) # Blue channel.
  result.addUint32(uint32(0xFF000000)) # Alpha channel.
  result.add("Win ") # little-endian.
  for i in 0 ..< 48:
    result.addUint8(0) # Unused

  for y in 0 ..< image.height:
    for x in 0 ..< image.width:
      let rgba = image[x, image.height - y - 1].rgba()
      result.addUint8(rgba.r)
      result.addUint8(rgba.g)
      result.addUint8(rgba.b)
      result.addUint8(rgba.a)

  result.writeUInt32(2, result.len.uint32)
