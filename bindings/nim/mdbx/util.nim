# util

#import mdbx/private/mdbx_raw

proc bitflag*(flag: uint64): cuint {.compileTime.} =
    ## Utility for defining enums for sets, when the values are given as masks.
    ## Given a binary flag/mask, returns the position of the bit that is set, starting with 1.
    ## Examples: 1 -> 1, 2 -> 2, 0x100 -> 8, 0x200 -> 9, ...
    assert flag != 0
    var n = flag
    result = 0
    while (n and 1) == 0:
        n = n shr 1
        inc result
    assert n == 1


assert bitflag(1) == 0
assert bitflag(2) == 1
assert bitflag(256) == 8
assert bitflag(0x04000000) == 26
