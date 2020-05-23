
{.deadCodeElim: on.}
when defined(windows):
  const
    LibMDBX = "mdbx.dll"
elif defined(macosx):
  const
    LibMDBX = "libmdbx.dylib"
else:
  const
    LibMDBX = "libmdbx.so"

const
  VERSION_MAJOR* = 0
  VERSION_MINOR* = 7

type
  INNER_C_STRUCT_mdbx_703* {.bycopy.} = object
    datetime*: cstring
    tree*: cstring
    commit*: cstring
    describe*: cstring

  VersionInfo* {.bycopy.} = object
    major*: uint8
    minor*: uint8
    release*: uint16
    revision*: uint32
    git*: INNER_C_STRUCT_mdbx_703
    sourcery*: cstring

var Version* {.importc: "mdbx_version", dynlib: LibMDBX.}: VersionInfo

type
  BuildInfo* {.bycopy.} = object
    datetime*: cstring
    target*: cstring
    options*: cstring
    compiler*: cstring
    flags*: cstring

var Build* {.importc: "mdbx_build", dynlib: LibMDBX.}: BuildInfo

type
  Env* {.bycopy.} = object

  Txn* {.bycopy.} = object

  Cursor* {.bycopy.} = object

  Val* {.bycopy.} = object
    base*: pointer
    len*: csize_t

type
  DBI* = uint32

const
  MAX_DBI* = (cast[uint32](32765))

const
  MAXDATASIZE* = 0x8000000000000000'u64

const
  LOG_FATAL* = 0
  LOG_ERROR* = 1
  LOG_WARN* = 2
  LOG_NOTICE* = 3
  LOG_VERBOSE* = 4
  LOG_DEBUG* = 5
  LOG_TRACE* = 6
  LOG_EXTRA* = 7

const
  DBG_ASSERT* = 1

const
  DBG_AUDIT* = 2

const
  DBG_JITTER* = 4

const
  DBG_DUMP* = 8

const
  DBG_LEGACY_MULTIOPEN* = 16

const
  DBG_LEGACY_OVERLAP* = 32

type
  debug_func* = proc (loglevel: cint; function: cstring; line: cint; msg: cstring; args: pointer): void {.cdecl.}

const
  LOG_DONTCHANGE* = (-1)
  DBG_DONTCHANGE* = (-1)

const
  LOGGER_DONTCHANGE* = (cast[ptr debug_func](-1))

proc setup_debug*(loglevel: cint; flags: cint; logger: ptr debug_func): cint {.cdecl, importc: "mdbx_setup_debug", dynlib: LibMDBX.}

type
  assert_func* = proc (env: ptr Env; msg: cstring; function: cstring; line: cuint): void {.cdecl.}

proc set_assert*(env: ptr Env; `func`: ptr assert_func): cint {.cdecl, importc: "mdbx_env_set_assert", dynlib: LibMDBX.}

proc dump_val*(key: ptr Val; buf: cstring; bufsize: csize_t): cstring {.cdecl, importc: "mdbx_dump_val", dynlib: LibMDBX.}

const
  LOCKNAME* = "/mdbx.lck"

const
  DATANAME* = "/mdbx.dat"

const
  LOCK_SUFFIX* = "-lck"

const
  NOSUBDIR* = 0x00004000

const
  RDONLY* = 0x00020000

const
  EXCLUSIVE* = 0x00400000

const
  ACCEDE* = 0x40000000

const
  WRITEMAP* = 0x00080000

const
  NOTLS* = 0x00200000

const
  NORDAHEAD* = 0x00800000

const
  NOMEMINIT* = 0x01000000

const
  COALESCE* = 0x02000000

const
  LIFORECLAIM* = 0x04000000

const
  PAGEPERTURB* = 0x08000000

const
  NOMETASYNC* = 0x00040000

const
  SAFE_NOSYNC* = 0x00010000

const
  MAPASYNC* = 0x00100000

