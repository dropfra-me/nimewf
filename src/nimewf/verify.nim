import ./ffi
import ./handle
import ./writer
import ./state
import std/strutils

proc toHex*(bytes: openArray[uint8]): string =
  for b in bytes:
    result.add(toHex(int(b), 2))

type VerifyResult* = object
  ok*: bool
  checksumErrors*: int
  md5*: string
  sha1*: string

proc verify*(path: string, bufSize: int = 1 shl 20): VerifyResult =
  var h = newHandle()
  if h == nil:
    return
  defer:
    discard freeHandle(h)
  if not openForRead(h, path):
    return
  # Read the entire content to exercise the parser
  var buf = newSeq[byte](max(4096, bufSize))
  while true:
    let n = libewf_handle_read_buffer(h, addr buf[0], csize_t(buf.len), addr ewfError)
    if n <= 0: break
  # Corruption and checksum errors
  let corrupt = libewf_handle_segment_files_corrupted(h, addr ewfError)
  var nerr: uint32 = 0
  discard libewf_handle_get_number_of_checksum_errors(h, addr nerr, addr ewfError)
  result.ok = (corrupt == 0)
  result.checksumErrors = int(nerr)
  # Hashes (may be absent)
  var md5buf: array[16, uint8]
  var sha1buf: array[20, uint8]
  if libewf_handle_get_md5_hash(h, addr md5buf[0], md5buf.len.csize_t, addr ewfError) == 1:
    result.md5 = toHex(md5buf)
  if libewf_handle_get_sha1_hash(h, addr sha1buf[0], sha1buf.len.csize_t, addr ewfError) == 1:
    result.sha1 = toHex(sha1buf)

