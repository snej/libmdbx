# Database

import mdbx_raw
import errors
import transaction
import util

type 
    DatabaseFlag* = enum
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

    KeyParam = openarray[byte]
    ValParam = openarray[byte]

    Val = object
        txn: Transaction
        data: openarray[byte]

proc openDatabase*(txn: Transaction, name: string, flags: DatabaseFlags): Database =
    checkmdbx open(txn.mdbxTxn, name, cast[cuint](flags), addr result.handle)

proc drop*(db: Database, txn: Transaction) =
    checkmdbx drop(txn.mdbxTxn, db.handle, 1)
    db.handle = 0  # ?? Is this guaranteed invalid?

proc erase*(db: Database, txn: Transaction) =
    checkmdbx drop(txn.mdbxTxn, db.handle, 0)
    db.handle = 0  # ?? Is this guaranteed invalid?

proc rawGet(db: Database, txn: Transaction, key: KeyParam): MDBX_Val =
    var k = MDBX_Val(base: unsafeAddr key, len: cast[csize_t](len(key)))
    var v: MDBX_Val
    checkmdbx get(txn.mdbxTxn, db.handle, addr k, addr v)
    return v

proc get(db: Database, txn: Transaction, key: KeyParam, callback: proc(bytes:openarray[byte])) =
    let val = db.rawGet(txn, key)
    callback(toOpenArrayByte(cast[cstring](val.base), 0, cast[int](val.len)))

proc getString*(db: Database, txn: Transaction, key: KeyParam): string =
    $(db.rawGet(txn, key))

proc getBytes*(db: Database, txn: Transaction, key: KeyParam): seq[byte] =
    let val = db.rawGet(txn, key)
    var bytes = newSeqUninitialized[byte](val.len)
    copyMem(addr bytes, val.base, val.len)
    return bytes
