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
    Environment* {.package.} = ref EnvironmentObj

proc `=destroy`(env: var EnvironmentObj) =
    discard close_ex(env.handle, cint(false))

proc newEnvironment*(): Environment =
    ## Creates a new Environment that needs to be opened before it can be used.
    result = Environment(handle: nil)
    checkmdbx create(addr result.handle)
    checkmdbx set_userctx(result.handle, addr result)

proc `maxDatabases=`*(env: Environment, maxDBs: int) =
    ## Sets the maximum number of named databases in the environment.
    ## Only needed if multiple databases will be used in the
    ## environment. Simpler applications that use the environment as a single
    ## unnamed database can ignore this option.
    ## This property may only be set after ``newEnvironment`` and before ``open``.
    checkmdbx set_maxdbs(env.handle, MDBX_DBI(maxDBs))

proc open*(env: Environment,
           path: string,
           flags: EnvironmentFlags = {},
           mode: cushort = 0o600) =
    ## Opens an Environment. It must not already be open.
    checkmdbx open(env.handle, path, cast[cuint](flags), mode)

proc newEnvironment*(path: string;
                     flags: EnvironmentFlags = {};
                     mode: cushort = 0o600;
                     maxDatabases = 0): Environment =
    ## Creates and opens a new Environment.
    result = newEnvironment()
    if maxDatabases > 0:
        result.maxDatabases = maxDatabases
    result.open(path, flags, mode)

proc flags*(env: Environment): EnvironmentFlags =
    var flags: cuint
    checkmdbx get_flags(env.handle, addr flags)
    return cast[EnvironmentFlags](flags)

proc set_flags*(env: Environment, flags: EnvironmentFlags, on: bool =true) =
    checkmdbx set_flags(env.handle, cast[cuint](flags), cint(on))

proc path*(env: Environment): string =
    var rawPath: cstring
    checkmdbx get_path(env.handle, cast[cstringArray](addr rawPath))
    return $rawPath

proc setGeometry(env: Environment,
                 size_lower = -1;
                 size_now = -1;
                 size_upper = -1;
                 growth_step = -1;
                 shrink_threshold = -1;
                 pagesize = -1) =
    ## Sets size-related parameters of an environment, including the page size and the min/max size
    ## of the memory map.
    ## All size parameters default to -1, which means "leave unchanged", so you can just specify
    ## by name the one(s) you want to change.
    checkmdbx set_geometry(env.handle, csize_t(size_lower), csize_t(size_now), csize_t(size_upper),
                           csize_t(growth_step), csize_t(shrink_threshold), csize_t(page_size))

type EnvironmentStats* = MDBX_Stat

proc stats(env: Environment): EnvironmentStats =
    var stat: MDBX_Stat
    checkmdbx stat_ex(env.handle, nil, addr stat, csize_t(sizeof MDBX_Stat))
    return stat

# For internal use -- should not be public:

proc mdbxEnv*(env: Environment): ptr MDBXEnv =
    env.handle

proc fromMdbxEnv*(handle: ptr MDBXEnv): Environment =
    cast[Environment](get_userctx(handle))