const
  UTTERLY_NOSYNC* = (SAFE_NOSYNC or MAPASYNC)

const
  REVERSEKEY* = 0x00000002

const
  DUPSORT* = 0x00000004

const
  INTEGERKEY* = 0x00000008

const
  DUPFIXED* = 0x00000010

const
  INTEGERDUP* = 0x00000020

const
  REVERSEDUP* = 0x00000040

const
  CREATE* = 0x00040000

const
  NOOVERWRITE* = 0x00000010

const
  NODUPDATA* = 0x00000020

const
  CURRENT* = 0x00000040

const
  RESERVE* = 0x00010000

const
  APPEND* = 0x00020000

const
  APPENDDUP* = 0x00040000

const
  MULTIPLE* = 0x00080000

const
  TRYTXN* = 0x10000000

const
  CP_COMPACT* = 1
  CP_FORCE_RESIZEABLE* = 2

type
  CursorOp* {.size: sizeof(cint).} = enum
    FIRST, FIRST_DUP, GET_BOTH, GET_BOTH_RANGE, GET_CURRENT, GET_MULTIPLE, LAST, LAST_DUP, NEXT, NEXT_DUP, NEXT_MULTIPLE, NEXT_NODUP, PREV, PREV_DUP, PREV_NODUP, SET, SET_KEY, SET_RANGE, PREV_MULTIPLE

const
  SUCCESS* = 0
  RESULT_FALSE* = SUCCESS

const
  RESULT_TRUE* = (-1)

const
  KEYEXIST* = (-30799)

const
  NOTFOUND* = (-30798)

const
  PAGE_NOTFOUND* = (-30797)

const
  CORRUPTED* = (-30796)

const
  PANIC* = (-30795)

const
  VERSION_MISMATCH* = (-30794)

const
  INVALID* = (-30793)

const
  MAP_FULL* = (-30792)

const
  DBS_FULL* = (-30791)

const
  READERS_FULL* = (-30790)

const
  TXN_FULL* = (-30788)

const
  CURSOR_FULL* = (-30787)

const
  PAGE_FULL* = (-30786)

const
  UNABLE_EXTEND_MAPSIZE* = (-30785)

const
  INCOMPATIBLE* = (-30784)

const
  BAD_RSLOT* = (-30783)

const
  BAD_TXN* = (-30782)

const
  BAD_VALSIZE* = (-30781)

const
  BAD_DBI* = (-30780)

const
  PROBLEM* = (-30779)

const
  LAST_LMDB_ERRCODE* = PROBLEM

const
  BUSY* = (-30778)

const
  EMULTIVAL* = (-30421)

const
  EBADSIGN* = (-30420)

const
  WANNA_RECOVERY* = (-30419)

const
  EKEYMISMATCH* = (-30418)

const
  TOO_LARGE* = (-30417)

const
  THREAD_MISMATCH* = (-30416)

const
  TXN_OVERLAPPING* = (-30415)

proc strerror*(errnum: cint): cstring {.cdecl, importc: "mdbx_strerror", dynlib: LibMDBX.}
proc strerror_r*(errnum: cint; buf: cstring; buflen: csize_t): cstring {.cdecl, importc: "mdbx_strerror_r", dynlib: LibMDBX.}

proc create*(penv: ptr ptr Env): cint {.cdecl, importc: "mdbx_env_create", dynlib: LibMDBX.}

proc open*(env: ptr Env; pathname: cstring; flags: cuint; mode: cushort): cint {.cdecl, importc: "mdbx_env_open", dynlib: LibMDBX.}

proc copy*(env: ptr Env; dest: cstring; flags: cuint): cint {.cdecl, importc: "mdbx_env_copy", dynlib: LibMDBX.}

proc copy2fd*(env: ptr Env; fd: cint; flags: cuint): cint {.cdecl, importc: "mdbx_env_copy2fd", dynlib: LibMDBX.}

