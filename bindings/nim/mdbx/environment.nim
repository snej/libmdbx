# Environment

import mdbx/[errors, util]
import mdbx/private/mdbx_raw

type
    EnvironmentFlag* = enum
        xxPlaceholder = 0
        NoSubdir      = bitflag(0x00004000)
        SafeNoSync    = bitflag(0x00010000)
        ReadOnly      = bitflag(0x00020000)
        NoMetaSync    = bitflag(0x00040000)
        WriteMap      = bitflag(0x00080000)
        MapAsync      = bitflag(0x00100000)
        NoTLS         = bitflag(0x00200000)
        Exclusive     = bitflag(0x00400000)
        NoReadAahead  = bitflag(0x00800000)
        NoMemInit     = bitflag(0x01000000)
        Coalesce      = bitflag(0x02000000)
        LIFOReclaim   = bitflag(0x04000000)
        PagePerturb   = bitflag(0x08000000)
        Accede        = bitflag(0x40000000)
        #UtterlyNoSync = (SafeNoSync | MapAsync)
    EnvironmentFlags* = set[EnvironmentFlag]

    EnvironmentObj = object
        handle: ptr MDBX_env
    Environment* = ref EnvironmentObj

proc `=destroy`(env: var EnvironmentObj) =
    discard close_ex(env.handle, cint(false))

proc newEnvironment*(): Environment =
    ## Creates a new Environment that needs to be opened before it can be used.
    result = Environment(handle: nil)
    checkmdbx create(addr result.handle)

proc open*(env: Environment,
           path: string,
           flags: EnvironmentFlags = {},
           mode: cushort = 0o600) =
    ## Opens an Environment. It must not already be open.
    checkmdbx open(env.handle, path, cast[cuint](flags), mode)

proc newEnvironment*(path: string,
                    flags: EnvironmentFlags = {},
                    mode: cushort = 0o600,
                    maxDatabases = 0): Environment =
    ## Creates and opens a new Environment.
    result = newEnvironment()
    if maxDatabases > 0:
        checkmdbx set_maxdbs(result.handle, MDBX_DBI(maxDatabases))
    result.open(path, flags, mode)

proc flags*(env: Environment): EnvironmentFlags =
    var flags: cuint
    checkmdbx get_flags(env.handle, addr flags)
    return cast[EnvironmentFlags](flags)

proc set_flags*(env: Environment, flags: EnvironmentFlags, on: bool =true) =
    checkmdbx set_flags(env.handle, cast[cuint](flags), cint(on))

proc mdbxEnv*(env: Environment): ptr MDBXEnv = env.handle
