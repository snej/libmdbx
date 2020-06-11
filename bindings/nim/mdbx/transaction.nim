# Transaction

import mdbx/[environment, errors, util]
import mdbx/private/mdbx_raw

type
    TransactionFlag* = enum
        xxPlaceholder   = 0
        SafeNoSync      = bitflag(0x00010000)   ## Use this sync mode when committing
        ReadOnly        = bitflag(0x00020000)   ## No writes allowed
        NoMetaSync      = bitflag(0x00040000)   ## Use this sync mode when committing
        MapAsync        = bitflag(0x00100000)   ## Use this sync mode when committing
        TryTransaction  = bitflag(0x10000000)   ## Do not block when starting a write transaction
    TransactionFlags = set[TransactionFlag]

    Transaction* = object
        ## An MDBX transaction. This is a stack-based object, not a ``ref``, so that it will be
        ## be destroyed when the variable goes out of scope; this will abort the transaction if
        ## it hasn't already been committed. It's important that Transaction's not be left
        ## hanging around, since there can only be one write Transaction on an Environment at a
        ## time, and only one read-only Transaction per thread.
        handle: ptr MDBX_txn

    TransactionInfo* = MDBX_txn_info

proc `=destroy`(t: var Transaction) =
    # Normally the commit() or abort() methods will have been called by now.
    # If not, implicitly abort, for instance if an exception is thrown.
    if t.handle != nil:
        discard t.handle.abort()

proc `=`(dest: var Transaction; source: Transaction) {.error.}

proc beginTransaction*(env: Environment,
                       flags: TransactionFlags = {}) :Transaction =
    checkmdbx begin(env.mdbxEnv, nil, cast[cuint](flags), addr result.handle)
    return result

proc beginTransaction*(env: Environment,
                       parent: Transaction,
                       flags: TransactionFlags = {}) :Transaction =
    checkmdbx begin(env.mdbxEnv, parent.handle, cast[cuint](flags), addr result.handle)
    return result

proc commit*(t: var Transaction) =
    let h = t.handle
    if h != nil:
        t.handle = nil
        checkmdbx h.commit()

proc abort*(t: var Transaction) =
    let h = t.handle
    if h != nil:
        t.handle = nil
        checkmdbx h.abort()

# Accessors:

proc flags*(t: Transaction): TransactionFlags =
    cast[TransactionFlags](flags(t.handle))

proc isReadOnly(t: Transaction): bool = t.flags.contains(ReadOnly)

proc environment*(t: Transaction): Environment =
    ## The Environment of this Transaction
    env(t.handle).fromMdbxEnv()

proc info*(t: Transaction, full: bool = false): TransactionInfo =
    ## Returns information about the Transaction.
    ## For performance reasons, some values is not computed unless the ``full`` parameter is true:
    ## * ``txn_reader_lag`` (in a write transaction)
    ## * ``txn_space_dirty`` (in a read-only transaction)
    checkmdbx info(t.handle, addr result, full)

# Utilities:

proc withTransaction*(env: Environment,
                      flags: TransactionFlags,
                      body: proc(t:var Transaction)) =
    ## Convenience to run a transaction in a block and commit when the block exits.
    ## The transaction is aborted if the block throws an exception or calls ``abort`` explicitly.
    ## Use it like this:
    ## ``env.withTransaction({ReadOnly}) do (txn: var Transaction):``
    var txn = beginTransaction(env, flags)
    try:
        body(txn)
    except:
        txn.abort()
        raise
    txn.commit()

proc withTransaction*(env: Environment,
                         body: proc(t:var Transaction)) =
    ## Convenience to run a transaction in a block and commit when the block exits.
    ## The transaction is aborted if the block throws an exception or calls ``abort`` explicitly.
    ## Use it like this:
    ## ``env.withTransaction do (txn: var Transaction):``
    withTransaction(env, {}, body)

proc mdbxTxn*(t: Transaction): ptr MDBX_txn = t.handle

#TODO: An abstraction around reset/renew