type
  Stat* {.bycopy.} = object
    psize*: uint32
    depth*: uint32
    branch_pages*: uint64
    leaf_pages*: uint64
    overflow_pages*: uint64
    entries*: uint64
    mod_txnid*: uint64

proc stat_ex*(env: ptr Env; txn: ptr Txn; stat: ptr Stat; bytes: csize_t): cint {.cdecl, importc: "mdbx_env_stat_ex", dynlib: LibMDBX.}
proc stat*(env: ptr Env; stat: ptr Stat; bytes: csize_t): cint {.cdecl, importc: "mdbx_env_stat", dynlib: LibMDBX.}

type
  INNER_C_STRUCT_mdbx_1771* {.bycopy.} = object
    lower*: uint64
    upper*: uint64
    current*: uint64
    shrink*: uint64
    grow*: uint64

  INNER_C_STRUCT_mdbx_1800* {.bycopy.} = object
    l*: uint64
    h*: uint64

  INNER_C_STRUCT_mdbx_1799* {.bycopy.} = object
    current*: INNER_C_STRUCT_mdbx_1800
    meta0*: INNER_C_STRUCT_mdbx_1800
    meta1*: INNER_C_STRUCT_mdbx_1800
    meta2*: INNER_C_STRUCT_mdbx_1800

  Envinfo* {.bycopy.} = object
    geo*: INNER_C_STRUCT_mdbx_1771
    mapsize*: uint64
    last_pgno*: uint64
    recent_txnid*: uint64
    latter_reader_txnid*: uint64
    self_latter_reader_txnid*: uint64
    meta0_txnid*: uint64
    meta0_sign*: uint64
    meta1_txnid*: uint64
    meta1_sign*: uint64
    meta2_txnid*: uint64
    meta2_sign*: uint64
    maxreaders*: uint32
    numreaders*: uint32
    dxb_pagesize*: uint32
    sys_pagesize*: uint32
    bootid*: INNER_C_STRUCT_mdbx_1799
    unsync_volume*: uint64
    autosync_threshold*: uint64
    since_sync_seconds16dot16*: uint32
    autosync_period_seconds16dot16*: uint32
    since_reader_check_seconds16dot16*: uint32
    mode*: uint32

proc info_ex*(env: ptr Env; txn: ptr Txn; info: ptr Envinfo; bytes: csize_t): cint {.cdecl, importc: "mdbx_env_info_ex", dynlib: LibMDBX.}
proc info*(env: ptr Env; info: ptr Envinfo; bytes: csize_t): cint {.cdecl, importc: "mdbx_env_info", dynlib: LibMDBX.}

proc sync_ex*(env: ptr Env; force: cint; nonblock: cint): cint {.cdecl, importc: "mdbx_env_sync_ex", dynlib: LibMDBX.}
proc sync*(env: ptr Env): cint {.cdecl, importc: "mdbx_env_sync", dynlib: LibMDBX.}
proc sync_poll*(env: ptr Env): cint {.cdecl, importc: "mdbx_env_sync_poll", dynlib: LibMDBX.}

proc set_syncbytes*(env: ptr Env; threshold: csize_t): cint {.cdecl, importc: "mdbx_env_set_syncbytes", dynlib: LibMDBX.}

proc set_syncperiod*(env: ptr Env; seconds_16dot16: cuint): cint {.cdecl, importc: "mdbx_env_set_syncperiod", dynlib: LibMDBX.}

proc close_ex*(env: ptr Env; dont_sync: cint): cint {.cdecl, importc: "mdbx_env_close_ex", dynlib: LibMDBX.}
proc close*(env: ptr Env): cint {.cdecl, importc: "mdbx_env_close", dynlib: LibMDBX.}

proc set_flags*(env: ptr Env; flags: cuint; onoff: cint): cint {.cdecl, importc: "mdbx_env_set_flags", dynlib: LibMDBX.}

