{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Persistence.JSON;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.Generics.Defaults,
  System.JSON,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.DynamicTypes,
  Neon.Core.Utils;

type
  /// <summary>
  ///   JSON Serializer class
  /// </summary>
  TNeonSerializerJSON = class(TNeonBase, ISerializerContext)
  private
    /// <summary>
    ///   Writer for members of objects and records
    /// </summary>
    procedure WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
  private
    /// <summary>
    ///   Writer for string types
    /// </summary>
    /// <remarks>
    ///   Under [NeonRawValue] the string is JSON text spliced into the document
    ///   instead of a value to quote, so it has to parse: see the attribute for
    ///   the contract that puts on both directions
    /// </remarks>
    function WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Char types
    /// </summary>
    function WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Boolean types
    /// </summary>
    function WriteBoolean(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for enums types <br />
    /// </summary>
    function WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Int64 types <br />
    /// </summary>
    /// <remarks>
    ///   Delphi does not manage correctly UInt64 values in TJSONNumber
    /// </remarks>
    function WriteInt64(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for float types
    /// </summary>
    function WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TDate types
    /// </summary>
    function WriteDate(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TTime types
    /// </summary>
    function WriteTime(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TDateTime types
    /// </summary>
    function WriteDateTime(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for the date carried by a varDate variant
    /// </summary>
    /// <remarks>
    ///   A varDate holds a full TDateTime, so it is written as a plain date only
    ///   when there is no time to lose
    /// </remarks>
    function WriteVariantDate(const AValue: TDateTime; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine serialize the fields by default
    /// </remarks>
    function WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject; AList: IDynamicList): TJSONValue;
    function IsEnumerable(const AValue: TValue; out AList: IDynamicList): Boolean;

    /// <summary>
    ///   Writer for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    /// <remarks>
    ///   A JSON name is always a string, so the key type must have an
    ///   unambiguous text form: strings and chars, integers and floats,
    ///   booleans and enums, anything with a custom serializer that writes a
    ///   scalar, and classes exposing both ToString and FromString. Every other
    ///   key type raises SNeonErrorDictKeyInvalid, in both directions
    /// </remarks>
    function WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject; AMap: IDynamicMap): TJSONValue;
    function IsEnumerableMap(const AValue: TValue; out AMap: IDynamicMap): Boolean;

    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject; AStream: IDynamicStream): TJSONValue;
    function IsStreamable(const AValue: TValue; out AStream: IDynamicStream): Boolean;

    /// <summary>
    ///   Writer for "Nullable" records
    /// </summary>
    /// <remarks>
    ///   Record must have HasValue and GetValue methods
    /// </remarks>
    function WriteNullable(const AValue: TValue; ANeonObject: TNeonRttiObject; ANullable: IDynamicNullable): TJSONValue;
    function IsNullable(const AValue: TValue; out ANullable: IDynamicNullable): Boolean;
  protected
    /// <summary>
    ///   Function to be called by a custom serializer method (ISerializeContext)
    /// </summary>
    function WriteDataMember(const AValue: TValue; ACustomProcess: Boolean = True): TJSONValue; overload;

    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(const AValue: TValue; ACustomProcess: Boolean; ANeonObject: TNeonRttiObject): TJSONValue; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TValue
    /// </summary>
    function ValueToJSON(const AValue: TValue): TJSONValue;

    /// <summary>
    ///   Serialize any Delphi objects into a JSONValue
    /// </summary>
    function ObjectToJSON(AObject: TObject): TJSONValue;
  end;

  TNeonDeserializerParam = record
    JSONValue: TJSONValue;
    RttiType: TRttiType;
    NeonObject: TNeonRttiObject;
    procedure Default;
  end;

  /// <summary>
  ///   JSON Deserializer class
  /// </summary>
  TNeonDeserializerJSON = class(TNeonBase, IDeserializerContext)
  private
    /// <summary>
    ///   Reader for members of objects and records
    /// </summary>
    procedure ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);

    /// <summary>
    ///   Decides to whether or not to create the object and assigning it to the reference
    /// </summary>
    function ReadReference(var AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Decides to whether or not to create the object and assigning it to the reference
    /// </summary>
    function ManageInstance(var AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Manages the creation of an Item of a collection (array, list, dictionary)
    /// </summary>
    function CreateItem(ANeonRtti: TNeonRttiObject; AValue: TJSONValue; var AType: TRttiType): TValue;

    /// <summary>
    ///   Builds the object that implements an interface member through its
    ///   [NeonFactory], and returns it as a value of the interface type
    /// </summary>
    /// <remarks>
    ///   Returns an empty value (and AObject nil) when the member has no
    ///   factory - the one case that is logged and skipped instead of raising,
    ///   since it means the member was simply not configured for reading
    /// </remarks>
    function CreateInterface(const AParam: TNeonDeserializerParam; out AObject: TObject): TValue;
  private
    /// <summary>
    ///   reader for string types
    /// </summary>
    /// <remarks>
    ///   Under [NeonRawValue] the member is given the JSON text of the value,
    ///   which is what the writer expects back: a scalar therefore arrives
    ///   JSON-encoded ("abc", quotes included). See the attribute
    /// </remarks>
    function ReadString(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Writer for char types
    /// </summary>
    function ReadChar(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Writer for enum types
    /// </summary>
    function ReadEnum(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Writer for integer type
    /// </summary>
    function ReadInteger(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Writer for Int64 type
    /// </summary>
    function ReadInt64(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Writer for float types
    /// </summary>
    function ReadFloat(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Reader for set types
    /// </summary>
    /// <remarks>
    ///   The input is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function ReadSet(const AParam: TNeonDeserializerParam): TValue;

    /// <summary>
    ///   Reader for Variant types
    /// </summary>
    function ReadVariant(const AParam: TNeonDeserializerParam): TValue;
  private
    /// <summary>
    ///   Reader for static and dynamic arrays
    /// </summary>
    function ReadArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Reader for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function ReadObject(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Reader for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object behind the interface is read, the same object
    ///   WriteInterface writes: an interface that already points at one is
    ///   filled in place, otherwise the member's [NeonFactory] builds it (see
    ///   CreateInterface). Interfaces without a GUID cannot be built
    /// </remarks>
    function ReadInterface(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Reader for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine deserialize to fields by default
    /// </remarks>
    function ReadRecord(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Reader for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function ReadStreamable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function ReadEnumerable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;

    /// <summary>
    ///   Reader for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    /// <remarks>
    ///   See WriteEnumerableMap for the key types a map supports: this reader
    ///   refuses the same ones with the same error
    /// </remarks>
    function ReadEnumerableMap(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;

    /// <summary>
    ///   Reader for a JSON null: an explicit "no value" for the target type
    /// </summary>
    /// <remarks>
    ///   Simple types go back to their default, a Nullable loses its value, and
    ///   an object or interface reference is left alone: Neon does not own what
    ///   a member points to, so clearing the reference here would leak it
    /// </remarks>
    function ReadNull(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

    /// <summary>
    ///   Tells whether a map key of this type can be read back from a JSON name
    /// </summary>
    function IsSupportedMapKeyType(AType: TRttiType; AMap: IDynamicMap): Boolean;

    /// <summary>
    ///   Builds the JSON value a key reader expects from the (always string)
    ///   name of a JSON pair. Returns nil when the name itself is what the
    ///   reader wants, and a value the caller must free otherwise
    /// </summary>
    function MapKeyToJSON(AType: TRttiType; const AName: string): TJSONValue;

    /// <summary>
    ///   Reader for "Nullable" records
    /// </summary>
    /// <remarks>
    ///   Record must have HasValue and GetValue methods
    /// </remarks>
    function ReadNullable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
  private
    /// <summary>
    ///   Function to be called by a custom serializer method (IDeserializeContext)
    /// </summary>
    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue; ACustomProcess: Boolean = True): TValue; overload;

    /// <summary>
    ///   This method chooses the right Reader
    /// </summary>
    function ReadDataMember(var AParam: TNeonDeserializerParam; const AData: TValue; ACustomProcess: Boolean): TValue; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Deserialize a JSON value into a Delphi object
    /// </summary>
    procedure JSONToObject(AObject: TObject; AJSON: TJSONValue);

    /// <summary>
    ///   Deserialize a JSON value into any Delphi type
    /// </summary>
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue; overload;

    /// <summary>
    ///   Deserialize a JSON value into any Delphi type
    /// </summary>
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue; overload;

    /// <summary>
    ///   Deserialize a JSON array into any Delphi type
    /// </summary>
    function JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
  end;

  /// <summary>
  ///   Static utility class for serializing and deserializing Delphi types
  /// </summary>
  TNeon = class sealed
  {$IFDEF HAS_TOJSON_OPTIONS}
  private const
    OUTPUT_DEFAULT = [TJSONAncestor.TJSONOutputOption.EncodeBelow32, TJSONAncestor.TJSONOutputOption.EncodeAbove127];
  {$ENDIF}
  private
    /// <summary>
    ///   ParseJSON function call for compatibility Delphi <= 10.2 Tokyo
    /// </summary>
    class function ParseJSON(const Data: string; UseBool: Boolean = False; RaiseExc: Boolean = False): TJSONValue;

    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class procedure PrintToWriter(AJSONValue: TJSONValue; AWriter: TTextWriter; APretty: Boolean
      {$IFDEF HAS_TOJSON_OPTIONS}; AOutputOptions: TJSONAncestor.TJSONOutputOptions{$ENDIF}); static;
  public
    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class function Print(AJSONValue: TJSONValue; APretty: Boolean): string; overload; static;
    {$IFDEF HAS_TOJSON_OPTIONS}
    class function Print(AJSONValue: TJSONValue; APretty: Boolean; AOutputOptions: TJSONAncestor.TJSONOutputOptions): string; overload; static;
    {$ENDIF}

    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class procedure PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean); overload; static;
    {$IFDEF HAS_TOJSON_OPTIONS}
    class procedure PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean; AOutputOptions: TJSONAncestor.TJSONOutputOptions); overload; static;
    {$ENDIF}
  public
    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TStream
    /// </summary>
    class procedure ValueToStream(const AValue: TValue; AStream: TStream); overload;

    /// <summary>
    ///   Serializes a value based type to a TStream with a given configuration
    /// </summary>
    class procedure ValueToStream(const AValue: TValue; AStream: TStream; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Serializes a value based type to a TJSONValue with a default configuration
    /// </summary>
    class function ValueToJSON(const AValue: TValue): TJSONValue; overload;

    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TJSONValue
    ///   with a given configuration
    /// </summary>
    class function ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes a value based type to a string with a default configuration <br />
    /// </summary>
    class function ValueToJSONString(const AValue: TValue): string; overload;

    /// <summary>
    ///   Serializes a vallue based type to a string with a given configuration <br />
    /// </summary>
    class function ValueToJSONString(const AValue: TValue; AConfig: INeonConfiguration): string; overload;
  public
    /// <summary>
    ///   Serializes an object based type into a TTStream with a default configuration
    /// </summary>
    class procedure ObjectToStream(AObject: TObject; AStream: TStream); overload;

    /// <summary>
    ///   Serializes an object based type into a TTStream with a given configuration
    /// </summary>
    class procedure ObjectToStream(AObject: TObject; AStream: TStream; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a default configuration
    /// </summary>
    class function ObjectToJSON(AObject: TObject): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a given configuration <br />
    /// </summary>
    class function ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a default configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject): string; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a given configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Deserializes a string into a TObject with a default configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; const AJSON: string); overload;

    /// <summary>
    ///   Deserializes a string into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a default configuration
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a given configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a default configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a given configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string; AConfig: INeonConfiguration): T; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a default configuration <br />
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a given configuration
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a default configuration
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a given configuration <br />
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; (value based) with a default configuration <br />
    /// </summary>
    class function JSONToValue<T>(const AJSON: string): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; (value based) with a given configuration <br />
    /// </summary>
    class function JSONToValue<T>(const AJSON: string; const AConfig: INeonConfiguration): T; overload;
  end;

implementation

uses
  System.Math,
  System.Diagnostics,
  System.DateUtils,
  System.Variants;

{ TNeonSerializerJSON }

constructor TNeonSerializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
end;

function TNeonSerializerJSON.IsEnumerable(const AValue: TValue; out AList: IDynamicList): Boolean;
begin
  AList := TDynamicList.GuessType(AValue.AsObject);
  Result := Assigned(AList);
end;

function TNeonSerializerJSON.IsEnumerableMap(const AValue: TValue; out AMap: IDynamicMap): Boolean;
begin
  AMap := TDynamicMap.GuessType(AValue.AsObject);
  Result := Assigned(AMap);
end;

function TNeonSerializerJSON.IsNullable(const AValue: TValue; out ANullable: IDynamicNullable): Boolean;
begin
  ANullable := TDynamicNullable.GuessType(AValue);
  Result := Assigned(ANullable);
end;

function TNeonSerializerJSON.IsStreamable(const AValue: TValue; out AStream: IDynamicStream): Boolean;
begin
  AStream := TDynamicStream.GuessType(AValue.AsObject);
  Result := Assigned(AStream);
end;

function TNeonSerializerJSON.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  FOriginalInstance := AObject;
  if not Assigned(AObject) then
    Exit(TJSONObject.Create);

  Result := WriteDataMember(AObject);
end;

function TNeonSerializerJSON.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  FOriginalInstance := AValue;

  Result := WriteDataMember(AValue);
end;

function TNeonSerializerJSON.WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LIndex, LCount: Integer;
  LArray: TJSONArray;
  LJSONValue: TJSONValue;
begin
  LCount := AValue.GetArrayLength;
  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LCount = 0 then
      Exit(nil);

  LArray := TJSONArray.Create;
  for LIndex := 0 to LCount - 1 do
  begin
    LJSONValue := WriteDataMember(AValue.GetArrayElement(LIndex));
    // A nil element (e.g. a nil object under IncludeIf.NotNull) must become
    // JSON null: adding a nil TJSONValue corrupts the array (and raises on
    // newer RTLs), and skipping it would shift every following index
    if not Assigned(LJSONValue) then
      LJSONValue := TJSONNull.Create;
    LArray.AddElement(LJSONValue);
  end;

  Result := LArray;
end;

function TNeonSerializerJSON.WriteBoolean(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  Result := TJSONUtils.GetJSONBool(AValue);
end;

function TNeonSerializerJSON.WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LStr: string;
begin
  LStr := AValue.AsString;
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if (LStr = #0) or LStr.IsEmpty then
        Exit(nil);
    end;
  end;

  if (LStr = #0) or LStr.IsEmpty then
    Result := TJSONString.Create('')
  else
    Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue; ACustomProcess: Boolean): TJSONValue;
var
  LNeonObject: TNeonRttiObject;
  LStamp: Int64;
begin
  // This overload is called per-element for arrays/lists/map keys+values, so it
  // takes the RTTI type and its parsed attributes from the per-type cache: only
  // the first element of a given type pays for resolving them, and the cached
  // object is owned by the registry, not by this call
  LStamp := TNeonLogger.ProfileBegin;
  LNeonObject := GetNeonObject(AValue.TypeInfo);
  TNeonLogger.ProfileEnd('Serialize:RttiResolve', LStamp);

  Result := WriteDataMember(AValue, ACustomProcess, LNeonObject);
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue; ACustomProcess: Boolean; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LCustomSer: TCustomSerializer;
  LDynamicType: IDynamicType;

  LDynamicMap: IDynamicMap absolute LDynamicType;
  LDynamicList: IDynamicList absolute LDynamicType;
  LDynamicStream: IDynamicStream absolute LDynamicType;
  LDynamicNullable: IDynamicNullable absolute LDynamicType;
begin
  Result := nil;

  if ACustomProcess then
  begin
    LCustomSer := FConfig.Serializers.GetSerializer(AValue.TypeInfo);
    if Assigned(LCustomSer) then
    begin
      // A nil object is governed by the member's IncludeIf semantics and must
      // never reach a custom serializer, which would dereference it
      // The tkClass branch below applies the same rules for values that have no custom serializer
      if (AValue.Kind = tkClass) and (AValue.AsObject = nil) then
      begin
        case ANeonObject.NeonInclude.Value of
          IncludeIf.Always, IncludeIf.CustomFunction:
            Exit(TJSONNull.Create);
        else
          Exit(nil);
        end;
      end;

      Result := LCustomSer.Serialize(AValue, ANeonObject, Self);
      Exit(Result);
    end;
  end;

  case AValue.Kind of
    tkChar,
    tkWChar:
    begin
      Result := WriteChar(AValue, ANeonObject);
    end;

    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AValue, ANeonObject);
    end;

    tkEnumeration:
    begin
      if AValue.TypeInfo = System.TypeInfo(Boolean) then
        Result := WriteBoolean(AValue, ANeonObject)
      else
        Result := WriteEnum(AValue, ANeonObject);
    end;

    tkInteger:
    begin
      Result := WriteInteger(AValue, ANeonObject);
    end;

    tkInt64:
    begin
      Result := WriteInt64(AValue, ANeonObject);
    end;

    tkFloat:
    begin
      if AValue.TypeInfo = System.TypeInfo(TDate) then
        Result := WriteDate(AValue, ANeonObject)
      else if AValue.TypeInfo = System.TypeInfo(TTime) then
        Result := WriteTime(AValue, ANeonObject)
      else if AValue.TypeInfo = System.TypeInfo(TDateTime) then
        Result := WriteDateTime(AValue, ANeonObject)
      else
        Result := WriteFloat(AValue, ANeonObject);
    end;

    tkClass:
    begin
      if AValue.AsObject = nil then
      begin
        case ANeonObject.NeonInclude.Value of
          IncludeIf.Always, IncludeIf.CustomFunction:
          Exit(TJSONNull.Create);
        else
          Exit(nil);
        end;
      end
      else
        // Which shape this class has is settled once per class, so only the
        // probe that can match still runs here - the other two used to run,
        // and fail, for every value
        case GetDynamicKind(AValue.AsObject) of
          TNeonDynamicKind.Map:
            if IsEnumerableMap(AValue, LDynamicMap) then
              Result := WriteEnumerableMap(AValue, ANeonObject, LDynamicMap);

          TNeonDynamicKind.List:
            if IsEnumerable(AValue, LDynamicList) then
              Result := WriteEnumerable(AValue, ANeonObject, LDynamicList);

          TNeonDynamicKind.Stream:
            if IsStreamable(AValue, LDynamicStream) then
              Result := WriteStreamable(AValue, ANeonObject, LDynamicStream);
        else
          Result := WriteObject(AValue, ANeonObject);
        end;
    end;

    tkArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkDynArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkSet:
    begin
      Result := WriteSet(AValue, ANeonObject);
    end;

    tkRecord{$IFDEF HAS_MRECORDS}, tkMRecord{$ENDIF}:
    begin
      if IsNullable(AValue, LDynamicNullable) then
        Result := WriteNullable(AValue, ANeonObject, LDynamicNullable)
      else
        Result := WriteRecord(AValue, ANeonObject);
    end;

    tkInterface:
    begin
      Result := WriteInterface(AValue, ANeonObject);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AValue, ANeonObject);
    end;

    {
    tkUnknown,
    tkMethod,
    tkPointer,
    tkProcedure,
    tkClassRef:
    }
  end;
end;

function TNeonSerializerJSON.WriteDate(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;
  Result := TJSONString.Create(TJSONUtils.DateToJSON(AValue.AsType<TDate>));
end;

function TNeonSerializerJSON.WriteTime(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;
  Result := TJSONString.Create(TJSONUtils.TimeToJSON(AValue.AsType<TTime>));
end;

function TNeonSerializerJSON.WriteDateTime(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;
  Result := TJSONString.Create(TJSONUtils.DateTimeToJSON(AValue.AsType<TDateTime>, FConfig.UseUTCDate));
end;

function TNeonSerializerJSON.WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LName: string;
begin
  if FConfig.EnumAsInt then
  begin
    Result := TJSONNumber.Create(AValue.AsOrdinal);
  end
  else
  begin
    // The enum's JSON name follows the configured member case the way a
    // member's name does: (Admin, Guest) is written "admin"/"guest" under
    // LowerCase or CamelCase, and a multi-word member splits under SnakeCase.
    // An explicit [NeonEnumNames] name wins over the case and is used verbatim
    LName := TTypeInfoUtils.EnumToJSONName(AValue.TypeInfo, AValue.AsOrdinal,
      FConfig.MemberCase, FConfig.MemberCustomCase);
    Result := TJSONString.Create(LName);
  end;
end;

function TNeonSerializerJSON.WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;

  Result := TJSONNumber.Create(AValue.AsExtended);
end;

function TNeonSerializerJSON.WriteInt64(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LUIntStr: string;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotDefault:
    begin
      if AValue.AsInt64 = 0 then
        Exit(nil);
    end;
  end;

  if AValue.TypeData^.MinInt64Value < 0 then
    Result := TJSONNumber.Create(AValue.AsInt64)
  else
  begin
    // Tries to workaround the Delphi bug on JSONNumber + UInt64
    LUIntStr := UIntToStr(AValue.AsUInt64);
    Result := TJSONNumber.Create(LUIntStr);
  end;
end;

function TNeonSerializerJSON.WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotDefault:
    begin
      if AValue.AsInt64 = 0 then
        Exit(nil);
    end;
  end;

  Result := TJSONNumber.Create(AValue.AsInt64);
end;

function TNeonSerializerJSON.WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LInterface: IInterface;
  LObject: TObject;
begin
  LInterface := AValue.AsInterface;
  LObject := LInterface as TObject;

  // A member holding no interface follows the same IncludeIf rules as a nil
  // object member: omitted by default, an explicit null under Always
  if not Assigned(LObject) then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.Always, IncludeIf.CustomFunction:
        Exit(TJSONNull.Create);
    else
      Exit(nil);
    end;
  end;

  Result := WriteObject(LObject, ANeonObject);
end;

procedure TNeonSerializerJSON.WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
var
  LPairName: string;
  LPair: TJSONPair;
  LJSONObject: TJSONObject;
  LJSONValue: TJSONValue;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  LMembers := GetNeonMembers(AType);
  LMembers.FilterSerialize(AInstance);

  for LNeonMember in LMembers do
  begin

    if LNeonMember.Serializable then
    begin
      try
        LJSONValue := WriteDataMember(LNeonMember.GetValue(AInstance), True, LNeonMember);
        if Assigned(LJSONValue) then
        begin
          // if it's unwrapped add childs to the AResult JSON object
          if LNeonMember.NeonUnwrapped and (LJSONValue is TJSONObject) then
          begin
            LJSONObject := LJSONValue as TJSONObject;
            for LPair in LJSONObject do
              (AResult as TJSONObject).AddPair(LPair.Clone as TJSONPair);
            LJSONObject.Free;
          end
          else
          begin
            LPairName := GetNameFromMember(LNeonMember);
            LPair := TJSONPair.Create(LPairName, LJSONValue);
            (AResult as TJSONObject).AddPair(LPair);
          end;
        end;
      except
        on E: Exception do
        begin
          LogError(Format(SNeonErrorMemberF3,
            [LNeonMember.Name, AType.Name, E.Message]));
          if FConfig.RaiseExceptions then
            raise;
        end;
      end;
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Serialize:Members', LStamp);
  end;
end;

function TNeonSerializerJSON.WriteNullable(const AValue: TValue; ANeonObject: TNeonRttiObject; ANullable: IDynamicNullable): TJSONValue;
begin
  Result := nil;
  if not Assigned(ANullable) then
    Exit;

  case ANeonObject.NeonInclude.Value of
    IncludeIf.Always, IncludeIf.CustomFunction:
    begin
      if ANullable.HasValue then
        Result := WriteDataMember(ANullable.GetValue, True, ANeonObject)
      else
        Result := TJSONNull.Create;
    end;
    IncludeIf.NotNull, IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if ANullable.HasValue then
        Result := WriteDataMember(ANullable.GetValue, True, ANeonObject);
    end;
  end;
end;

function TNeonSerializerJSON.WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LType: TRttiType;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
    LObject := AValue.AsObject;

    if LObject = nil then
      Exit(nil);

    LType := TRttiUtils.Context.GetType(LObject.ClassType);

    Result := TJSONObject.Create;
    try
      WriteMembers(LType, LObject, Result);
      case ANeonObject.NeonInclude.Value of
        IncludeIf.NotEmpty, IncludeIf.NotDefault:
        begin
          if (Result as TJSONObject).Count = 0 then
            FreeAndNil(Result);
        end;
      end;
    except
      on E: Exception do
      begin
        // Free the partial result, then let the error propagate: without the
        // re-raise, RaiseExceptions only works for top-level members because
        // every nested object/record/map swallows the exception
        FreeAndNil(Result);
        if FConfig.RaiseExceptions then
          raise;
        // Swallowed: this is not a member error (WriteMembers logs and skips
        // those), the whole object is gone from the document
        LogError(Format(SNeonErrorSerializeTypeF2, [LType.Name, E.Message]));
      end;
    end;
  finally
    TNeonLogger.ProfileEnd('Serialize:Object', LStamp);
  end;
end;

function TNeonSerializerJSON.WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject; AList: IDynamicList): TJSONValue;
var
  LJSONValue: TJSONValue;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
    // Not an enumerable object
    if not Assigned(AList) then
      Exit(nil);
    if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
      if AList.Count = 0 then
        Exit(nil);

    Result := TJSONArray.Create;
    while AList.MoveNext do
    begin
      LJSONValue := WriteDataMember(AList.Current);
      // Nil elements become JSON null (same reasoning as WriteArray)
      if not Assigned(LJSONValue) then
        LJSONValue := TJSONNull.Create;
      (Result as TJSONArray).AddElement(LJSONValue);
    end;
  finally
    TNeonLogger.ProfileEnd('Serialize:Enumerable', LStamp);
  end;
end;

function TNeonSerializerJSON.WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject; AMap: IDynamicMap): TJSONValue;
var
  LName: string;
  LJSONName: TJSONValue;
  LJSONValue: TJSONValue;
  LKeyValue, LValValue: TValue;
  LPairs: TObjectList<TJSONPair>;
  LPair: TJSONPair;
  LStamp: Int64;

  function PairKeyComparer(AReverse: Boolean): IComparer<TJSONPair>;
  begin
    Result := TComparer<TJSONPair>.Construct(
      function(const ALeft, ARight: TJSONPair): Integer
      begin
        Result := CompareStr(ALeft.JsonString.Value, ARight.JsonString.Value);
        if AReverse then
          Result := -Result;
      end);
  end;

begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  // Not an EnumerableMap object
  if not Assigned(AMap) then
    Exit(nil);

  case ANeonObject.NeonInclude.Value of
    IncludeIf.Always:
    begin
      if not Assigned(AMap) then
        Exit(TJSONNull.Create);
    end;
    IncludeIf.NotNull:
    begin
      if not Assigned(AMap) then
        Exit(nil);
    end;
    IncludeIf.NotEmpty:
    begin
      if AMap.Count = 0 then
        Exit(nil);
    end;
    IncludeIf.NotDefault: ;
  end;

  Result := TJSONObject.Create;
  try
    LPairs := TObjectList<TJSONPair>.Create(True);
    try
      while AMap.MoveNext do
      begin
        LKeyValue := AMap.CurrentKey;
        LValValue := AMap.CurrentValue;

        // A JSON name is always a string, so the key needs an unambiguous text
        // form: a string key is itself, a number/boolean key is its JSON text
        // (an Integer-keyed map writes {"1": ...}), a class key goes through
        // ToString. Anything else has no name to write and is refused here with
        // the error ReadEnumerableMap raises for the same key types.
        // The name is resolved before the value is written, so refusing a key
        // cannot leak the value's JSON, and an empty string key - which is legal
        // JSON - is no longer mistaken for a failure to build a name
        LJSONName := WriteDataMember(LKeyValue);
        try
          if LJSONName is TJSONString then
            LName := (LJSONName as TJSONString).Value
          else if (LJSONName is TJSONNumber) or TJSONUtils.IsBool(LJSONName) then
            LName := LJSONName.Value
          else if AMap.KeyIsString then
            LName := AMap.KeyToString(LKeyValue)
          else
            raise ENeonException.Create(SNeonErrorDictKeyInvalid);
        finally
          LJSONName.Free;
        end;

        LJSONValue := WriteDataMember(LValValue);
        // A nil value (nil object, empty value under NotEmpty/NotDefault)
        // becomes JSON null so the pair keeps a valid, printable value
        if not Assigned(LJSONValue) then
          LJSONValue := TJSONNull.Create;

        LPairs.Add(TJSONPair.Create(LName, LJSONValue));
      end;

      case FConfig.MapSort of
        TNeonSort.Rtti: ; // Default, keep the map enumeration order
        TNeonSort.RttiReverse: LPairs.Reverse;
        TNeonSort.Alpha: LPairs.Sort(PairKeyComparer(False));
        TNeonSort.AlphaReverse: LPairs.Sort(PairKeyComparer(True));
      end;

      // The pairs are now owned by the resulting JSON object
      LPairs.OwnsObjects := False;
      for LPair in LPairs do
        (Result as TJSONObject).AddPair(LPair);
    finally
      LPairs.Free;
    end;
  except
    on E: Exception do
    begin
      FreeAndNil(Result);
      // Same reasoning as WriteObject/WriteRecord: free the partial result,
      // then let the error propagate when RaiseExceptions is set
      if FConfig.RaiseExceptions then
        raise;
      // Swallowed: the whole map is gone from the document, so it goes through
      // LogError (not FErrors.Add) for the configured handler to see it
      LogError(Format(SNeonErrorSerializeTypeF2,
        [TRttiUtils.Context.GetType(AValue.TypeInfo).Name, E.Message]));
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Serialize:EnumerableMap', LStamp);
  end;
end;

function TNeonSerializerJSON.WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LType: TRttiType;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  Result := TJSONObject.Create;
  LType := TRttiUtils.Context.GetType(AValue.TypeInfo);
  try
    WriteMembers(LType, AValue.GetReferenceToRawData, Result);
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault:
      begin
        if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
          if (Result as TJSONObject).Count = 0 then
            FreeAndNil(Result);
      end;
    end;
  except
    on E: Exception do
    begin
      // Free the partial result, then let the error propagate
      FreeAndNil(Result);
      if FConfig.RaiseExceptions then
        raise;
      // Swallowed: same as WriteObject, the whole record is gone
      LogError(Format(SNeonErrorSerializeTypeF2, [LType.Name, E.Message]));
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Serialize:Record', LStamp);
  end;
end;

function TNeonSerializerJSON.WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LArray: TJSONArray;
  LElementType: PPTypeInfo;
  LEnumTypeData: PTypeData;
  LSetData: array[0..31] of Byte;
  LSize: Integer;
  LIndex: Integer;
  LOrdinal: Integer;
  LJSONValue: TJSONValue;
  LValue: TValue;
begin
  LArray := TJSONArray.Create;

  LElementType := GetTypeData(AValue.TypeInfo)^.CompType;
  if LElementType <> nil then
  begin
    LEnumTypeData := GetTypeData(LElementType^);

    // A set is stored as the smallest of 1/2/4/8/16/32 bytes that can hold
    // the enum range; iterate every bit so sets with more than 32 elements
    // (and non-zero-based enums) are not truncated
    LSize := ((LEnumTypeData.MaxValue - LEnumTypeData.MinValue + 1) + 7) div 8;
    if LSize <= 1 then LSize := 1
    else if LSize <= 2 then LSize := 2
    else if LSize <= 4 then LSize := 4
    else if LSize <= 8 then LSize := 8
    else if LSize <= 16 then LSize := 16
    else LSize := 32;

    FillChar(LSetData, SizeOf(LSetData), 0);
    Move(AValue.GetReferenceToRawData^, LSetData, LSize);

    for LIndex := 0 to LSize * 8 - 1 do
      if (LSetData[LIndex div 8] and (1 shl (LIndex mod 8))) <> 0 then
      begin
        LOrdinal := LEnumTypeData.MinValue + LIndex;
        // Bits beyond the enum range are not valid elements
        if (LOrdinal >= LEnumTypeData.MinValue) and (LOrdinal <= LEnumTypeData.MaxValue) then
        begin
          TValue.Make(LOrdinal, LElementType^, LValue);
          LJSONValue := WriteDataMember(LValue);
          LArray.AddElement(LJSONValue);
        end;
      end;
  end
  else
  begin
    // No RTTI for the element type: fall back to raw 32-bit ordinals
    FillChar(LSetData, SizeOf(LSetData), 0);
    LSize := SizeOf(Integer);
    Move(AValue.GetReferenceToRawData^, LSetData, LSize);

    for LIndex := 0 to LSize * 8 - 1 do
      if (LSetData[LIndex div 8] and (1 shl (LIndex mod 8))) <> 0 then
      begin
        LValue := LIndex;
        LJSONValue := WriteDataMember(LValue);
        LArray.AddElement(LJSONValue);
      end;
  end;

  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LArray.Count = 0 then
      FreeAndNil(LArray);

  Result := LArray;
end;

function TNeonSerializerJSON.WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject; AStream: IDynamicStream): TJSONValue;
var
  LBinaryStream: TMemoryStream;
  LBase64: string;
begin
  Result := nil;

  if Assigned(AStream) then
  begin
    LBinaryStream := TMemoryStream.Create;
    try
      AStream.SaveToStream(LBinaryStream);
      LBinaryStream.Position := soFromBeginning;
      LBase64 := TBase64.Encode(LBinaryStream);
      if IsOriginalInstance(AValue) then
        Result := TJSONObject.Create.AddPair('$value', LBase64)
      else
        Result := TJSONString.Create(LBase64);
    finally
      LBinaryStream.Free;
    end;
  end;
end;

function TNeonSerializerJSON.WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsString.IsEmpty then
        Exit(nil);
    end;
  end;

  if ANeonObject.NeonRawValue then
  begin
    // [NeonRawValue] means the member holds JSON text to splice into the
    // document as it is, so it has to parse. Report what failed and where the
    // library's error catalog can be read, instead of letting the RTL's parse
    // exception (or, when the parser just returns nil, a silently missing
    // member) out of a member whose only job is to carry JSON
    Result := TNeon.ParseJSON(AValue.AsString, False, False);
    if not Assigned(Result) then
      raise ENeonException.CreateFmt(SNeonErrorRawValueF1, [AValue.AsString]);
  end
  else
    Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteVariantDate(const AValue: TDateTime; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  // A varDate carries a full TDateTime: writing it as a plain date would drop
  // the time of everything that ReadVariant decoded from an ISO-8601 string
  if Frac(AValue) = 0 then
    Result := WriteDate(TValue.From<TDate>(AValue), ANeonObject)
  else
    Result := WriteDateTime(TValue.From<TDateTime>(AValue), ANeonObject);
end;

function TNeonSerializerJSON.WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LValue: Variant;
  LVariantType: Integer;
begin
  LValue := AValue.AsVariant;
  case ANeonObject.NeonInclude.Value of
    IncludeIf.Always:
    begin
      if VarIsNull(LValue) then
        Exit(TJSONNull.Create);
    end;

    IncludeIf.NotNull:
    begin
      if VarIsNull(LValue) then
        Exit(nil);
    end;

    IncludeIf.NotEmpty:
    begin
      if VarIsEmpty(LValue) then
        Exit(nil);
    end;
  end;

  // A variant array has no scalar JSON form, and ReadVariant refuses a JSON
  // array in return: fail with a clear message instead of letting the branches
  // below escape as an opaque EVariantTypeCastError
  if VarIsArray(LValue) then
    raise ENeonException.Create(SNeonErrorVariantArray);

  LVariantType := VarType(LValue) and VarTypeMask;
  case LVariantType of
    //varEmpty   :
    //varNull    :
    varSmallInt,
    varInteger : Result := WriteInteger(Int64(LValue), ANeonObject);
    varSingle  ,
    varDouble  ,
    varCurrency: Result := WriteFloat(Currency(LValue), ANeonObject);
    varDate    : Result := WriteVariantDate(VarToDateTime(LValue), ANeonObject);
    //varOleStr  :
    //varDispatch:
    //varError   :
    varBoolean : Result := WriteBoolean(Boolean(LValue), ANeonObject);
    //varVariant :
    //varUnknown :
    varByte    ,
    varWord    ,
    varLongWord,
    varInt64   : Result := WriteInteger(Int64(LValue), ANeonObject);
    //varStrArg  :
    varString  : Result := WriteString(VarToStr(LValue), ANeonObject);
    //varAny     :
    //varTypeMask:

  else
    Result := TJSONString.Create(AValue.AsVariant);
  end;
end;

constructor TNeonDeserializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Deserialize;
end;

function TNeonDeserializerJSON.ReadArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LArrayLength: NativeInt;
  LJSONArray: TJSONArray;
  LItemValue: TValue;
  LItemParam: TNeonDeserializerParam;
  LOldItems: TArray<TObject>;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  Result := AData;
  LJSONArray := AParam.JSONValue as TJSONArray;
  LArrayLength := LJSONArray.Count;

  if AParam.RttiType.TypeKind = tkArray then
  begin
    LItemParam.RttiType := (AParam.RttiType as TRttiArrayType).ElementType;

    // A static array has a fixed size: refuse JSON that is longer instead
    // of letting SetArrayElement raise a raw range exception
    if LJSONArray.Count > Result.GetArrayLength then
      raise ENeonException.CreateFmt(SNeonErrorRangeOutF2,
        [LJSONArray.Count.ToString, AParam.RttiType.Name]);
  end
  else //tkDynArray
  begin
    LItemParam.RttiType := (AParam.RttiType as TRttiDynamicArrayType).ElementType;
    DynArraySetLength(PPointer(Result.GetReferenceToRawData)^, Result.TypeInfo, 1, @LArrayLength);
  end;

  // For a static array of classes, snapshot the elements the member
  // currently holds so they can be released after the new elements have
  // been read: the deserializer owns the contents it replaces, and freeing
  // before the read completed could leave the member with freed references
  // if an element read raises
  LOldItems := nil;
  if (AParam.RttiType.TypeKind = tkArray) and (LItemParam.RttiType.TypeKind = tkClass) then
  begin
    SetLength(LOldItems, Result.GetArrayLength);
    for LIndex := 0 to High(LOldItems) do
      LOldItems[LIndex] := Result.GetArrayElement(LIndex).AsObject;
  end;

  LItemParam.NeonObject := GetNeonObject(LItemParam.RttiType.Handle);

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LItemParam.JSONValue := LJSONArray.Items[LIndex];

    // A null item has nothing to read into: the slot gets the element type's
    // default (nil for a class), instead of the empty instance the factory or
    // the constructor used to build for it
    if LItemParam.JSONValue is TJSONNull then
    begin
      Result.SetArrayElement(LIndex, TValue.Empty.Cast(LItemParam.RttiType.Handle));
      Continue;
    end;

    if AParam.RttiType.TypeKind = tkArray then // Static Array
    begin
      // Replace the stored element with a fresh one via the item factory
      // (or the plain constructor), so the factory is consulted for every
      // JSON item; the previous object is freed after the loop below
      if LItemParam.RttiType.TypeKind = tkClass then
        LItemValue := CreateItem(AParam.NeonObject, LItemParam.JSONValue, LItemParam.RttiType)
      else
        LItemValue := Result.GetArrayElement(LIndex);
    end
    else //tkDynArray (Dynamic Array)
      LItemValue := CreateItem(AParam.NeonObject, LItemParam.JSONValue, LItemParam.RttiType);

    LItemValue := ReadDataMember(LItemParam, LItemValue, True);
    Result.SetArrayElement(LIndex, LItemValue);
  end;

  // Every element was read successfully: release the previous contents
  for LIndex := 0 to High(LOldItems) do
    LOldItems[LIndex].Free;
end;

function TNeonDeserializerJSON.ReadChar(const AParam: TNeonDeserializerParam): TValue;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if AParam.JSONValue.Value.IsEmpty then
    Exit(TValue.Empty);

  case AParam.RttiType.TypeKind of
{$IFDEF HAS_UTF8CHAR}
    tkChar:  Result := TValue.From<UTF8Char>(UTF8Char(AParam.JSONValue.Value.Chars[0]));
{$ELSE}
    tkChar,
{$ENDIF}
    tkWChar: Result := TValue.From<Char>(AParam.JSONValue.Value.Chars[0]);
  end;
end;

function TNeonDeserializerJSON.ReadDataMember(AJSONValue: TJSONValue;
    AType: TRttiType; const AData: TValue; ACustomProcess: Boolean): TValue;
var
  LParam: TNeonDeserializerParam;
  LStamp: Int64;
begin
  // Mirrors the serializer's entry overload, cache included - see the comment
  // there. Custom serializers recursing through IDeserializerContext land here,
  // and TCollectionSerializer does it once per item
  LStamp := TNeonLogger.ProfileBegin;
  LParam.JSONValue := AJSONValue;
  LParam.RttiType := AType;
  LParam.NeonObject := GetNeonObject(AType.Handle);
  TNeonLogger.ProfileEnd('Deserialize:RttiResolve', LStamp);

  Result := ReadDataMember(LParam, AData, ACustomProcess);
end;

function TNeonDeserializerJSON.ReadDataMember(var AParam: TNeonDeserializerParam;
  const AData: TValue; ACustomProcess: Boolean): TValue;
var
  LCustom: TCustomSerializer;
  LValue: TValue;
begin
  Result := TValue.Empty;

  if ACustomProcess then
  begin
    // if there is a custom serializer
    LCustom := FConfig.Serializers.GetSerializer(AParam.RttiType.Handle);
    if Assigned(LCustom) then
    begin
      LValue := ManageInstance(AParam, AData);

      // A nil target instance (no AutoCreate/factory and no parameterless
      // constructor - e.g. an abstract TStream member) cannot be populated by
      // the serializer without dereferencing nil: skip it and log, matching
      // the engine's "no AutoCreate -> member stays nil". A serializer that
      // builds the value itself (NeedsInstance = False) is called anyway
      if LCustom.NeedsInstance and (LValue.Kind = tkClass) and (LValue.AsObject = nil) then
      begin
        LogError(Format(SNeonErrorDeserializeNilF1, [AParam.RttiType.Name]));
        Exit(LValue);
      end;

      Result := LCustom.Deserialize(AParam.JSONValue, LValue, AParam.NeonObject, Self);
      Exit(Result);
    end;
  end;

  // A JSON null is a value, not a missing member: it is applied here, after the
  // custom serializers (which may have their own reading of null) and before
  // every type reader, so that null means the same thing everywhere
  if AParam.JSONValue is TJSONNull then
    Exit(ReadNull(AParam, AData));

  case AParam.RttiType.TypeKind of
    // Simple types
    tkInt64:       Result := ReadInt64(AParam);
    tkInteger:     Result := ReadInteger(AParam);
    tkChar:        Result := ReadChar(AParam);
    tkWChar:       Result := ReadChar(AParam);
    tkEnumeration: Result := ReadEnum(AParam);
    tkFloat:       Result := ReadFloat(AParam);
    tkLString:     Result := ReadString(AParam);
    tkWString:     Result := ReadString(AParam);
    tkUString:     Result := ReadString(AParam);
    tkString:      Result := ReadString(AParam);
    tkSet:         Result := ReadSet(AParam);
    tkVariant:     Result := ReadVariant(AParam);
    tkArray:       Result := ReadArray(AParam, AData);
    tkDynArray:    Result := ReadArray(AParam, AData);
    tkInterface:   Result := ReadInterface(AParam, AData);

    tkClass:      Result := ReadReference(AParam, AData);

    tkRecord{$IFDEF HAS_MRECORDS}, tkMRecord{$ENDIF}:
    begin
      if ReadNullable(AParam, AData) then
        Result := AData
      else
        Result := ReadRecord(AParam, AData);
    end;

  end;
end;

function TNeonDeserializerJSON.ReadNull(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
begin
  case AParam.RttiType.TypeKind of
    // Neon does not own the instance a reference points to, so a null cannot
    // clear it here without leaking it: the reference keeps its value
    tkClass, tkInterface:
      Result := AData;

    // A Variant has a null of its own, which is not the same as Unassigned
    tkVariant:
      Result := TValue.From<Variant>(Null);

    tkRecord{$IFDEF HAS_MRECORDS}, tkMRecord{$ENDIF}:
    begin
      // A zeroed Nullable<T> is exactly "no value"; any other record has no
      // null form and is left as it is
      if Assigned(TDynamicNullable.GuessType(AData)) then
        Result := TValue.Empty.Cast(AParam.RttiType.Handle)
      else
        Result := AData;
    end;

  else
    // Everything else goes back to its default: '' for a string, 0 for a
    // number, the empty set, an empty array
    Result := TValue.Empty.Cast(AParam.RttiType.Handle);
  end;
end;

function TNeonDeserializerJSON.ReadEnum(const AParam: TNeonDeserializerParam): TValue;
var
  LIndex, LOrdinal: Integer;
  LTypeData: PTypeData;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if AParam.RttiType.Handle = System.TypeInfo(Boolean) then
  begin
    if TJSONUtils.IsBool(AParam.JSONValue) then
      Result := TJSONUtils.GetValueBool(AParam.JSONValue)
    else if not FConfig.StrictTypes  then
      Result := AParam.JSONValue.GetValue<Boolean>
    else
      raise ENeonException.Create(SNeonErrorBoolExpected);
  end
  else
  begin
    if FConfig.EnumAsInt then
    begin
      LTypeData := GetTypeData(AParam.RttiType.Handle);
      LOrdinal := StrToIntDef(AParam.JSONValue.Value, -1);
      if (LOrdinal >= LTypeData.MinValue) and (LOrdinal <= LTypeData.MaxValue) then
        TValue.Make(LOrdinal, AParam.RttiType.Handle, Result)
      else
        raise ENeonException.Create(SNeonErrorEnumInvalid);
    end
    else
    begin
      LOrdinal := -1;

      // An explicit [NeonEnumNames] spelling is what the writer produces, so
      // it is accepted verbatim
      if Length(AParam.NeonObject.NeonEnumNames) > 0 then
      begin
        for LIndex := Low(AParam.NeonObject.NeonEnumNames) to High(AParam.NeonObject.NeonEnumNames) do
          if AParam.JSONValue.Value = AParam.NeonObject.NeonEnumNames[LIndex] then
            LOrdinal := LIndex;
      end;

      // GetEnumValue knows the RTTI spelling and is case-insensitive, which
      // reads back the settings that only change capitalization (lower, upper,
      // camel, pascal) and the documents written before the case was applied
      if LOrdinal = -1 then
        LOrdinal := GetEnumValue(AParam.RttiType.Handle, AParam.JSONValue.Value);

      // A separator introduced by snake, kebab or screaming snake, or a name
      // rewritten by a custom function, is not something GetEnumValue can
      // resolve: regenerate the name the writer produces for each member and
      // compare against it
      if LOrdinal = -1 then
      begin
        LTypeData := GetTypeData(AParam.RttiType.Handle);
        for LIndex := LTypeData.MinValue to LTypeData.MaxValue do
          if AParam.JSONValue.Value = TTypeInfoUtils.EnumToJSONName(
            AParam.RttiType.Handle, LIndex, FConfig.MemberCase, FConfig.MemberCustomCase) then
          begin
            LOrdinal := LIndex;
            Break;
          end;
      end;

      LTypeData := GetTypeData(AParam.RttiType.Handle);

      if (LOrdinal >= LTypeData.MinValue) and (LOrdinal <= LTypeData.MaxValue) then
        TValue.Make(LOrdinal, AParam.RttiType.Handle, Result)
      else
        raise ENeonException.Create(SNeonErrorEnumNames);
    end;
  end;
end;

function TNeonDeserializerJSON.ReadEnumerable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LItemValue: TValue;
  LList: IDynamicList;
  LJSONArray: TJSONArray;
  LIndex: Integer;
  LParam: TNeonDeserializerParam;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  Result := False;
  LParam.NeonObject := AParam.NeonObject;
  LList := TDynamicList.GuessType(AData.AsObject);
  if Assigned(LList) then
  begin
    Result := True;
    LParam.RttiType := LList.GetItemType;
    LList.Clear;

    LJSONArray := AParam.JSONValue as TJSONArray;

    for LIndex := 0 to LJSONArray.Count - 1 do
    begin
      LParam.JSONValue := LJSONArray.Items[LIndex];

      // A null item has nothing to read into: the list gets the item type's
      // default (nil for a class), instead of the empty instance the factory or
      // the constructor used to build for it
      if LParam.JSONValue is TJSONNull then
      begin
        LList.Add(TValue.Empty.Cast(LParam.RttiType.Handle));
        Continue;
      end;

      if LParam.RttiType.TypeKind = tkClass then
        LItemValue := CreateItem(AParam.NeonObject, LParam.JSONValue, LParam.RttiType)
      else
        LItemValue := LList.NewItem;

      LItemValue := ReadDataMember(LParam, LItemValue, True);

      LList.Add(LItemValue);
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Deserialize:Enumerable', LStamp);
  end;
end;

function TNeonDeserializerJSON.IsSupportedMapKeyType(AType: TRttiType; AMap: IDynamicMap): Boolean;
begin
  // A class key round-trips only through its ToString/FromString pair
  if AType.TypeKind = tkClass then
    Exit(AMap.KeyIsString);

  // A custom serializer speaks for its own type (e.g. a TGUID key written as a
  // string): trust it, the way WriteEnumerableMap trusts what it produced
  if Assigned(FConfig.Serializers.GetSerializer(AType.Handle)) then
    Exit(True);

  Result := AType.TypeKind in [tkChar, tkWChar, tkString, tkLString, tkWString,
    tkUString, tkInteger, tkInt64, tkFloat, tkEnumeration, tkVariant];
end;

function TNeonDeserializerJSON.MapKeyToJSON(AType: TRttiType; const AName: string): TJSONValue;
var
  LInt: Int64;
begin
  Result := nil;

  case AType.TypeKind of
    tkInteger, tkInt64:
    begin
      if TryStrToInt64(AName, LInt) then
        Result := TJSONNumber.Create(LInt);
    end;

    tkFloat:
    begin
      // TDate/TTime/TDateTime are written as strings, so they want the name
      if (AType.Handle <> System.TypeInfo(TDate)) and
         (AType.Handle <> System.TypeInfo(TTime)) and
         (AType.Handle <> System.TypeInfo(TDateTime)) then
        Result := TJSONNumber.Create(AName);
    end;

    tkEnumeration:
    begin
      if AType.Handle = System.TypeInfo(Boolean) then
      begin
        if SameText(AName, 'true') then
          Result := TJSONTrue.Create
        else if SameText(AName, 'false') then
          Result := TJSONFalse.Create;
      end
      else if FConfig.EnumAsInt and TryStrToInt64(AName, LInt) then
        Result := TJSONNumber.Create(LInt);
    end;
  end;
end;

function TNeonDeserializerJSON.ReadEnumerableMap(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LMap: IDynamicMap;
{$IFDEF HAS_NEW_JSON}
  LEnum: TJSONObject.TEnumerator;
{$ELSE}
  LEnum: TJSONPairEnumerator;
{$ENDIF}
  LKey, LValue: TValue;
  LKeyJSON: TJSONValue;
  LParamKey, LParamValue: TNeonDeserializerParam;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  Result := False;
  LParamKey.NeonObject := AParam.NeonObject;
  LParamValue.NeonObject := AParam.NeonObject;

  LMap := TDynamicMap.GuessType(AData.AsObject);
  if Assigned(LMap) then
  begin
    Result := True;
    LParamKey.RttiType := LMap.GetKeyType;
    LParamValue.RttiType := LMap.GetValueType;
    LMap.Clear;

    LEnum := (AParam.JSONValue as TJSONObject).GetEnumerator;
    try
      while LEnum.MoveNext do
      begin
        // Key creation and deserialization
        LParamKey.JSONValue := LEnum.Current.JsonString;

        // A key type with no text form cannot come back from a JSON name: fail
        // with the same error WriteEnumerableMap raises for it, instead of
        // adding a default-constructed key (a class without FromString) or
        // failing later with an unrelated message
        if not IsSupportedMapKeyType(LParamKey.RttiType, LMap) then
          raise ENeonException.Create(SNeonErrorDictKeyInvalid);

        if LParamKey.RttiType.TypeKind = tkClass then
        begin
          LKey := CreateItem(AParam.NeonObject, LParamKey.JSONValue, LParamKey.RttiType);
          LMap.KeyFromString(LKey, LEnum.Current.JsonString.Value);
        end
        else
        begin
          LKey := LMap.NewKey;

          // The name is a string even when the key is not: give the reader the
          // JSON shape that matches the key type, so a numeric or boolean key
          // is not rejected by StrictTypes for being the string JSON requires
          LKeyJSON := MapKeyToJSON(LParamKey.RttiType, LEnum.Current.JsonString.Value);
          try
            if Assigned(LKeyJSON) then
              LParamKey.JSONValue := LKeyJSON;
            LKey := ReadDataMember(LParamKey, LKey, True);
          finally
            LKeyJSON.Free;
          end;
        end;

        // Value creation and deserialization
        LParamValue.JSONValue := LEnum.Current.JsonValue;

        // A null value has nothing to read into: the pair gets the value type's
        // default (nil for a class), not a freshly created empty instance
        if LParamValue.JSONValue is TJSONNull then
          LValue := TValue.Empty.Cast(LParamValue.RttiType.Handle)
        else
        begin
          if LParamValue.RttiType.TypeKind = tkClass then
            LValue := CreateItem(AParam.NeonObject, LParamValue.JSONValue, LParamValue.RttiType)
          else
            LValue := LMap.NewValue;

          LValue := ReadDataMember(LParamValue, LValue, True);
        end;

        // Add the pair to the Map
        LMap.Add(LKey, LValue);
      end;
    finally
      LEnum.Free;
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Deserialize:EnumerableMap', LStamp);
  end;
end;

function TNeonDeserializerJSON.ReadFloat(const AParam: TNeonDeserializerParam): TValue;
var
  LFloat: Extended;
  LMax: Extended;
  LMsg: string;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if AParam.RttiType.Handle = System.TypeInfo(TDate) then
    Result := TValue.From<TDate>(TJSONUtils.JSONToDate(AParam.JSONValue.Value))
  else if AParam.RttiType.Handle = System.TypeInfo(TTime) then
    Result := TValue.From<TTime>(TJSONUtils.JSONToTime(AParam.JSONValue.Value))
  else if AParam.RttiType.Handle = System.TypeInfo(TDateTime) then
    Result := TValue.From<TDateTime>(TJSONUtils.JSONToDateTime(AParam.JSONValue.Value, FConfig.UseUTCDate))
  else
  begin
    if FConfig.StrictTypes and not (AParam.JSONValue is TJSONNumber) then
      raise ENeonException.Create(SNeonErrorNumExpected);

    LMax := 0;
    case GetTypeData(AParam.RttiType.Handle).FloatType of
      ftSingle:
      begin
        LMax := MaxSingle;
        LMsg := 'Single';
      end;
      ftDouble:
      begin
        LMax := MaxDouble;
        LMsg := 'Double';
      end;
      ftExtended:
      begin
{$IFDEF HAS_EXTENDED_80}
        LMax := MaxExtended80;
{$ELSE}
        LMax := MaxExtended;
{$ENDIF}
        LMsg := 'Extended';
      end;
      ftComp:
      begin
        LMax := MaxComp;
        LMsg := 'Comp';
      end;
      ftCurr:
      begin
        LMax := MaxCurrency;
        LMsg := 'Currency';
      end;
    end;

    try
      LFloat := AParam.JSONValue.GetValue<Extended>;
    except
      on E: EOverflow do
        raise ENeonException.CreateFmt(SNeonErrorRangeOutF2, [AParam.JSONValue.Value, LMsg]);
    end;

    if (LFloat < -LMax) or (LFloat > LMax) then
      raise ENeonException.CreateFmt(SNeonErrorRangeOutF2, [AParam.JSONValue.Value, LMsg]);

    Result := LFloat;
  end;
end;

function TNeonDeserializerJSON.ReadInt64(const AParam: TNeonDeserializerParam): TValue;
var
  LMin, LInt: Int64;
  LUInt: UInt64;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if FConfig.StrictTypes and not (AParam.JSONValue is TJSONNumber) then
    raise ENeonException.Create(SNeonErrorNumExpected);

  LMin := GetTypeData(AParam.RttiType.Handle).MinInt64Value;
  if LMin < 0 then
  begin
    LInt := StrToInt64(AParam.JSONValue.Value);
    Result := LInt;
  end
  else
  begin
    LUInt := StrToUInt64(AParam.JSONValue.Value);
    TValue.Make(@LUInt, System.TypeInfo(UInt64), Result);
  end;
end;

function TNeonDeserializerJSON.ReadInteger(const AParam: TNeonDeserializerParam): TValue;
var
  LMin, LMax, LInt: Int64;
  LMsg: string;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if FConfig.StrictTypes and not (AParam.JSONValue is TJSONNumber) then
    raise ENeonException.Create(SNeonErrorNumExpected);

  LInt := StrToInt64(AParam.JSONValue.Value);

  LMin := 0;
  LMax := 0;
  case GetTypeData(AParam.RttiType.Handle)^.OrdType of
    otSByte:
    begin
      LMin := Low(Int8);
      LMax := High(Int8);
      LMsg := 'a signed 8-bit value';
    end;
    otUByte:
    begin
      LMin := Low(UInt8);
      LMax := High(UInt8);
      LMsg := 'an unsigned 8-bit value';
    end;
    otSWord:
    begin
      LMin := Low(Int16);
      LMax := High(Int16);
      LMsg := 'a signed 16-bit value';
    end;
    otUWord:
    begin
      LMin := Low(UInt16);
      LMax := High(UInt16);
      LMsg := 'an unsigned 16-it value';
    end;
    otSLong:
    begin
      LMin := Low(Int32);
      LMax := High(Int32);
      LMsg := 'a signed 32-bit value';
    end;
    otULong:
    begin
      LMin := Low(UInt32);
      LMax := High(UInt32);
      LMsg := 'an unsigned 32-bit value';
    end;
  end;
  if (LInt < LMin) or (LInt > LMax) then
    raise ENeonException.CreateFmt(SNeonErrorRangeOutF2, [LInt.ToString, LMsg]);

  Result := LInt;
end;

function TNeonDeserializerJSON.CreateInterface(const AParam: TNeonDeserializerParam; out AObject: TObject): TValue;
var
  LFactory: TCustomFactory;
  LIntfType: TRttiInterfaceType;
  LInterface: IInterface;
begin
  Result := TValue.Empty;
  AObject := nil;

  // Nothing in the JSON says which class implements an interface, and the
  // engine cannot guess one: without a [NeonFactory] - on the member or on the
  // interface type - there is nothing to read into, so the member keeps what it
  // has, exactly like a nil class member with no AutoCreate
  if not Assigned(AParam.NeonObject.NeonFactoryClass) then
  begin
    LogError(Format(SNeonErrorInterfaceNoFactoryF1, [AParam.RttiType.Name]));
    Exit;
  end;

  // Asking an object for an interface goes through its GUID, so an interface
  // declared without one cannot be built from a class
  LIntfType := AParam.RttiType as TRttiInterfaceType;
  if not (ifHasGuid in LIntfType.IntfFlags) then
    raise ENeonException.CreateFmt(SNeonErrorInterfaceNoGuidF1, [LIntfType.Name]);

  LFactory := AParam.NeonObject.NeonFactoryClass.Create;
  try
    AObject := LFactory.Build(AParam.RttiType, AParam.JSONValue);
  finally
    LFactory.Free;
  end;

  if not Assigned(AObject) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [LIntfType.Name]);

  // The reference is taken before anything is read, so a failed read releases
  // the object with the TValue instead of leaking it. An object that does not
  // implement the interface is reported and left alone - it is the factory's,
  // and freeing what the factory may still own would be worse than the leak
  if not Supports(AObject, LIntfType.GUID, LInterface) then
    raise ENeonException.CreateFmt(SNeonErrorInterfaceNotImplF2,
      [AObject.ClassName, LIntfType.Name]);

  TValue.Make(@LInterface, AParam.RttiType.Handle, Result);
end;

function TNeonDeserializerJSON.ReadInterface(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LInterface: IInterface;
  LObject: TObject;
  LParam: TNeonDeserializerParam;
begin
  Result := AData;

  // The object behind the interface is what WriteInterface serializes, so it is
  // what gets read: an interface that already points at one is filled in place
  LObject := nil;
  if AData.Kind = tkInterface then
  begin
    LInterface := AData.AsInterface;
    if Assigned(LInterface) then
      LObject := LInterface as TObject;
  end;

  if not Assigned(LObject) then
  begin
    Result := CreateInterface(AParam, LObject);
    if not Assigned(LObject) then
      Exit;
  end;

  // The members are read from the implementing class, not from the interface:
  // an interface publishes properties the class may map to different members,
  // and the serializer writes the class's members too
  LParam := AParam;
  LParam.RttiType := TRttiUtils.Context.GetType(LObject.ClassType);
  ReadObject(LParam, LObject);
end;

procedure TNeonDeserializerJSON.ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
var
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LMemberValue: TValue;
  LParam: TNeonDeserializerParam;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
  LMembers := GetNeonMembers(AType);
  LMembers.FilterDeserialize(AInstance);

  for LNeonMember in LMembers do
  begin
    if LNeonMember.Serializable then
    begin
      LParam.NeonObject := LNeonMember;
      LParam.RttiType := LNeonMember.RttiType;

      if LNeonMember.NeonUnwrapped then
        LParam.JSONValue := AJSONObject
      else
        //Look for a JSON with the calculated Member Name
        LParam.JSONValue := AJSONObject.GetValue(GetNameFromMember(LNeonMember));

      // Property not found in JSON, continue to the next one
      if not Assigned(LParam.JSONValue) then
        Continue;

      try
        // Every JSON value the member has is read, a null and an empty {} or []
        // included: the old TJSONUtils.HasItems filter skipped exactly those, so
        // a value the document states explicitly could not clear, create or
        // empty a member - it silently kept whatever the member already had
        LMemberValue := ReadDataMember(LParam, LNeonMember.GetValue(AInstance), True);

        // A reader that produced no typed value (an unsupported type kind)
        // must not overwrite the member with an untyped TValue
        if LMemberValue.TypeInfo = nil then
          Continue;

        LNeonMember.SetValue(LMemberValue, AInstance);
      except
        on E: Exception do
        begin
          LogError(Format(SNeonErrorMemberF3, [LNeonMember.Name, AType.Name, E.Message]));
          if FConfig.RaiseExceptions then
            raise;
        end;
      end;
    end;
  end;
  finally
    TNeonLogger.ProfileEnd('Deserialize:Members', LStamp);
  end;
end;

function TNeonDeserializerJSON.ReadNullable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LNullable: IDynamicNullable;
  LValue: TValue;
  LValueType: TRttiType;
  LNewParam: TNeonDeserializerParam;
  LNewData: TValue;
begin
  Result := False;
  LNullable := TDynamicNullable.GuessType(AData);
  if Assigned(LNullable) then
  begin
    Result := True;
    LValueType := TRttiUtils.Context.GetType(LNullable.GetValueType);

    LNewParam.JSONValue := AParam.JSONValue;
    LNewParam.NeonObject := AParam.NeonObject;
    LNewParam.RttiType := LValueType;
    LNewData := TValue.Empty.Cast(LValueType.Handle);

    // A custom serializer registered for the inner type T must be honored here:
    // WriteNullable recurses with ACustomProcess=True, and reading with False
    // would bypass it, so a Nullable<T> would not survive its own round trip
    LValue := ReadDataMember(LNewParam, LNewData, True);

    LNullable.SetValue(LValue);
  end;
end;

function TNeonDeserializerJSON.ReadObject(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
    if AParam.JSONValue is TJSONNull then
      Exit(TValue.Empty);

    Result := AData;
    LPData := AData.AsObject;
    if not Assigned(LPData) then
      Exit;

    LJSONObject := AParam.JSONValue as TJSONObject;
    if (AParam.RttiType.TypeKind = tkClass) or (AParam.RttiType.TypeKind = tkInterface) then
      ReadMembers(AParam.RttiType, LPData, LJSONObject);
  finally
    TNeonLogger.ProfileEnd('Deserialize:Object', LStamp);
  end;
end;

function TNeonDeserializerJSON.ReadRecord(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
  LStamp: Int64;
begin
  LStamp := TNeonLogger.ProfileBegin;
  try
    if AParam.JSONValue is TJSONNull then
      Exit(TValue.Empty);

    Result := AData;
    LPData := AData.GetReferenceToRawData;

    if not Assigned(LPData) then
      Exit;

    // Objects, Records, Interfaces are all represented by JSON objects
    LJSONObject := AParam.JSONValue as TJSONObject;

    ReadMembers(AParam.RttiType, LPData, LJSONObject);
  finally
    TNeonLogger.ProfileEnd('Deserialize:Record', LStamp);
  end;
end;

function TNeonDeserializerJSON.ReadSet(const AParam: TNeonDeserializerParam): TValue;
var
  LJSONValue: TJSONValue;
  LJSONArray: TJSONArray;
  LValue: TValue;
  LEnumType: TRttiType;
  LTypeData: PTypeData;
  LSetData: array[0..31] of Byte;
  LOrdinal: Integer;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  LEnumType := TRttiUtils.GetSetElementType(AParam.RttiType);
  if not Assigned(LEnumType) then
    raise ENeonException.Create(SNeonErrorEnumInvalid);

  if AParam.JSONValue is TJSONArray then
    LJSONArray := AParam.JSONValue as TJSONArray
  else
    raise ENeonException.Create(SNeonErrorArrExpected);

  LTypeData := GetTypeData(LEnumType.Handle);

  // The result buffer covers the maximum set size (256 elements = 32 bytes);
  // ordinals are validated against the enum range before their bit is set
  FillChar(LSetData, SizeOf(LSetData), 0);

  for LJSONValue in LJSONArray do
  begin
    if LJSONValue is TJSONNull then
      Continue;

    if LJSONValue is TJSONNumber then
      LValue := (LJSONValue as TJSONNumber).AsInt
    else if TJSONUtils.IsBool(LJSONValue) then
      LValue := TJSONUtils.GetValueBool(LJSONValue)
    else if LJSONValue is TJSONString then
      LValue := ReadDataMember(LJSONValue, LEnumType, TValue.Empty);

    LOrdinal := LValue.AsOrdinal;
    if (LOrdinal < LTypeData.MinValue) or (LOrdinal > LTypeData.MaxValue) then
      raise ENeonException.Create(SNeonErrorEnumInvalid);

    LOrdinal := LOrdinal - LTypeData.MinValue;
    LSetData[LOrdinal div 8] := LSetData[LOrdinal div 8] or (1 shl (LOrdinal mod 8));
  end;

  TValue.Make(@LSetData, AParam.RttiType.Handle, Result);
end;

function TNeonDeserializerJSON.ReadStreamable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LStream: TMemoryStream;
  LStreamable: IDynamicStream;
  LJSONValue: TJSONValue;
begin
  Result := False;
  LStreamable := TDynamicStream.GuessType(AData.AsObject);
  if Assigned(LStreamable) then
  begin
    Result := True;
    LStream := TMemoryStream.Create;
    try
      if IsOriginalInstance(AData) then
      begin
        LJSONValue := (AParam.JSONValue as TJSONObject).GetValue('$value');
        if not Assigned(LJSONValue) then
          raise ENeonException.Create(SNeonErrorStreamableNoValue);
      end
      else
        LJSONValue := AParam.JSONValue;

      TBase64.Decode(LJSONValue.Value, LStream);
      LStream.Position := soFromBeginning;
      LStreamable.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadString(const AParam: TNeonDeserializerParam): TValue;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  if AParam.NeonObject.NeonRawValue then
{$IFDEF HAS_TOJSON}
    Exit(TValue.From<string>(AParam.JSONValue.ToJSON));
{$ELSE}
    Exit(TValue.From<string>(AParam.JSONValue.ToString));
{$ENDIF}

  case AParam.RttiType.TypeKind of

    // AnsiString
    tkLString: Result := TValue.From<UTF8String>(UTF8String(AParam.JSONValue.Value));

    {$IFDEF WINDOWS}
    //WideString
    tkWString: Result := TValue.From<WideString>(AParam.JSONValue.Value);
    {$ENDIF}

    //UnicodeString
    tkUString: Result := TValue.From<string>(AParam.JSONValue.Value);

    //ShortString
    tkString:  Result := TValue.From<UTF8String>(UTF8String(AParam.JSONValue.Value));

  else
    // Future string types treated as unicode strings
    Result := AParam.JSONValue.Value;
  end;
end;

function TNeonDeserializerJSON.ReadVariant(const AParam: TNeonDeserializerParam): TValue;
var
  LDateTime: TDateTime;
begin
  // Because the property is a variant we have to guess the type based (only)
  // on the information of the JSON data

  if not Assigned(AParam.JSONValue) then
    Exit(TValue.Empty);

  if AParam.JSONValue is TJSONNull then
    Exit(TValue.From<Variant>(Null));

  if AParam.JSONValue is TJSONTrue then
    Exit(TValue.From<Variant>(True));

  if AParam.JSONValue is TJSONFalse then
    Exit(TValue.From<Variant>(False));

  if AParam.JSONValue is TJSONNumber then
    Exit(TValue.From<Variant>(JsonToFloat(AParam.JSONValue.Value)));

  if AParam.JSONValue is TJSONString then
  begin
    if TryISO8601ToDate(AParam.JSONValue.Value, LDateTime, FConfig.UseUTCDate) then
      Exit(TValue.From<Variant>(VarFromDateTime(LDateTime)));

    Exit(TValue.From<Variant>(AParam.JSONValue.Value));
  end;

  // A Variant holds scalars only (WriteVariant writes nothing else), so an
  // object or an array has to fail loudly instead of leaving the member
  // Unassigned, which is indistinguishable from "not in the JSON at all"
  if AParam.JSONValue is TJSONObject then
    raise ENeonException.CreateFmt(SNeonErrorVariantNotScalarF1, ['object']);

  if AParam.JSONValue is TJSONArray then
    raise ENeonException.CreateFmt(SNeonErrorVariantNotScalarF1, ['array']);

  raise ENeonException.CreateFmt(SNeonErrorVariantNotScalarF1, [AParam.JSONValue.ClassName]);
end;

function TNeonDeserializerJSON.CreateItem(ANeonRtti: TNeonRttiObject;
  AValue: TJSONValue; var AType: TRttiType): TValue;
var
  LFactory: TCustomFactory;
  LCreated: TObject;
begin
  if Assigned(ANeonRtti.NeonItemFactoryClass) then
  begin
    LFactory := ANeonRtti.NeonItemFactoryClass.Create;
    try
      LCreated := LFactory.Build(AType, AValue);
      AType := TRttiUtils.Context.GetType(LCreated.ClassType);
      Exit(LCreated);
    finally
      LFactory.Free;
    end;
  end;

  Result := TRttiUtils.CreateNewValue(AType);
end;

function TNeonDeserializerJSON.JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  // Seed the read with a zeroed value of the target type, as JSONToTValue
  // does: a raw TValue.Empty has no TypeInfo, so ReadArray can neither
  // allocate a dynamic array (DynArraySetLength needs the element type)
  // nor index a static one
  Result := ReadDataMember(AJSON, AType, TValue.Empty.Cast(AType.Handle));
end;

procedure TNeonDeserializerJSON.JSONToObject(AObject: TObject; AJSON: TJSONValue);
var
  LType: TRttiType;
begin
  FOriginalInstance := AObject;
  LType := TRttiUtils.Context.GetType(AObject.ClassType);
  ReadDataMember(AJSON, LType, AObject);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
begin
  FOriginalInstance := AData;
  Result := ReadDataMember(AJSON, AType, AData);
end;

function TNeonDeserializerJSON.ManageInstance(var AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LFactory: TCustomFactory;
  LObj: TObject;
begin
  Result := AData;

  if not AData.IsObject then
    Exit;

  if not (AData.AsObject = nil) then
    Exit;

  // Anything that is not a JSON null declares a value for the member, so the
  // instance to read it into is created - an empty {} or [] included, which
  // used to count as "nothing to read" and left the member nil
  if AParam.JSONValue is TJSONNull then
    Exit;

  if Assigned(AParam.NeonObject.NeonFactoryClass) then
  begin
    LFactory := AParam.NeonObject.NeonFactoryClass.Create;
    try
      LObj := LFactory.Build(AParam.RttiType, AParam.JSONValue);

      // Compute again the instance type in case it has changed
      AParam.RttiType := TRttiUtils.Context.GetType(LObj.ClassType);

      Exit(LObj);
    finally
      LFactory.Free;
    end;
  end;

  // Try, not CreateInstance: a member whose class has no parameterless
  // constructor (an abstract TStream, say) stays nil and is logged and skipped
  // by ReadDataMember, which is the documented AutoCreate behavior
  if (FConfig.AutoCreate or AParam.NeonObject.NeonAutoCreate) then
    Exit(TRttiUtils.TryCreateInstance(AParam.RttiType));
end;

function TNeonDeserializerJSON.ReadReference(var AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LValue: TValue;
begin
  LValue := ManageInstance(AParam, AData);

  // Each of these three starts with the same structural probe the serializer
  // does, so the cached verdict picks the one that can succeed. A nil instance
  // (no AutoCreate, no factory) matches none of them and falls through to
  // ReadObject, which is where it was handled before as well
  if LValue.AsObject <> nil then
    case GetDynamicKind(LValue.AsObject) of
      TNeonDynamicKind.Map:
        if ReadEnumerableMap(AParam, LValue) then
          Exit(LValue);

      TNeonDynamicKind.List:
        if ReadEnumerable(AParam, LValue) then
          Exit(LValue);

      TNeonDynamicKind.Stream:
        if ReadStreamable(AParam, LValue) then
          Exit(LValue);
    end;

  Result := ReadObject(AParam, LValue);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  Result := ReadDataMember(AJSON, AType, TValue.Empty.Cast(AType.Handle));
end;

{ TNeon }

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject;
begin
  // CreateInstance raises SNeonErrorCreateInstanceF1 itself when the type has
  // no parameterless constructor (A11)
  Result := TRttiUtils.CreateInstance(AType);
  JSONToObject(Result, AJSON, AConfig);
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class procedure TNeon.JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := ParseJSON(AJSON, False, True);
  try
    JSONToObject(AObject, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject<T>(const AJSON: string): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class function TNeon.ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ObjectToJSON(AObject);
  finally
    LWriter.Free;
  end;
end;

class function TNeon.ObjectToJSONString(AObject: TObject): string;
begin
  Result := TNeon.ObjectToJSONString(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  Result := TNeon.ObjectToJSON(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := ObjectToJSON(AObject, AConfig);
  try
    Result := Print(LJSON, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class procedure TNeon.ObjectToStream(AObject: TObject; AStream: TStream);
begin
  ObjectToStream(AObject, AStream, TNeonConfiguration.Default);
end;

class procedure TNeon.ObjectToStream(AObject: TObject; AStream: TStream; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ObjectToJSON(AObject, AConfig);
  try
    PrintToStream(LJSON, AStream, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.Print(AJSONValue: TJSONValue; APretty: Boolean): string;
var
  LWriter: TStringWriter;
begin
  if not Assigned(AJSONValue) then
    Exit('');

  LWriter := TStringWriter.Create;
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty{$IFDEF HAS_TOJSON_OPTIONS}, OUTPUT_DEFAULT{$ENDIF});
    Result := LWriter.ToString;
  finally
    LWriter.Free;
  end;
end;

{$IFDEF HAS_TOJSON_OPTIONS}
class function TNeon.Print(AJSONValue: TJSONValue; APretty: Boolean; AOutputOptions: TJSONAncestor.TJSONOutputOptions): string;
var
  LWriter: TStringWriter;
begin
  if not Assigned(AJSONValue) then
    Exit('');

  LWriter := TStringWriter.Create;
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty, AOutputOptions);
    Result := LWriter.ToString;
  finally
    LWriter.Free;
  end;
end;
{$ENDIF}

class procedure TNeon.PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean);
var
  LWriter: TStreamWriter;
begin
  if not Assigned(AJSONValue) then
    Exit;

  LWriter := TStreamWriter.Create(AStream);
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty{$IFDEF HAS_TOJSON_OPTIONS}, OUTPUT_DEFAULT{$ENDIF});
  finally
    LWriter.Free;
  end;
end;

{$IFDEF HAS_TOJSON_OPTIONS}
class procedure TNeon.PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean; AOutputOptions: TJSONAncestor.TJSONOutputOptions);
var
  LWriter: TStreamWriter;
begin
  if not Assigned(AJSONValue) then
    Exit;

  LWriter := TStreamWriter.Create(AStream);
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty, AOutputOptions);
  finally
    LWriter.Free;
  end;
end;
{$ENDIF}

class procedure TNeon.PrintToWriter(AJSONValue: TJSONValue; AWriter: TTextWriter; APretty: Boolean
  {$IFDEF HAS_TOJSON_OPTIONS}; AOutputOptions: TJSONAncestor.TJSONOutputOptions{$ENDIF});
var
  LJSONString: string;
begin
{$IFDEF HAS_TOJSON}
  {$IFDEF HAS_TOJSON_OPTIONS}
  LJSONString := AJSONValue.ToJSON(AOutputOptions);
  {$ELSE}
  LJSONString := AJSONValue.ToJSON;
  {$ENDIF}
{$ELSE}
  LJSONString := AJSONValue.ToString;
{$ENDIF}
  if not APretty then
  begin
    AWriter.Write(LJSONString);
    Exit;
  end;

  TJSONUtils.Prettify(LJSONString, AWriter);
end;

class function TNeon.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  Result := TNeon.ValueToJSON(AValue, TNeonConfiguration.Default);
end;

class function TNeon.ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ValueToJSON(AValue);
  finally
    LWriter.Free;
  end;
end;

class function TNeon.ValueToJSONString(const AValue: TValue; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := ValueToJSON(AValue, AConfig);
  try
    Result := Print(LJSON, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.ValueToJSONString(const AValue: TValue): string;
begin
  Result := ValueToJSONString(AValue, TNeonConfiguration.Default);
end;

class procedure TNeon.ValueToStream(const AValue: TValue; AStream: TStream);
begin
  ValueToStream(AValue, AStream, TNeonConfiguration.Default);
end;

class procedure TNeon.ValueToStream(const AValue: TValue; AStream: TStream; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ValueToJSON(AValue, AConfig);
  try
    PrintToStream(LJSON, AStream, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class procedure TNeon.JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration);
var
  LReader: TNeonDeserializerJSON;
begin
  LReader := TNeonDeserializerJSON.Create(AConfig);
  try
    LReader.JSONToObject(AObject, AJSON);
  finally
    LReader.Free;
  end;
end;

class function TNeon.JSONToValue<T>(const AJSON: string): T;
begin
  Result := JSONToValue<T>(AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToValue<T>(const AJSON: string; const AConfig: INeonConfiguration): T;
var
  LJSON: TJSONValue;
begin
  LJSON := ParseJSON(AJSON, False, True);
  try
    Result := JSONToValue<T>(LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject;
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ParseJSON(AJSON, False, True);
  try
    Result := TRttiUtils.CreateInstance(AType);
    JSONToObject(Result, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class procedure TNeon.JSONToObject(AObject: TObject; const AJSON: string);
begin
  JSONToObject(AObject, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToObject<T>(const AJSON: string; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TValue;
var
  LDes: TNeonDeserializerJSON;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    Result := LDes.JSONToTValue(AJSON, ARttiType);
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue;
begin
  Result := JSONToValue(ARttiType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
var
  LDes: TNeonDeserializerJSON;
  LValue: TValue;
  LType: TRttiType;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    LType := TRttiUtils.Context.GetType(TypeInfo(T));
    if not Assigned(LType) then
      raise ENeonException.Create(SNeonErrorEmptyType);

    case LType.TypeKind of
      tkArray, tkRecord, tkDynArray: TValue.Make(nil, TypeInfo(T), LValue);
    else
      LValue := TValue.Empty;
    end;
    LValue := LDes.JSONToTValue(AJSON, LType, LValue);
    Result := LValue.AsType<T>;
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToValue<T>(AJSON, TNeonConfiguration.Default);
end;

class function TNeon.ParseJSON(const Data: string; UseBool, RaiseExc: Boolean): TJSONValue;
begin
{$IFDEF HAS_NEW_JSON}
  Result := TJSONObject.ParseJSONValue(Data, UseBool, RaiseExc);
{$ELSE}
  {$IFDEF HAS_JSON_BOOL}
    Result := TJSONObject.ParseJSONValue(Data, UseBool);
  {$ELSE}
    Result := TJSONObject.ParseJSONValue(Data);
  {$ENDIF}
    if RaiseExc and not Assigned(Result) then
      raise ENeonException.Create(SNeonErrorParse);
{$ENDIF}
end;

{ TNeonDeserializerParam }

procedure TNeonDeserializerParam.Default;
begin
  JSONValue := nil;
  RttiType := nil;
  NeonObject := nil;
end;

end.
