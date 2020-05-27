# mdbx

import mdbx/[database, environment, errors, transaction]

export database, environment, errors, transaction

import mdbx/private/mdbx_raw

type
    LogLevel* = enum
        FATAL = 0
        ERROR = 1
        WARN = 2
        NOTICE = 3
        VERBOSE = 4
        DEBUG = 5
        TRACE = 6
        EXTRA = 7

    DebugFlag* = enum
        ASSERT = 1
        AUDIT = 2
        JITTER = 4
        DUMP = 8
        LEGACY_MULTIOPEN = 16
        LEGACY_OVERLAP = 32
    DebugFlags* = set[DebugFlag]



proc setDebugLevel*(level: LogLevel, flags: DebugFlags = {}) =
    discard setup_debug(cast[cint](level), cast[cint](flags), LOGGER_DONTCHANGE)