proc get_flags*(env: ptr Env; flags: ptr cuint): cint {.cdecl, importc: "mdbx_env_get_flags", dynlib: LibMDBX.}

proc get_path*(env: ptr Env; dest: cstringArray): cint {.cdecl, importc: "mdbx_env_get_path", dynlib: LibMDBX.}

proc get_fd*(env: ptr Env; fd: ptr cint): cint {.cdecl, importc: "mdbx_env_get_fd", dynlib: LibMDBX.}

proc set_geometry*(env: ptr Env; size_lower: csize_t; size_now: csize_t; size_upper: csize_t; growth_step: csize_t; shrink_threshold: csize_t; pagesize: csize_t): cint {.cdecl, importc: "mdbx_env_set_geometry", dynlib: LibMDBX.}
proc set_mapsize*(env: ptr Env; size: csize_t): cint {.cdecl, importc: "mdbx_env_set_mapsize", dynlib: LibMDBX.}

proc is_readahead_reasonable*(volume: csize_t; redundancy: csize_t): cint {.cdecl, importc: "mdbx_is_readahead_reasonable", dynlib: LibMDBX.}

const
  MIN_PAGESIZE* = 256

proc pgsize_min*(): csize_t {.inline, cdecl.} =
  return MIN_PAGESIZE

const
  MAX_PAGESIZE* = 65536

proc pgsize_max*(): csize_t {.inline, cdecl.} =
  return MAX_PAGESIZE

proc dbsize_min*(pagesize: csize_t): csize_t {.cdecl, importc: "mdbx_limits_dbsize_min", dynlib: LibMDBX.}

proc dbsize_max*(pagesize: csize_t): csize_t {.cdecl, importc: "mdbx_limits_dbsize_max", dynlib: LibMDBX.}

proc keysize_max*(pagesize: csize_t; flags: cuint): csize_t {.cdecl, importc: "mdbx_limits_keysize_max", dynlib: LibMDBX.}
proc valsize_max*(pagesize: csize_t; flags: cuint): csize_t {.cdecl, importc: "mdbx_limits_valsize_max", dynlib: LibMDBX.}

proc txnsize_max*(pagesize: csize_t): csize_t {.cdecl, importc: "mdbx_limits_txnsize_max", dynlib: LibMDBX.}

proc set_maxreaders*(env: ptr Env; readers: cuint): cint {.cdecl, importc: "mdbx_env_set_maxreaders", dynlib: LibMDBX.}

proc get_maxreaders*(env: ptr Env; readers: ptr cuint): cint {.cdecl, importc: "mdbx_env_get_maxreaders", dynlib: LibMDBX.}

proc set_maxdbs*(env: ptr Env; dbs: DBI): cint {.cdecl, importc: "mdbx_env_set_maxdbs", dynlib: LibMDBX.}

proc get_maxkeysize_ex*(env: ptr Env; flags: cuint): cint {.cdecl, importc: "mdbx_env_get_maxkeysize_ex", dynlib: LibMDBX.}
proc get_maxvalsize_ex*(env: ptr Env; flags: cuint): cint {.cdecl, importc: "mdbx_env_get_maxvalsize_ex", dynlib: LibMDBX.}
proc get_maxkeysize*(env: ptr Env): cint {.cdecl, importc: "mdbx_env_get_maxkeysize", dynlib: LibMDBX.}

proc set_userctx*(env: ptr Env; ctx: pointer): cint {.cdecl, importc: "mdbx_env_set_userctx", dynlib: LibMDBX.}

proc get_userctx*(env: ptr Env): pointer {.cdecl, importc: "mdbx_env_get_userctx", dynlib: LibMDBX.}

proc begin*(env: ptr Env; parent: ptr Txn; flags: cuint; txn: ptr ptr Txn): cint {.cdecl, importc: "mdbx_txn_begin", dynlib: LibMDBX.}

