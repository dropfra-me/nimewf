{.push cdecl.}
# Minimal OpenSSL EVP digests (MD5, SHA1, SHA256)

type
  EVP_MD_CTX* = distinct pointer
  EVP_MD* = distinct pointer

proc EVP_MD_CTX_new*(): EVP_MD_CTX {.importc.}
proc EVP_MD_CTX_free*(ctx: EVP_MD_CTX) {.importc.}
proc EVP_sha1*(): EVP_MD {.importc.}
proc EVP_sha256*(): EVP_MD {.importc.}
proc EVP_md5*(): EVP_MD {.importc.}
proc EVP_DigestInit_ex*(ctx: EVP_MD_CTX, md: EVP_MD, engine: pointer): cint {.importc.}
proc EVP_DigestUpdate*(ctx: EVP_MD_CTX, d: pointer, cnt: csize_t): cint {.importc.}
proc EVP_DigestFinal_ex*(ctx: EVP_MD_CTX, md: ptr uint8, s: ptr cuint): cint {.importc.}
{.pop.}

type HashCtx* = object
  md5*: EVP_MD_CTX
  sha1*: EVP_MD_CTX
  sha256*: EVP_MD_CTX

proc init*(hc: var HashCtx) =
  hc.md5 = EVP_MD_CTX_new()
  hc.sha1 = EVP_MD_CTX_new()
  hc.sha256 = EVP_MD_CTX_new()
  discard EVP_DigestInit_ex(hc.md5, EVP_md5(), nil)
  discard EVP_DigestInit_ex(hc.sha1, EVP_sha1(), nil)
  discard EVP_DigestInit_ex(hc.sha256, EVP_sha256(), nil)

proc update*(hc: var HashCtx, data: pointer, len: csize_t) =
  discard EVP_DigestUpdate(hc.md5, data, len)
  discard EVP_DigestUpdate(hc.sha1, data, len)
  discard EVP_DigestUpdate(hc.sha256, data, len)

proc finish*(hc: var HashCtx, md5: var array[16, uint8], sha1: var array[20, uint8], sha256: var array[32, uint8]) =
  var l: cuint
  discard EVP_DigestFinal_ex(hc.md5, addr md5[0], addr l)
  discard EVP_DigestFinal_ex(hc.sha1, addr sha1[0], addr l)
  discard EVP_DigestFinal_ex(hc.sha256, addr sha256[0], addr l)
  EVP_MD_CTX_free(hc.md5)
  EVP_MD_CTX_free(hc.sha1)
  EVP_MD_CTX_free(hc.sha256)

proc toHex*(bytes: openArray[uint8]): string =
  const hexd = "0123456789abcdef"
  result.setLen(bytes.len * 2)
  var j = 0
  for b in bytes:
    result[j] = hexd[int(b shr 4)]
    result[j+1] = hexd[int(b and 0x0F)]
    inc j, 2

proc parseHex*(s: string, outBuf: var openArray[uint8]): bool =
  if s.len != outBuf.len * 2: return false
  for i in 0 ..< outBuf.len:
    let hi = s[i*2]
    let lo = s[i*2+1]
    proc val(c: char): int =
      if c >= '0' and c <= '9': return ord(c) - ord('0')
      let lc = if c >= 'A' and c <= 'F': chr(ord(c) + 32) else: c
      if lc >= 'a' and lc <= 'f': return ord(lc) - ord('a') + 10
      return -1
    let vh = val(hi)
    let vl = val(lo)
    if vh < 0 or vl < 0: return false
    outBuf[i] = uint8((vh shl 4) or vl)
  true

