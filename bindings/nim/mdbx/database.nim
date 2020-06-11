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

    DBI* = distinct MDBX_DBI         ## Small handle representing an existing database

    Database* = object
        ## A reference to a database that's open in a Transaction.
        ## Only valid while the Transaction is active.
        txn: ptr MDBX_txn
        dbi: MDBX_DBI

proc `=`(dest: var Database; source: Database) {.error.}  # Database cannot be copied

proc database*(txn: Transaction, dbi: DBI): Database =
    ## Constructs an open Database given a Transaction and a database ID.
    Database(txn: txn.mdbxTxn, dbi: MDBX_DBI(dbi))

proc `[]`*(txn: Transaction, dbi: DBI): Database =
    Database(txn: txn.mdbxTxn, dbi: MDBX_DBI(dbi))

proc openDefaultDatabase*(txn: Transaction, flags: DatabaseFlags): Database =
    ## Opens and returns environment's default (unnamed) database.
    ## (Once you've done this, you can't get any named databases.)
    ## You can get the returned Database's ID and keep it around to access the database in
    ## another Transaction later.
    var dbi: MDBX_DBI
    checkmdbx open(txn.mdbxTxn, nil, cast[cuint](flags), addr dbi)
    return Database(txn: txn.mdbxTxn, dbi: dbi)

proc openDatabase*(txn: Transaction, name: string, flags: DatabaseFlags): Database =
    ## Returns the ID of a named database within the environment.
    ## You must first have passed a nonzero `maxDatabases` parameter to `newEnvironment`.
    ## (Once you've done this, you can't call `getDefaultDatabase`.)
    ## You can get the returned Database's ID and keep it around to access the database in
    ## another Transaction later.
    var dbi: MDBX_DBI
    checkmdbx open(txn.mdbxTxn, name, cast[cuint](flags), addr dbi)
    return Database(txn: txn.mdbxTxn, dbi: dbi)

proc id*(db: Database): DBI = DBI(db.dbi)
    ## A Database's ID. You can reuse this later to access the same Database in a later Transaction.

proc drop*(db: Database) =
    ## Closes and *persistently* deletes a database.
    ## The DBI becomes invalid and cannot be used anymore.
    checkmdbx drop(db.txn, db.dbi, 1)

proc erase*(db: Database) =
    ## Closes a database and removes all its key/value pairs, leaving it empty.
    ## The DBI becomes invalid and cannot be used anymore.
    checkmdbx drop(db.txn, db.dbi, 0)

proc mdbx_dbi*(db: Database): MDBX_DBI =
    db.dbi

proc sequence*(db: Database): uint64 =
    ## Returns the Database's current sequence counter, which is initially zero and can be changed
    ## by calling ``incrementSequence``.
    checkmdbx sequence(db.txn, db.dbi, addr result, 0)

proc incrementSequence*(db: Database, increment: uint64 = 1): uint64 =
    ## Adds ``increment`` to the Database's sequence counter, and returns its **previous** value.
    ## Throws an exception if called in a read-only Transaction.
    ## The updated sequence counter will not be visible outside this Transaction until committed.
    checkmdbx sequence(db.txn, db.dbi, addr result, increment)

type
    StateFlag* = enum
        Dirty,      ## Has been written to in this transaction
        Stale,      ## Is older than this transaction
        Fresh,      ## Was opened in this transaction
        Created     ## Was created in this transaction
    DatabaseState = set[StateFlag]

proc flagsAndState(db: Database): tuple[flags:DatabaseFlags, state:DatabaseState] =
    var rawFlags, rawState: cuint
    checkmdbx flags_ex(db.txn, db.dbi, addr rawFlags, addr rawState)
    return (cast[DatabaseFlags](rawFlags), cast[DatabaseState](rawState))

proc flags*(db: Database): DatabaseFlags = db.flagsAndState.flags
proc state*(db: Database): DatabaseState = db.flagsAndState.state

# Getting values:

proc rawGet(db: Database, key: KeyParam): Option[MDBX_Val] =
    var k = as_mdbx(key)
    var v: MDBX_Val
    if checkmdbxfound get(db.txn, db.dbi, addr k, addr v):
        return some(v)
    else:
        return none[MDBX_Val]()

proc get*[T](db: Database,
             key: KeyParam,
             callback: proc(bytes:openarray[byte]):T): Option[T] =
    ## Reads the value for a key. If the value exists, it will be passed to the callback, and the
    ## callback's value will be returned from this proc as a `some` value.
    ## If no value exists, the callback is _not_ called, and the return value is `none`.
    return db.rawGet(key).map( proc (val: MDBX_Val):T =
        callback( toOpenArrayByte(cast[cstring](val.base), 0, cast[int](val.len)) ) )

proc getString*(db: Database, key: KeyParam): Option[string] =
    ## Reads the value for a key and returns it as a string, or as `none` if there is no value.
    return db.rawGet(key).map( as_string )

proc getBytes*(db: Database, key: KeyParam): Option[seq[byte]] =
    ## Reads the value for a key and returns it as a byte sequence, or as `none` if there is no value.
    return db.rawGet(key).map( as_bytes )

# Setting values:

type
    PutFlag* = enum
        xxxPlaceholder = 0
        NoOverwrite = bitflag(0x00000010)
        NoDupData   = bitflag(0x00000020)
        Append      = bitflag(0x00020000)
        AppendDup   = bitflag(0x00040000)
    PutFlags* = set[PutFlag]

proc put*[KEY, VAL](db: Database,
                    key: KEY, val: VAL,
                    flags: PutFlags): bool =
    ## Stores a value for a key. Returns true if the value is stored, or false if a constraint
    ## implied by one of the flags was violated.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    let err = put(db.txn, db.dbi, addr k, addr v, cast[cuint](flags))
    if (err == cint(KEYEXIST) or err == cint(NOTFOUND) or err == cint(EMULTIVAL)) and flags != {}:
        return false
    else:
        checkmdbx(err)
        return true

proc put*[KEY, VAL](db: Database, key: KEY, val: VAL) =
    ## Stores a value for a key, with no constraints (no flags).
    discard put(db, key, val, {})

proc del*(db: Database, key: KeyParam): bool =
    ## Removes a key and all its values.
    var k = as_mdbx(key)
    return checkmdbxfound del(db.txn, db.dbi, addr k, nil)

proc del*(db: Database, key: KeyParam, val: openarray[ByteLike]): bool =
    ## Removes a specific value for a key.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    return checkmdbxfound del(db.txn, db.dbi, addr k, addr v)
