{$IF CompilerVersion >= 27} // Delphi XE6
  {$DEFINE HAS_SYSTEM_JSON}
{$ENDIF}

{$IF CompilerVersion >= 28} // Delphi XE7
  {$DEFINE HAS_NEW_ARRAY}
  {$DEFINE HAS_NET_ENCODING}
  {$DEFINE HAS_SYSTEM_THREADING}
{$ENDIF}

{$IF CompilerVersion >= 29} // Delphi XE8
  {$DEFINE HAS_NETHTTP_CLIENT}
{$ENDIF}

{$IF CompilerVersion >= 30} // Delphi 10.0 Seattle
  {$DEFINE HAS_HMAC_HASH}
  {$DEFINE HAS_GENERIC_CREATE}
{$ENDIF}

{$IF CompilerVersion >= 31} // Delphi 10.1 Berlin
  {$DEFINE HAS_UTF8CHAR}
  {$DEFINE NO_ARRAY_HELPER_BUG}
{$ENDIF}

{$IF CompilerVersion >= 33} // Delphi 10.3 Rio
  {$DEFINE HAS_NEW_PIDS}
  {$DEFINE HAS_NEW_JSON}
{$ENDIF}

{$IF CompilerVersion >= 34} // Delphi 10.4 Sydney
  {$DEFINE HAS_MRECORDS}
{$ENDIF}

