# kv.nim

import mdbx/private/mdbx_raw

type
    KeyParam* = openarray[byte] | string
    ByteLike* = char | byte | uint8

    RawKV* = tuple[key: MDBX_Val, val: MDBX_Val]

proc as_mdbx*(data: openarray[ByteLike]): MDBX_Val =
    MDBX_Val(base: unsafeAddr data[0], len: cast[csize_t](len(data)))

proc as_mdbx*(str: string): MDBX_Val =
    MDBX_Val(base: unsafeAddr str[0], len: cast[csize_t](len(str)))

proc as_string*(val: MDBX_Val): string =
    ## MDBX_Val -> string conversion. Does not check for valid UTF-8.
    var str = newString(val.len)
    copyMem(addr str[0], val.base, val.len)
    return str

proc as_bytes*(val: MDBX_Val): seq[byte] =
    var bytes = newSeqUninitialized[byte](val.len)
    copyMem(addr bytes, val.base, val.len)
    return bytes
