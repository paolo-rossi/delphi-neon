{$IF CompilerVersion >= 27} // Delphi XE6
  {$DEFINE HAS_SYSTEM_JSON}       // New System.JSON unit
{$ENDIF}

{$IF CompilerVersion >= 28} // Delphi XE7
  {$DEFINE HAS_NEW_ARRAY}         // New dynamic array syntax
  {$DEFINE HAS_NET_ENCODING}      // System.NetEncoding unit introduced
  {$DEFINE HAS_SYSTEM_THREADING}  // System.Threading unit introduced
{$ENDIF}

{$IF CompilerVersion >= 29} // Delphi XE8
  {$DEFINE HAS_NETHTTP_CLIENT}    // New NetHttp native client
  {$DEFINE HAS_SYSTEM_IMAGELIST}  // New unit System.ImageList
{$ENDIF}

{$IF CompilerVersion >= 30} // Delphi 10.0 Seattle
  {$DEFINE HAS_JSON_BOOL}         // TJSONBool class introduced
  {$DEFINE HAS_TOJSON}            // ToJSON method introduced
  {$DEFINE HAS_HMAC_HASH}         // Unit Hashing introduced
  {$DEFINE HAS_GENERIC_CREATE}    // Generic constraint
{$ENDIF}

{$IF CompilerVersion >= 31} // Delphi 10.1 Berlin
  {$DEFINE HAS_UTF8CHAR}          // New UTF8Char type
{$ENDIF}

{$IF CompilerVersion >= 32} // Delphi 10.2 Tokyo
  {$DEFINE HAS_EXTENDED_80}       // New type Extended80
{$ENDIF}

{$IF CompilerVersion >= 33} // Delphi 10.3 Rio
  {$DEFINE HAS_NEW_JSON}          // New JSON parsing options (raise)
  {$DEFINE HAS_VAR_INLINE}        // Declaration of inline variables
{$ENDIF}

{$IF CompilerVersion >= 34} // Delphi 10.4 Sydney
  {$DEFINE HAS_TOJSON_OPTIONS}    // Options in the ToJSON serialization
  {$DEFINE HAS_MRECORDS}          // Managed Records
{$ENDIF}

{$IF CompilerVersion >= 35} // Delphi 11 Alexandria
  {$DEFINE HAS_NO_REF_COUNT}      // TNoRefCountObject class
{$ENDIF}

{$IF CompilerVersion >= 36} // Delphi 12 Athens
  {$DEFINE HAS_JSON_MAPPING}      // JSON Data Mapping
{$ENDIF}

