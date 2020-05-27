# Database

import mdbx/[errors, transaction, util]
import mdbx/private/mdbx_raw

import options

type
    DatabaseFlag* = enum
        xxPlaceholder = 0
        ReverseKey  = bitflag(0x00000002)
        DupSort     = bitflag(0x00000004)
        IntegerKey  = bitflag(0x00000008)
        DupFixed    = bitflag(0x00000010)
        IntegerDup  = bitflag(0x00000020)
        ReverseDup  = bitflag(0x00000040)
        Create      = bitflag(0x00040000)
    DatabaseFlags* = set[DatabaseFlag]

    DatabaseObj = object
        handle: MDBX_DBI
    Database* = ref DatabaseObj

    KeyParam* = openarray[byte] | string

    PutFlag* = enum
        xxxPlaceholder = 0
        NoOverwrite = bitflag(0x00000010)
        NoDupData   = bitflag(0x00000020)
        Current     = bitflag(0x00000040)
        Append      = bitflag(0x00020000)
        AppendDup   = bitflag(0x00040000)
    PutFlags* = set[PutFlag]

proc openDefaultDatabase*(txn: Transaction, flags: DatabaseFlags): Database =
    ## Opens the environment's default (unnamed) database.
    ## Once you've done this, you can't open any named databases.
    var handle: MDBX_DBI
    checkmdbx open(txn.mdbxTxn, nil, cast[cuint](flags), addr handle)
    return Database(handle: handle)

proc openDatabase*(txn: Transaction, name: string, flags: DatabaseFlags): Database =
    ## Opens a named database within the environment.
    ## You must first have passed a nonzero `maxDatabases` parameter to `newEnvironment`.
    ## Once you've done this, you can't call `openDefaultDatabase`.
    var handle: MDBX_DBI
    checkmdbx open(txn.mdbxTxn, name, cast[cuint](flags), addr handle)
    return Database(handle: handle)

proc drop*(db: Database, txn: Transaction) =
    ## Closes and deletes a database.
    checkmdbx drop(txn.mdbxTxn, db.handle, 1)
    db.handle = 0  # ?? Is this guaranteed invalid?

proc erase*(db: Database, txn: Transaction) =
    ## Closes a database and removes all its key/value pairs, but not the database itself.
    checkmdbx drop(txn.mdbxTxn, db.handle, 0)
    db.handle = 0  # ?? Is this guaranteed invalid?

# Getting values:

type ByteLike = char | byte | uint8

proc as_mdbx(data: openarray[ByteLike]): MDBX_Val =
    MDBX_Val(base: unsafeAddr data, len: cast[csize_t](len(data)))

proc as_mdbx(str: string): MDBX_Val =
    MDBX_Val(base: unsafeAddr str, len: cast[csize_t](len(str)))

proc rawGet(db: Database, txn: Transaction, key: KeyParam): Option[MDBX_Val] =
    var k = as_mdbx(key)
    var v: MDBX_Val
    if checkmdbxfound get(txn.mdbxTxn, db.handle, addr k, addr v):
        return some(v)
    else:
        return none[MDBX_Val]()

proc get*[T](db: Database,
             txn: Transaction,
             key: KeyParam,
             callback: proc(bytes:openarray[byte]):T): Option[T] =
    ## Reads the value for a key. If the value exists, it will be passed to the callback, and the
    ## callback's value will be returned from this proc as a `some` value.
    ## If no value exists, the callback is _not_ called, and the return value is `none`.
    return db.rawGet(txn, key).map( proc (val: MDBX_Val):T =
        callback( toOpenArrayByte(cast[cstring](val.base), 0, cast[int](val.len)) ) )

proc getString*(db: Database, txn: Transaction, key: KeyParam): Option[string] =
    ## Reads the value for a key and returns it as a string, or as `none` if there is no value.
    return db.rawGet(txn, key).map( proc (val: MDBX_Val):string =
        var str = newString(val.len)
        copyMem(addr str[0], val.base, val.len)
        str)

proc getBytes*(db: Database, txn: Transaction, key: KeyParam): Option[seq[byte]] =
    ## Reads the value for a key and returns it as a byte sequence, or as `none` if there is no value.
    return db.rawGet(txn, key).map( proc (val: MDBX_Val):seq[byte] =
        var bytes = newSeqUninitialized[byte](val.len)
        copyMem(addr bytes, val.base, val.len)
        bytes )

# Setting values:

proc put*(db: Database, txn: Transaction, key: KeyParam, val: openarray[ByteLike], flags: PutFlags = {}) =
    ## Stores a value for a key.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    checkmdbx put(txn.mdbxTxn, db.handle, addr k, addr v, cast[cuint](flags))

proc put*(db: Database, txn: Transaction, key: KeyParam, val: string, flags: PutFlags = {}) =
    put(db, txn, key, cast[seq[char]](val), flags)
