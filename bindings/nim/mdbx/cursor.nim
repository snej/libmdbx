# cursor.nim

import mdbx/[database, errors, kv, transaction]
import mdbx/private/mdbx_raw

type
    Cursor* = object
        ## An iterator over the key/value items in a Database.
        ## The iteration order is always according to the key/value sort order of the Database.
        ## A Cursor is always pointing to a specific key/value pair, or else past the end.
        handle: ptr MDBX_Cursor
        key: MDBX_Val
        val: MDBX_Val

proc openCursor(txn: var Transaction, db: Database): Cursor =
    ## Returns a new Cursor that points to the first record in the Database.
    checkmdbx open(txn.mdbxTxn, db.mdbx_dbi, addr result.handle)
    return result

proc close(cursor: var Cursor) =
    ## Closes a Cursor. Not usually needed, because it will be closed when it exits scope.
    if cursor.handle != nil:
        cursor.handle.close()
        cursor.handle = nil
        cursor.key.len = 0
        cursor.val.len = 0

proc `=destroy`(cursor: var Cursor) =
    cursor.close()

proc `=`(dest: var Cursor; source: Cursor) {.error.} # Not copyable!

# Accessors:

proc count*(cursor: var Cursor): csize_t =
    ## Returns the number of values *with the current key*.
    checkmdbx count(cursor.handle, addr result)

proc eof*(cursor: var Cursor): bool =
    ## Returns true if the cursor points past the last item in the Database.
    return checkmdbxbool eof(cursor.handle)

proc onFirst*(cursor: var Cursor): bool =
    ## Returns true if the cursor points to the first item in the Database.
    return checkmdbxbool on_first(cursor.handle)

proc onLast*(cursor: var Cursor): bool =
    ## Returns true if the cursor points to the last item in the Database.
    return checkmdbxbool on_last(cursor.handle)

# Moving:

type MoveOp* = enum
    ## Specifies how the ``move`` method should move the Cursor.
    ## NOTE: The ops with "Dup" or "NoDup" in their names only apply to Databases that support
    ## multiple values for a key, i.e. that were created with the ``DupSort`` flag.
    First     = mdbx_raw.FIRST,      ##  First item in Database
    FirstDup  = mdbx_raw.FIRST_DUP,  ##  First item of current key
    Last      = mdbx_raw.LAST,       ##  Last item in Database
    LastDup   = mdbx_raw.LAST_DUP,   ##  Last item of current key
    Next      = mdbx_raw.NEXT,       ##  Next item
    NextDup   = mdbx_raw.NEXT_DUP,   ##  Next item of current key
    NextNoDup = mdbx_raw.NEXT_NODUP, ##  First item of next key
    Prev      = mdbx_raw.PREV,       ##  Previous item
    PrevDup   = mdbx_raw.PREV_DUP,   ##  Previous item of current key
    PrevNoDup = mdbx_raw.PREV_NODUP, ##  Last item of previous key

proc move*(cursor: var Cursor, op: MoveOp): bool =
    ## Moves the Cursor to the first, last, previous, or next item, according to the given
    ## ``MoveOp``. Returns false if there is no such item.
    return checkmdbxfound get(cursor.handle, addr cursor.key, addr cursor.val, MDBX_CursorOp(op))

proc moveToKey(cursor: var Cursor, key: KeyParam, op: MDBX_CursorOp): bool =
    var k = as_mdbx(key)
    var v: MDBX_Val
    if not checkmdbxfound get(cursor.handle, addr k, addr v, op):
        return false
    cursor.key = k
    cursor.val = v
    return true;

proc moveToKey*(cursor: var Cursor, key: KeyParam): bool =
    ## Moves the Cursor to the first item with that exact key, or returns false if there is none.
    moveToKey(cursor, key, mdbx_raw.SET_KEY)

proc moveToOrAfterKey*(cursor: var Cursor, key: KeyParam): bool =
    ## Moves the Cursor to the first item whose key is *greater than or equal to* the given key,
    ## or returns false if there is none.
    moveToKey(cursor, key, mdbx_raw.SET_RANGE)

# Reading:

proc keyString*(cursor: var Cursor): string = cursor.key.as_string ## The current key as a string.
proc keyBytes*(cursor: var Cursor): seq[byte] = cursor.key.asBytes ## The currsnt key as a byte array.

proc valueString*(cursor: var Cursor): string = cursor.val.as_string ## The current value as a string.
proc valueBytes*(cursor: var Cursor): seq[byte] = cursor.val.asBytes ## The current value as a byte array.

proc with*[T](cursor: var Cursor,
              callback: proc(key, bytes: openarray[byte]):T): T =
    ## Invokes the callback, passing the cursor's current key and value as openarrays.
    ## Returns whatever the callback proc returned.
    return callback( toOpenArrayByte(cast[cstring](cursor.key.base), 0, cast[int](cursor.key.len)),
                     toOpenArrayByte(cast[cstring](cursor.val.base), 0, cast[int](cursor.val.len)) )

# Writing:

type PutMode* = enum
    Insert      = 0x00000    # No constraints; always insert (key, val)
    NoOverwrite = 0x00010    # Key must not already exist
    NoDupData   = 0x00020    # (key, val) pair must not already exist [only use with DupSort]
    Current     = 0x00040    # Replace current item; key must match
    Append      = 0x20000    # Always add at end; key must be greater than last key in Database
    AppendDup   = 0x40000    # Like Append, but for use with DupSort Databases

proc put*[KEY, VAL](cursor: var Cursor,
          key: KEY, val: VAL,
          mode: PutMode): bool =
    ## Stores a value for a key, or returns false if the mode's constraint was violated.
    var k = as_mdbx(key)
    var v = as_mdbx(val)
    let err = put(cursor.handle, addr k, addr v, cast[cuint](flags))
    if err == cint(KEYEXIST) or err == cint(NOTFOUND) or err == cint(EMULTIVAL):
        if mode != Insert:
            return false
    checkmdbx(err)
    cursor.key = k
    cursor.val = v
    return true

proc put*[KEY, VAL](cursor: var Cursor,
          key: KEY, val: VAL) =
    ## Stores a value for a key, with no constraints (``Insert`` mode).
    discard cursor.put(key, val, Insert)

proc del*(cursor: var Cursor): bool =
    ## Removes the current item, or returns false if there is none, i.e. the cursor is at EOF.
    return checkmdbxfound del(cursor.handle, 0)

proc delDups*(cursor: var Cursor): bool =
    ## Removes all items with the current key, or returns false if there are none,
    ## i.e. the cursor is at EOF.
    return checkmdbxfound del(cursor.handle, mdbx_raw.NODUPDATA)
