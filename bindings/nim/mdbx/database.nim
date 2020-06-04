# Database

import mdbx/[errors, kv, transaction, util]
import mdbx/private/mdbx_raw

import options

type
    DatabaseFlag* = enum
        ## Flags for opening/creating a Database.
        xxPlaceholder = 0
        ReverseKey  = bitflag(0x00000002)   ## Keys should be read back-to-front when comparing
        DupSort     = bitflag(0x00000004)   ## Allow duplicate keys
        IntegerKey  = bitflag(0x00000008)   ## Keys are binary integers (4 or 8 bytes)
        DupFixed    = bitflag(0x00000010)   ## With `DupSort`, sorted dup items have fixed size
        IntegerDup  = bitflag(0x00000020)   ## With `DupSort`, keys are binary integers
        ReverseDup  = bitflag(0x00000040)   ## With `DupSort`, use reverse string dups
        Create      = bitflag(0x00040000)   ## Create DB if not already existing
    DatabaseFlags* = set[DatabaseFlag]

    DatabaseObj = object
        handle: MDBX_DBI
    Database* {.package.} = ref DatabaseObj

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

proc mdbx_dbi*(db: Database): MDBX_DBI =
    db.handle

proc sequence*(db: Database, txn: Transaction, increment: uint64 = 0): uint64 =
    checkmdbx sequence(txn.mdbxTxn, db.handle, addr result, increment)

type
    StateFlag* = enum
        Dirty,      ## Has been written to in this transaction
        Stale,      ## Is older than this transaction
        Fresh,      ## Was opened in this transaction
        Created     ## Was created in this transaction
    DatabaseState = set[StateFlag]

proc flagsAndState(db: Database, txn: Transaction): tuple[f:DatabaseFlags, s:DatabaseState] =
    var rawFlags, rawState: cuint
    checkmdbx flags_ex(txn.mdbxTxn, db.handle, addr rawFlags, addr rawState)
    return (cast[DatabaseFlags](rawFlags), cast[DatabaseState](rawState))

proc flags*(db: Database, txn: Transaction): DatabaseFlags = db.flagsAndState(txn).f
proc state*(db: Database, txn: Transaction): DatabaseState = db.flagsAndState(txn).s

# Getting values:

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
    return db.rawGet(txn, key).map( as_string )

proc getBytes*(db: Database, txn: Transaction, key: KeyParam): Option[seq[byte]] =
    ## Reads the value for a key and returns it as a byte sequence, or as `none` if there is no value.
    return db.rawGet(txn, key).map( as_bytes )

# Setting values:

type
    PutFlag* = enum
        xxxPlaceholder = 0
        NoOverwrite = bitflag(0x00000010)
        NoDupData   = bitflag(0x00000020)
        Append      = bitflag(0x00020000)
        AppendDup   = bitflag(0x00040000)
    PutFlags* = set[PutFlag]

proc put*[KEY, VAL](db: Database, txn: Transaction,
                    key: KEY, val: VAL,
                    flags: PutFlags): bool =
    ## Stores a value for a key. Returns true if the value is stored, or false if a constraint
    ## implied by one of the flags was violated.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    let err = put(txn.mdbxTxn, db.handle, addr k, addr v, cast[cuint](flags))
    if (err == cint(KEYEXIST) or err == cint(NOTFOUND) or err == cint(EMULTIVAL)) and flags != {}:
        return false
    else:
        checkmdbx(err)
        return true

proc put*[KEY, VAL](db: Database, txn: Transaction, key: KEY, val: VAL) =
    ## Stores a value for a key, with no constraints (no flags).
    discard put(db, txn, key, val, {})

proc del*(db: Database, txn: Transaction, key: KeyParam): bool =
    ## Removes a key and all its values.
    var k = as_mdbx(key)
    return checkmdbxfound del(txn.mdbxTxn, db.handle, addr k, nil)

proc del*(db: Database, txn: Transaction, key: KeyParam, val: openarray[ByteLike]): bool =
    ## Removes a specific value for a key.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    return checkmdbxfound del(txn.mdbxTxn, db.handle, addr k, addr v)
