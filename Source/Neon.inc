{$IF CompilerVersion >= 27} // Delphi XE6
  {$DEFINE HAS_SYSTEM_JSON}
{$IFEND}

{$IF CompilerVersion >= 28} // Delphi XE7
  {$DEFINE HAS_NEW_ARRAY}
  {$DEFINE HAS_NET_ENCODING}
  {$DEFINE HAS_SYSTEM_THREADING}
{$IFEND}

{$IF CompilerVersion >= 29} // Delphi XE8
  {$DEFINE HAS_NETHTTP_CLIENT}
{$IFEND}

{$IF CompilerVersion >= 30} // Delphi 10.0 Seattle
  {$DEFINE HAS_HMAC_HASH}
  {$DEFINE HAS_GENERIC_CREATE}
{$IFEND}

{$IF CompilerVersion >= 31} // Delphi 10.1 Berlin
  {$DEFINE HAS_UTF8CHAR}
  {$DEFINE NO_ARRAY_HELPER_BUG}
{$IFEND}

{$IF CompilerVersion >= 33} // Delphi 10.3 Rio
  {$DEFINE HAS_NEW_PIDS}
  {$DEFINE HAS_NEW_JSON}
{$IFEND}

