# test_database

import mdbx
import options
import os
import sugar
import unittest

const TestFile = "/tmp/nimdbx_test"

suite "Database":
    var env: Environment
    var txn: Transaction
    var dbi: Database

    setup:
        #setDebugLevel(TRACE, {ASSERT, AUDIT})
        os.removeDir(TestFile)
        env = newEnvironment(TestFile, {LIFOReclaim}, maxDatabases = 2)
        txn = env.beginTransaction()
        dbi = txn.openDatabase("main", {Create})

    test "Missing":
        check dbi.getString(txn, "key").isNone
        check dbi.getBytes(txn, "key").isNone
        check get(dbi, txn, "key", proc (bytes: openarray[byte]):int = len(bytes)).isNone

    test "Set Key":
        dbi.put(txn, "key", "hello")

        let val = dbi.getString(txn, "key")
        check val.isSome
        check val.get == "hello"