type
  TxnInfo* {.bycopy.} = object
    id*: uint64
    reader_lag*: uint64
    space_used*: uint64
    space_limit_soft*: uint64
    space_limit_hard*: uint64
    space_retired*: uint64
    space_leftover*: uint64
    space_dirty*: uint64

proc info*(txn: ptr Txn; info: ptr TxnInfo; scan_rlt: cint): cint {.cdecl, importc: "mdbx_txn_info", dynlib: LibMDBX.}

proc env*(txn: ptr Txn): ptr Env {.cdecl, importc: "mdbx_txn_env", dynlib: LibMDBX.}

proc flags*(txn: ptr Txn): cint {.cdecl, importc: "mdbx_txn_flags", dynlib: LibMDBX.}

proc id*(txn: ptr Txn): uint64 {.cdecl, importc: "mdbx_txn_id", dynlib: LibMDBX.}

proc commit*(txn: ptr Txn): cint {.cdecl, importc: "mdbx_txn_commit", dynlib: LibMDBX.}

proc abort*(txn: ptr Txn): cint {.cdecl, importc: "mdbx_txn_abort", dynlib: LibMDBX.}

proc reset*(txn: ptr Txn): cint {.cdecl, importc: "mdbx_txn_reset", dynlib: LibMDBX.}

proc renew*(txn: ptr Txn): cint {.cdecl, importc: "mdbx_txn_renew", dynlib: LibMDBX.}

type
  Canary* {.bycopy.} = object
    x*: uint64
    y*: uint64
    z*: uint64
    v*: uint64

proc Canary_put*(txn: ptr Txn; canary: ptr Canary): cint {.cdecl, importc: "mdbx_canary_put", dynlib: LibMDBX.}

proc Canary_get*(txn: ptr Txn; canary: ptr Canary): cint {.cdecl, importc: "mdbx_canary_get", dynlib: LibMDBX.}

type
  cmp_func* = proc (a: ptr Val; b: ptr Val): cint {.cdecl.}

proc open_ex*(txn: ptr Txn; name: cstring; flags: cuint; dbi: ptr DBI; keycmp: ptr cmp_func; datacmp: ptr cmp_func): cint {.cdecl, importc: "mdbx_dbi_open_ex", dynlib: LibMDBX.}
proc open*(txn: ptr Txn; name: cstring; flags: cuint; dbi: ptr DBI): cint {.cdecl, importc: "mdbx_dbi_open", dynlib: LibMDBX.}

proc key_from_jsonInteger*(json_integer: int64): uint64 {.cdecl, importc: "mdbx_key_from_jsonInteger", dynlib: LibMDBX.}
proc key_from_double*(ieee754_64bit: cdouble): uint64 {.cdecl, importc: "mdbx_key_from_double", dynlib: LibMDBX.}
proc key_from_ptrdouble*(ieee754_64bit: ptr cdouble): uint64 {.cdecl, importc: "mdbx_key_from_ptrdouble", dynlib: LibMDBX.}
proc key_from_float*(ieee754_32bit: cfloat): uint32 {.cdecl, importc: "mdbx_key_from_float", dynlib: LibMDBX.}
proc key_from_ptrfloat*(ieee754_32bit: ptr cfloat): uint32 {.cdecl, importc: "mdbx_key_from_ptrfloat", dynlib: LibMDBX.}
proc key_from_int64*(i64: int64): uint64 {.inline, cdecl.} =
  return 0x8000000000000000'u64 + cast[uint64](i64)

proc key_from_int32*(i32: int32): uint32 {.inline, cdecl.} =
  return (cast[uint32](0x80000000)) + cast[uint32](i32)

proc stat*(txn: ptr Txn; dbi: DBI; stat: ptr Stat; bytes: csize_t): cint {.cdecl, importc: "mdbx_dbi_stat", dynlib: LibMDBX.}

const
  TBL_DIRTY* = 0x00000001
  TBL_STALE* = 0x00000002
  TBL_FRESH* = 0x00000004
  TBL_CREAT* = 0x00000008

