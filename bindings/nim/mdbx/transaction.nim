# Transaction

import mdbx/[environment, errors, util]
import mdbx/private/mdbx_raw

type
    TransactionFlag* = enum
        xxPlaceholder   = 0
        SafeNoSync      = bitflag(0x00010000)
        ReadOnly        = bitflag(0x00020000)
        NoMetaSync      = bitflag(0x00040000)
        MapAsync        = bitflag(0x00100000)
        TryTransaction  = bitflag(0x10000000)
    TransactionFlags = set[TransactionFlag]

    Transaction* = object
        handle: ptr MDBX_txn

proc `=destroy`(t: var Transaction) =
    # Normally the commit() or abort() methods will have been called by now.
    # If not, implicitly abort, for instance if an exception is thrown.
    if t.handle != nil:
        checkmdbx t.handle.abort()

proc beginTransaction*(env: Environment,
                       flags: TransactionFlags = {}) :Transaction =
    checkmdbx begin(env.mdbxEnv, nil, cast[cuint](flags), addr result.handle)

proc beginTransaction*(env: Environment,
                       parent: Transaction,
                       flags: TransactionFlags = {}) :Transaction =
    checkmdbx begin(env.mdbxEnv, parent.handle, cast[cuint](flags), addr result.handle)

proc flags*(t: Transaction): TransactionFlags =
    cast[TransactionFlags](flags(t.handle))

proc commit*(t: var Transaction) =
    checkmdbx t.handle.commit()
    t.handle = nil

proc abort*(t: var Transaction) =
    checkmdbx t.handle.abort()
    t.handle = nil

proc mdbxTxn*(t: Transaction): ptr MDBX_txn = t.handle

#TODO: An abstraction around reset/renew
