# errors.nim

import mdbx_raw

type MDBXErrorCode = enum
    # key/data pair already exists
    KEYEXIST = -30799

    # key/data pair not found (EOF)
    NOTFOUND = -30798

    # Requested page not found - this usually indicates corruption
    PAGE_NOTFOUND = -30797

    # Database is corrupted (page was wrong type and so on)
    CORRUPTED = -30796

    # Environment had fatal error (i.e. update of meta page failed and so on)
    PANIC = -30795

    # DB file version mismatch with libmdbx
    VERSION_MISMATCH = -30794

    # File is not a valid MDBX file
    INVALID = -30793

    # Environment mapsize reached
    MAP_FULL = -30792

    # Environment maxdbs reached
    DBS_FULL = -30791

    # Environment maxreaders reached
    READERS_FULL = -30790

    # Transaction has too many dirty pages, i.e transaction too big
    TXN_FULL = -30788

    # Cursor stack too deep - this usually indicates corruption,
    # i.e branch-pages loop
    CURSOR_FULL = -30787

    # Page has not enough space - internal error
    PAGE_FULL = -30786

    # Database engine was unable to extend mapping, e.g. since address space
    # is unavailable or busy. This can mean:
    # - Database size extended by other process beyond to environment mapsize
    #   and engine was unable to extend mapping while starting read transaction.
    #   Environment should be reopened to continue.
    # - Engine was unable to extend mapping during write transaction
    #   or explicit call of env_set_geometry().
    UNABLE_EXTEND_MAPSIZE = -30785


    # Environment or database is not compatible with the requested operation
    # or the specified flags. This can mean:
    #  - The operation expects an DUPSORT / DUPFIXED database.
    #  - Opening a named DB when the unnamed DB has DUPSORT/INTEGERKEY.
    #  - Accessing a data record as a database, or vice versa.
    #  - The database was dropped and recreated with different flags.
    INCOMPATIBLE = -30784

    # Invalid reuse of reader locktable slot,
    # e.g. read-transaction already run for current thread
    BAD_RSLOT = -30783

    # Transaction is not valid for requested operation,
    # e.g. had errored and be must aborted, has a child, or is invalid
    BAD_TXN = -30782

    # Invalid size or alignment of key or data for target database,
    # either invalid subDB name
    BAD_VALSIZE = -30781

    # The specified DBI-handle is invalid
    # or changed by another thread/transaction
    BAD_DBI = -30780

    # Unexpected internal error, transaction should be aborted
    PROBLEM = -30779

    # Another write transaction is running or environment is already used while
    # opening with EXCLUSIVE flag
    BUSY = -30778

    # The specified key has more than one associated value
    EMULTIVAL = -30421

    # Bad signature of a runtime object(s), this can mean:
    #  - memory corruption or double-free;
    #  - ABI version mismatch (rare case);
    EBADSIGN = -30420

    # Database should be recovered, but this could NOT be done for now
    # since it opened in read-only mode
    WANNA_RECOVERY = -30419

    # The given key value is mismatched to the current cursor position
    EKEYMISMATCH = -30418

    # Database is too large for current system,
    # e.g. could NOT be mapped into RAM.
    TOO_LARGE = -30417

    # A thread has attempted to use a not owned object,
    # e.g. a transaction that started by another thread.
    THREAD_MISMATCH = -30416

    # Overlapping read and write transactions for the current thread
    TXN_OVERLAPPING = -30415

    # Successful result with special meaning or a flag
    RESULT_TRUE = -1

    SUCCESS = 0



type MDBXError* = object of CatchableError
    code*: MDBXErrorCode

proc checkmdbx*(err: cint) =
    if err != 0: 
        let x = newException(MDBXError, $strerror(err))
        x.code = MDBXErrorCode(err)
        raise x