proc flags_ex*(txn: ptr Txn; dbi: DBI; flags: ptr cuint; state: ptr cuint): cint {.cdecl, importc: "mdbx_dbi_flags_ex", dynlib: LibMDBX.}
proc flags*(txn: ptr Txn; dbi: DBI; flags: ptr cuint): cint {.cdecl, importc: "mdbx_dbi_flags", dynlib: LibMDBX.}

proc close*(env: ptr Env; dbi: DBI): cint {.cdecl, importc: "mdbx_dbi_close", dynlib: LibMDBX.}

proc drop*(txn: ptr Txn; dbi: DBI; del: cint): cint {.cdecl, importc: "mdbx_drop", dynlib: LibMDBX.}

proc get*(txn: ptr Txn; dbi: DBI; key: ptr Val; data: ptr Val): cint {.cdecl, importc: "mdbx_get", dynlib: LibMDBX.}

proc get_ex*(txn: ptr Txn; dbi: DBI; key: ptr Val; data: ptr Val; values_count: ptr csize_t): cint {.cdecl, importc: "mdbx_get_ex", dynlib: LibMDBX.}

proc get_nearest*(txn: ptr Txn; dbi: DBI; key: ptr Val; data: ptr Val): cint {.cdecl, importc: "mdbx_get_nearest", dynlib: LibMDBX.}

proc put*(txn: ptr Txn; dbi: DBI; key: ptr Val; data: ptr Val; flags: cuint): cint {.cdecl, importc: "mdbx_put", dynlib: LibMDBX.}

proc replace*(txn: ptr Txn; dbi: DBI; key: ptr Val; new_data: ptr Val; old_data: ptr Val; flags: cuint): cint {.cdecl, importc: "mdbx_replace", dynlib: LibMDBX.}

proc del*(txn: ptr Txn; dbi: DBI; key: ptr Val; data: ptr Val): cint {.cdecl, importc: "mdbx_del", dynlib: LibMDBX.}

proc open*(txn: ptr Txn; dbi: DBI; cursor: ptr ptr Cursor): cint {.cdecl, importc: "mdbx_cursor_open", dynlib: LibMDBX.}

proc close*(cursor: ptr Cursor) {.cdecl, importc: "mdbx_cursor_close", dynlib: LibMDBX.}

proc renew*(txn: ptr Txn; cursor: ptr Cursor): cint {.cdecl, importc: "mdbx_cursor_renew", dynlib: LibMDBX.}

proc txn*(cursor: ptr Cursor): ptr Txn {.cdecl, importc: "mdbx_cursor_txn", dynlib: LibMDBX.}

proc dbi*(cursor: ptr Cursor): DBI {.cdecl, importc: "mdbx_cursor_dbi", dynlib: LibMDBX.}

proc get*(cursor: ptr Cursor; key: ptr Val; data: ptr Val; op: CursorOp): cint {.cdecl, importc: "mdbx_cursor_get", dynlib: LibMDBX.}

proc put*(cursor: ptr Cursor; key: ptr Val; data: ptr Val; flags: cuint): cint {.cdecl, importc: "mdbx_cursor_put", dynlib: LibMDBX.}

proc del*(cursor: ptr Cursor; flags: cuint): cint {.cdecl, importc: "mdbx_cursor_del", dynlib: LibMDBX.}

proc count*(cursor: ptr Cursor; countp: ptr csize_t): cint {.cdecl, importc: "mdbx_cursor_count", dynlib: LibMDBX.}

proc eof*(mc: ptr Cursor): cint {.cdecl, importc: "mdbx_cursor_eof", dynlib: LibMDBX.}

proc on_first*(mc: ptr Cursor): cint {.cdecl, importc: "mdbx_cursor_on_first", dynlib: LibMDBX.}

