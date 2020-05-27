# test_environment

import mdbx
import unittest

suite "Environment":
    var env: Environment

    setup:
        env = newEnvironment()

    test "Flags":
        check cast[int](NoSubdir) == 14
        check cast[int]({NoSubdir}) == 0x4000
        check cast[int]({EnvironmentFlag.SafeNoSync}) == 0x00010000
        check cast[int]({EnvironmentFlag.ReadOnly}) == 0x00020000
        check cast[int]({EnvironmentFlag.NoMetaSync}) == 0x00040000

    test "Check":
        env.open("/tmp/nimdbx_test")
