import pixie/common, pixie/images

when defined(pixieUseStb):
  import pixie/fileformats/stb_image/stb_image

const
  jpgStartOfImage* = [0xFF.uint8, 0xD8]

proc decodeJpg*(
  data: seq[uint8]; width = 0; height = 0
): Image {.raises: [PixieError].} =
  ## Decodes the JPEG into an Image.
  when not defined(pixieUseStb):
    raise newException(PixieError, "Decoding JPG requires -d:pixieUseStb")
  else:
    var jpgWidth, jpgHeight: int
    let pixels = loadFromMemory(data, jpgWidth, jpgHeight)

    result = newImage(jpgWidth, jpgHeight)
    copyMem(result.data[0].addr, pixels[0].unsafeAddr, pixels.len)
    if width notin {0, jpgWidth} or height notin {0, jpgHeight}:
      result = resize(result, width, height)

proc decodeJpg*(
  data: string; width = 0; height = 0
): Image {.inline, raises: [PixieError].} =
  ## Decodes the JPEG data into an Image.
  decodeJpg(cast[seq[uint8]](data), width, height)

proc encodeJpg*(image: Image): string {.raises: [PixieError].} =
  ## Encodes Image into a JPEG data string.
  raise newException(PixieError, "Encoding JPG not supported yet")
