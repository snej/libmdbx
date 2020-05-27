#! /bin/bash -e
#
# Generates Nim language binding from mdbx.h
# NOTE: c2nim can be obtained from https://github.com/nim-lang/c2nim
#

SCRIPT_DIR=`dirname $0`
cd "$SCRIPT_DIR"
ROOT_DIR="../../../.."

# Run the bindings generator, producing `tmp.nim`
c2nim -o:tmp.nim mdbx.c2nim "$ROOT_DIR/mdbx.h"

# Postprocess the output to work around some c2nim glitches:
# - Remove duplicate newlines (just for aesthetics)
# - strip the `_t` suffixes from int types like `uint8_t` to make them valid Nim
# - change deprecated `csize` to `csize_t`
# - fix a buggy int literal conversion
cat -s tmp.nim \
    | sed -E -e 's/(u?int[0-9]+)_t/\1/g' \
    | sed -E -e 's/csize/csize_t/g' \
    | sed -E -e "s/0x0000000000000000'i64/0x8000000000000000'u64/" \
    > mdbx_raw.nim
rm tmp.nim

# Test the bindings:
# FIXME: DYLD_LIBRARY_PATH is Mac-only; something else will be needed on other platforms to tell
#        dlsym where to find the library.)
nim c simple_test.nim
DYLD_LIBRARY_PATH=../../ ./simple_test
rm simple_test
rm -r testdb
