# very basic test of MDBX bindings
# The library must be visible to dlsym; e.g. copied into this directory.

import mdbx

type MDBXError = object of CatchableError

proc check(err: cint) =
    if err != 0: raise newException(MDBXError, $strerror(err))


var env : ptr Env
check(create(addr env))
assert env != nil
#echo "Created env!"

check(env.open("testdb", 0, 0o644))
#echo "Opened db!"

check(env.close())
#echo "Closed env!"

echo "√ Nim bindings parse, link, and are minimally functional!"