proc on_last*(mc: ptr Cursor): cint {.cdecl, importc: "mdbx_cursor_on_last", dynlib: LibMDBX.}

proc estimate_distance*(first: ptr Cursor; last: ptr Cursor; distance_items: ptr clong): cint {.cdecl, importc: "mdbx_estimate_distance", dynlib: LibMDBX.}

proc estimate_move*(cursor: ptr Cursor; key: ptr Val; data: ptr Val; move_op: CursorOp; distance_items: ptr clong): cint {.cdecl, importc: "mdbx_estimate_move", dynlib: LibMDBX.}

const
  EPSILON* = (cast[ptr Val]((-1)))

proc estimate_range*(txn: ptr Txn; dbi: DBI; begin_key: ptr Val; begin_data: ptr Val; end_key: ptr Val; end_data: ptr Val; size_items: ptr clong): cint {.cdecl, importc: "mdbx_estimate_range", dynlib: LibMDBX.}

proc is_dirty*(txn: ptr Txn; `ptr`: pointer): cint {.cdecl, importc: "mdbx_is_dirty", dynlib: LibMDBX.}

proc sequence*(txn: ptr Txn; dbi: DBI; result: ptr uint64; increment: uint64): cint {.cdecl, importc: "mdbx_dbi_sequence", dynlib: LibMDBX.}

proc cmp*(txn: ptr Txn; dbi: DBI; a: ptr Val; b: ptr Val): cint {.cdecl, importc: "mdbx_cmp", dynlib: LibMDBX.}

proc dcmp*(txn: ptr Txn; dbi: DBI; a: ptr Val; b: ptr Val): cint {.cdecl, importc: "mdbx_dcmp", dynlib: LibMDBX.}

type
  reader_list_func* = proc (ctx: pointer; num: cint; slot: cint; pid: cint; thread: pointer; txnid: uint64; lag: uint64; bytes_used: csize_t; bytes_retained: csize_t): cint {.cdecl.}

proc reader_list*(env: ptr Env; `func`: ptr reader_list_func; ctx: pointer): cint {.cdecl, importc: "mdbx_reader_list", dynlib: LibMDBX.}

proc reader_check*(env: ptr Env; dead: ptr cint): cint {.cdecl, importc: "mdbx_reader_check", dynlib: LibMDBX.}

proc straggler*(txn: ptr Txn; percent: ptr cint): cint {.cdecl, importc: "mdbx_txn_straggler", dynlib: LibMDBX.}

type
  oom_func* = proc (env: ptr Env; pid: cint; tid: pointer; txn: uint64; gap: cuint; space: csize_t; retry: cint): cint {.cdecl.}

proc set_oomfunc*(env: ptr Env; oom_func: ptr oom_func): cint {.cdecl, importc: "mdbx_env_set_oomfunc", dynlib: LibMDBX.}

proc get_oomfunc*(env: ptr Env): ptr oom_func {.cdecl, importc: "mdbx_env_get_oomfunc", dynlib: LibMDBX.}

type
  page_type_t* {.size: sizeof(cint).} = enum
    page_void, page_meta, page_large, page_branch, page_leaf, page_dupfixed_leaf, subpage_leaf, subpage_dupfixed_leaf

const
  PGWALK_MAIN* = (cast[cstring](0))
  PGWALK_GC* = (cast[cstring](-1))
  PGWALK_META* = (cast[cstring](-2))

type
  pgvisitor_func* = proc (pgno: uint64; number: cuint; ctx: pointer; deep: cint; dbi: cstring; page_size: csize_t; `type`: page_type_t; nentries: csize_t; payload_bytes: csize_t; header_bytes: csize_t; unused_bytes: csize_t): cint {.cdecl.}

proc pgwalk*(txn: ptr Txn; visitor: ptr pgvisitor_func; ctx: pointer; dont_check_keys_ordering: cint): cint {.cdecl, importc: "mdbx_env_pgwalk", dynlib: LibMDBX.}

