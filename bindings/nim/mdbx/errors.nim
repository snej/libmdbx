# errors.nim

import mdbx/private/mdbx_raw

## MDBX error code type
type MDBXErrorCode* = distinct cint

proc `==`*(a, b: MDBXErrorCode): bool = (cint(a) == cint(b))

# key/data pair already exists
const KEYEXIST* = MDBXErrorCode(-30799)

# key/data pair not found (EOF)
const NOTFOUND* = MDBXErrorCode(-30798)

# Requested page not found - this usually indicates corruption
const PAGE_NOTFOUND* = MDBXErrorCode(-30797)

# Database is corrupted (page was wrong type and so on)
const CORRUPTED* = MDBXErrorCode(-30796)

# Environment had fatal error (i.e. update of meta page failed and so on)
const PANIC* = MDBXErrorCode(-30795)

# DB file version mismatch with libmdbx
const VERSION_MISMATCH* = MDBXErrorCode(-30794)

# File is not a valid MDBX file
const INVALID* = MDBXErrorCode(-30793)

# Environment mapsize reached
const MAP_FULL* = MDBXErrorCode(-30792)

# Environment maxdbs reached
const DBS_FULL* = MDBXErrorCode(-30791)

# Environment maxreaders reached
const READERS_FULL* = MDBXErrorCode(-30790)

# Transaction has too many dirty pages, i.e transaction too big
const TXN_FULL* = MDBXErrorCode(-30788)

# Cursor stack too deep - this usually indicates corruption,
# i.e branch-pages loop
const CURSOR_FULL* = MDBXErrorCode(-30787)

# Page has not enough space - internal error
const PAGE_FULL* = MDBXErrorCode(-30786)

# Database engine was unable to extend mapping, e.g. since address space
# is unavailable or busy. This can mean:
# - Database size extended by other process beyond to environment mapsize
#   and engine was unable to extend mapping while starting read transaction.
#   Environment should be reopened to continue.
# - Engine was unable to extend mapping during write transaction
#   or explicit call of env_set_geometry().
const UNABLE_EXTEND_MAPSIZE* = MDBXErrorCode(-30785)


# Environment or database is not compatible with the requested operation
# or the specified flags. This can mean:
#  - The operation expects an DUPSORT / DUPFIXED database.
#  - Opening a named DB when the unnamed DB has DUPSORT/INTEGERKEY.
#  - Accessing a data record as a database, or vice versa.
#  - The database was dropped and recreated with different flags.
const INCOMPATIBLE* = MDBXErrorCode(-30784)

# Invalid reuse of reader locktable slot,
# e.g. read-transaction already run for current thread
const BAD_RSLOT* = MDBXErrorCode(-30783)

# Transaction is not valid for requested operation,
# e.g. had errored and be must aborted, has a child, or is invalid
const BAD_TXN* = MDBXErrorCode(-30782)

# Invalid size or alignment of key or data for target database,
# either invalid subDB name
const BAD_VALSIZE* = MDBXErrorCode(-30781)

# The specified DBI-handle is invalid
# or changed by another thread/transaction
const BAD_DBI* = MDBXErrorCode(-30780)

# Unexpected internal error, transaction should be aborted
const PROBLEM* = MDBXErrorCode(-30779)

# Another write transaction is running or environment is already used while
# opening with EXCLUSIVE flag
const BUSY* = MDBXErrorCode(-30778)

# The specified key has more than one associated value
const EMULTIVAL* = MDBXErrorCode(-30421)

# Bad signature of a runtime object(s), this can mean:
#  - memory corruption or double-free;
#  - ABI version mismatch (rare case);
const EBADSIGN* = MDBXErrorCode(-30420)

# Database should be recovered, but this could NOT be done for now
# since it opened in read-only mode
const WANNA_RECOVERY* = MDBXErrorCode(-30419)

# The given key value is mismatched to the current cursor position
const EKEYMISMATCH* = MDBXErrorCode(-30418)

# Database is too large for current system,
# e.g. could NOT be mapped into RAM.
const TOO_LARGE* = MDBXErrorCode(-30417)

# A thread has attempted to use a not owned object,
# e.g. a transaction that started by another thread.
const THREAD_MISMATCH* = MDBXErrorCode(-30416)

# Overlapping read and write transactions for the current thread
const TXN_OVERLAPPING* = MDBXErrorCode(-30415)

# Successful result with special meaning or a flag
const RESULT_TRUE* = MDBXErrorCode(-1)

const SUCCESS* = MDBXErrorCode(0)

const RESULT_FALSE* = SUCCESS


type MDBXError* = object of CatchableError
    ## An MDBX exception.
    code*: MDBXErrorCode

type POSIXError* = object of CatchableError
    ## A POSIX error, thrown by MDBX
    errno*: int

proc raisemdbx(err: cint) =
    if err < 0:
        let x = newException(MDBXError, $strerror(err))
        x.code = MDBXErrorCode(err)
        raise x
    else:
        let x = newException(POSIXError, $strerror(err))
        x.errno = err
        raise x


proc checkmdbx*(err: cint) =
    ## Raises an exception if the error code is nonzero.
    if err != 0: raisemdbx(err)

proc checkmdbxbool*(err: cint): bool =
    ## Returns true/false if the error is RESULT_TRUE/RESULT_FALSE. Else raises exception.
    case err:
        of cint(RESULT_TRUE): return true
        of cint(RESULT_FALSE): return false
        else: raisemdbx(err)

proc checkmdbxfound*(err: cint): bool =
    ## Returns true if err is 0, false if NOTFOUND. Else raises exception.
    case err:
        of cint(SUCCESS): return true
        of cint(NOTFOUND): return false
        else: raisemdbx(err)
