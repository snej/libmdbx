# test_database

import mdbx
import options
import os
import unittest

const TestFile = "/tmp/nimdbx_test"

suite "Database":
    var env: Environment
    var txn: Transaction
    var dbi: DBI
    var db:  Database

    setup:
        #setDebugLevel(TRACE, {ASSERT, AUDIT})
        os.removeDir(TestFile)
        env = newEnvironment(TestFile, {LIFOReclaim}, maxDatabases = 2)
        txn = env.beginTransaction()
        db = txn.openDatabase("main", {Create})
        dbi = db.id

    test "Missing":
        check db.getString("key").isNone
        check db.getBytes("key").isNone
        check get(db, "key", proc (bytes: openarray[byte]):int = len(bytes)).isNone

    test "Set Key":
        db.put("key", "hello")

        let val = db.getString("key")
        check val.isSome
        check val.get == "hello"

        # Commit txn -- after this, db cannot be used anymore.
        txn.commit

        env.withTransaction do (txn2: var Transaction):
            let val2 = txn2[dbi].getString("key")
            check val2.isSome
            check val2.get == "hello"
