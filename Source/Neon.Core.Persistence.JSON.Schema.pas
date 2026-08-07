{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Persistence.JSON.Schema;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.JSON, Data.DB,

  Neon.Core.Tags,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.TypeInfo,
  Neon.Core.Utils;

type
  JsonSchemaAttribute = class(TCustomAttribute)
  private
    FTagString: string;
    FTags: TAttributeTags;
  public
    constructor Create(const ATagString: string);
    destructor Destroy; override;

    procedure ParseTags();

    property TagString: string read FTagString write FTagString;
    property Tags: TAttributeTags read FTags write FTags;
  end;

  /// <summary>
  ///   JSON Schema generator
  ///   JSON Schema version supported: Draft 2020-12
  /// </summary>
  TNeonSchemaGenerator = class(TNeonBase)
  private
    /// <summary>
    ///   Types currently being expanded on the current recursion path (added
    ///   before recursing into a class/record's members, removed after) so a
    ///   self-referencing Delphi type raises a clear error instead of a stack
    ///   overflow
    /// </summary>
    FVisitedTypes: TDictionary<PTypeInfo, Boolean>;

    /// <summary>
    ///   The "$schema" meta-schema URI for the given draft
    /// </summary>
    class function SchemaURIFor(AVersion: TNeonJSchemaVersion): string; static;
  protected
    /// <summary>
    ///   Returns the schema's own scalar JSON type ('string'/'number'/'integer'/
    ///   'boolean'), looking through a Nullable-style ["X","null"] type array
    /// </summary>
    function GetPrimaryJSONType(AJSON: TJSONObject): string;

    /// <summary>
    ///   Converts a JsonSchema tag value to a JSON value of the appropriate
    ///   kind (number/integer/boolean/string) based on AJSONType
    /// </summary>
    function TagValueToJSON(ATags: TAttributeTags; const AName, AJSONType: string): TJSONValue;

    /// <summary>
    ///   Writer for members of objects and records
    /// </summary>
    function WriteMembers(AType: TRttiType; AResult: TJSONObject): TJSONArray;

    /// <summary>
    ///   Writer for string types
    /// </summary>
    function WriteString(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Boolean types
    /// </summary>
    function WriteBoolean(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for enums types <br />
    /// </summary>
    function WriteEnum(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInteger(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInt64(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for float types
    /// </summary>
    function WriteFloat(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDouble(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TDate* types
    /// </summary>
    function WriteDate(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDateTime(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDynArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObjectOrRecord(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Exception (descendants) objects
    /// </summary>
    function WriteException(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TStream (descendants) objects
    /// </summary>
    function WriteStream(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TDataSet (descendants) objects
    /// </summary>
    function WriteDataSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TJSONValue (descendants) objects
    /// </summary>
    function WriteJSONValue(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(AType: TRttiType; ANeonObject: TNeonRttiObject; AList: INeonTypeInfoList): TJSONObject;
    function IsEnumerable(AType: TRttiType; out AList: INeonTypeInfoList): Boolean;

    /// <summary>
    ///   Writer for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerableMap(AType: TRttiType; ANeonObject: TNeonRttiObject; AMap: INeonTypeInfoMap): TJSONObject;
    function IsEnumerableMap(AType: TRttiType; out AMap: INeonTypeInfoMap): Boolean;

    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(AType: TRttiType; ANeonObject: TNeonRttiObject; AStream: INeonTypeInfoStream): TJSONObject;
    function IsStreamable(AType: TRttiType; out AStream: INeonTypeInfoStream): Boolean;

    /// <summary>
    ///   Writer for "Nullable" records
    /// </summary>
    /// <remarks>
    ///   Record must have HasValue and GetValue methods
    /// </remarks>
    function WriteNullable(AType: TRttiType; ANeonObject: TNeonRttiObject; ANullable: INeonTypeInfoNullable): TJSONObject;
    function IsNullable(AType: TRttiType; out ANullable: INeonTypeInfoNullable): Boolean;

    /// <summary>
    ///   Function to be called by a custom serializer method (ISerializeContext)
    /// </summary>
    function WriteDataMember(AType: TRttiType): TJSONObject; overload;

    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; overload;

    /// <summary>
    ///   True if the member's JsonSchema attribute carries the "required" tag
    /// </summary>
    /// <remarks>
    ///   "required" is a keyword of the *parent* schema (an array of member
    ///   names), so it is read straight from the attribute by WriteMembers and
    ///   never written into the member's own schema
    /// </remarks>
    function IsMemberRequired(ANeonObject: TNeonRttiObject): Boolean;

    /// <summary>
    ///   This method sets additional schema properties (based on JsonSchema
    ///   attribute). Does nothing if AJSON is nil, which happens for the type
    ///   kinds whose writers produce no schema at all (interfaces, variants, ...)
    /// </summary>
    procedure SetSchemaProperties(AJSON: TJSONObject; ANeonObject: TNeonRttiObject);
  public
    constructor Create(const AConfig: INeonConfiguration);
    destructor Destroy; override;

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TRttiType.
    ///   AVersion selects the "$schema" URI written into the root of the result (default: None).
    ///   If AVersion is None the function produces a JSON-Schema Fragment.
    /// </summary>
    class function TypeToJSONSchema(AType: TRttiType; AVersion: TNeonJSchemaVersion = TNeonJSchemaVersion.None): TJSONObject; overload;
    class function TypeToJSONSchema(AType: TRttiType; AConfig: INeonConfiguration; AVersion: TNeonJSchemaVersion = TNeonJSchemaVersion.None): TJSONObject; overload;

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TRttiType.
    ///   AVersion selects the "$schema" URI written into the root of the result (default: None).
    ///   If AVersion is None the function produces a JSON-Schema Fragment.
    /// </summary>
    class function ClassToJSONSchema(AClass: TClass; AVersion: TNeonJSchemaVersion = TNeonJSchemaVersion.None): TJSONObject; overload;
    class function ClassToJSONSchema(AClass: TClass; AConfig: INeonConfiguration; AVersion: TNeonJSchemaVersion = TNeonJSchemaVersion.None): TJSONObject; overload;
  end;

  /// <summary>
  ///   One JSON Schema validation failure
  /// </summary>
  TJSONValidationError = record
  public
    /// <summary>
    ///   JSON Pointer into the INSTANCE data being validated (not the schema),
    ///   e.g. /items/3/name
    /// </summary>
    Path: string;
    /// <summary>
    ///   The JSON Schema keyword that failed, e.g. 'minLength', 'required', 'type'
    /// </summary>
    Keyword: string;
    Message: string;
    constructor Create(const APath, AKeyword, AMessage: string);
  end;

  /// <summary>
  ///   The outcome of validating one JSON instance against a schema: every
  ///   violation found (not just the first), unless StopOnFirstError is set
  /// </summary>
  TJSONValidationResult = record
  public
    IsValid: Boolean;
    Errors: TArray<TJSONValidationError>;
  end;

  /// <summary>
  ///   Validates a TJSONValue instance against a JSON Schema (Draft 2020-12)
  ///   document, expressed directly as a TJSONObject/TJSONValue - no separate
  ///   strongly-typed schema class is needed since TJSONObject already is a
  ///   generic JSON tree.
  /// </summary>
  /// <remarks>
  ///   v1 scope: $ref/$defs and $anchor are resolved locally (same document)
  ///   only; a $ref to another document is unsupported. allOf/anyOf/oneOf/not,
  ///   if/then/else and dependentRequired are implemented; dependentSchemas and
  ///   unevaluatedProperties/unevaluatedItems are not yet (the latter need the
  ///   annotation-tracking machinery, planned separately). format is
  ///   annotation-only (never validated) in v1.
  /// </remarks>
  TJSONSchemaValidator = class
  private
  type
    /// <summary>
    ///   One (schema, instance) pair currently being evaluated through a $ref
    /// </summary>
    TRefFrame = record
      Schema: TJSONValue;
      Instance: TJSONValue;
    end;
  private
    FRoot: TJSONValue;
    FAnchors: TDictionary<string, TJSONValue>;
    FStopOnFirstError: Boolean;

    /// <summary>
    ///   The $ref frames on the current evaluation path, used to break
    ///   non-productive reference cycles (see IsRefFrameActive)
    /// </summary>
    FRefStack: TList<TRefFrame>;

    procedure CollectAnchors(ASchema: TJSONValue);
    function NavigatePointer(const APointer: string): TJSONValue;
    function ResolveRef(const ARef: string): TJSONValue;

    /// <summary>
    ///   True if this exact schema is already being evaluated against this
    ///   exact instance further up the call stack
    /// </summary>
    function IsRefFrameActive(ASchema, AInstance: TJSONValue): Boolean;

    procedure AddError(AErrors: TList<TJSONValidationError>; const APath, AKeyword, AMessage: string);
    function ShouldStop(AErrors: TList<TJSONValidationError>; ABaseline: Integer): Boolean;

    function JSONTypeName(AInstance: TJSONValue): string;
    function InstanceMatchesType(AInstance: TJSONValue; const AType: string): Boolean;
    function InstanceMatchesAnyType(AInstance: TJSONValue; ASchema: TJSONObject): Boolean;
    function JSONValuesEqual(AValue1, AValue2: TJSONValue): Boolean;
    function AsNumber(AInstance: TJSONValue; out AValue: Double): Boolean;
    function CodepointLength(const AValue: string): Integer;

    function ValidateNode(AInstance: TJSONValue; ASchema: TJSONValue; const APath: string; AErrors: TList<TJSONValidationError>): Boolean;
    procedure ValidateNumeric(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
    procedure ValidateString(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
    procedure ValidateArray(AInstance: TJSONArray; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
    procedure ValidateObject(AInstance: TJSONObject; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
    function ValidateLogic(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>): Boolean;
  public
    constructor Create(ARootSchema: TJSONValue);
    destructor Destroy; override;

    function Validate(AInstance: TJSONValue): TJSONValidationResult;

    /// <summary>
    ///   When True, Validate stops at the first violation found (Errors will
    ///   have at most one element). Default False: collect every violation.
    /// </summary>
    property StopOnFirstError: Boolean read FStopOnFirstError write FStopOnFirstError;
  end;

  TNeonHelper = class helper for TNeon
  public
    class function ValidateJSON(AJSON: TJSONValue; ASchema: TJSONValue): TJSONValidationResult;
  end;

implementation

uses
  System.RegularExpressions,
  System.Variants;

{ TNeonSchemaGenerator }

class function TNeonSchemaGenerator.ClassToJSONSchema(AClass: TClass; AVersion: TNeonJSchemaVersion): TJSONObject;
begin
  Result := TypeToJSONSchema(TRttiUtils.Context.GetType(AClass), TNeonConfiguration.Default, AVersion);
end;

class function TNeonSchemaGenerator.ClassToJSONSchema(AClass: TClass; AConfig: INeonConfiguration; AVersion: TNeonJSchemaVersion): TJSONObject;
begin
  Result := TypeToJSONSchema(TRttiUtils.Context.GetType(AClass), AConfig, AVersion);
end;

constructor TNeonSchemaGenerator.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
  FVisitedTypes := TDictionary<PTypeInfo, Boolean>.Create;
end;

destructor TNeonSchemaGenerator.Destroy;
begin
  FVisitedTypes.Free;
  inherited;
end;

function TNeonSchemaGenerator.GetPrimaryJSONType(AJSON: TJSONObject): string;
var
  LTypeValue: TJSONValue;
  LItem: TJSONValue;
begin
  Result := '';
  LTypeValue := AJSON.GetValue('type');
  if not Assigned(LTypeValue) then
    Exit;

  if LTypeValue is TJSONArray then
  begin
    for LItem in (LTypeValue as TJSONArray) do
      if LItem.Value <> 'null' then
        Exit(LItem.Value);
  end
  else
    Result := LTypeValue.Value;
end;

function TNeonSchemaGenerator.TagValueToJSON(ATags: TAttributeTags; const AName, AJSONType: string): TJSONValue;
begin
  // Only scalar (string/number/integer/boolean) values are supported; an array/object
  // "default"/"const"/"examples" would need embedded JSON syntax in the tag string,
  // which the flat key=value tag format does not support

  if AJSONType = 'integer' then
    Result := TJSONNumber.Create(ATags.GetValueAs<Int64>(AName))
  else if AJSONType = 'number' then
    Result := TJSONNumber.Create(ATags.GetValueAs<Double>(AName))
  else if AJSONType = 'boolean' then
    Result := TJSONBool.Create(ATags.GetValueAs<Boolean>(AName))
  else
    Result := TJSONString.Create(ATags.GetValueAs<string>(AName));
end;

function TNeonSchemaGenerator.IsEnumerable(AType: TRttiType; out AList: INeonTypeInfoList): Boolean;
begin
  AList := TNeonTypeInfoList.GuessType(AType);
  Result := Assigned(AList);
end;

function TNeonSchemaGenerator.IsEnumerableMap(AType: TRttiType; out AMap: INeonTypeInfoMap): Boolean;
begin
  AMap := TNeonTypeInfoMap.GuessType(AType);
  Result := Assigned(AMap);
end;

function TNeonSchemaGenerator.IsMemberRequired(ANeonObject: TNeonRttiObject): Boolean;
var
  LSchema: JsonSchemaAttribute;
begin
  Result := False;

  LSchema := TRttiUtils.FindAttribute<JsonSchemaAttribute>(ANeonObject.Attributes);
  if not Assigned(LSchema) then
    Exit;

  LSchema.ParseTags;
  Result := LSchema.Tags.Exists('required');
end;

function TNeonSchemaGenerator.IsNullable(AType: TRttiType; out ANullable: INeonTypeInfoNullable): Boolean;
begin
  ANullable := TNeonTypeInfoNullable.GuessType(AType);
  Result := Assigned(ANullable);
end;

function TNeonSchemaGenerator.IsStreamable(AType: TRttiType; out AStream: INeonTypeInfoStream): Boolean;
begin
  AStream := TNeonTypeInfoStream.GuessType(AType);
  Result := Assigned(AStream);
end;

procedure TNeonSchemaGenerator.SetSchemaProperties(AJSON: TJSONObject; ANeonObject: TNeonRttiObject);
var
  LSchema: JsonSchemaAttribute;
  LTags: TAttributeTags;
  LJSONType: string;
  LExamples: TJSONArray;
begin
  // The writers for interfaces and variants produce no schema at all, so an
  // attribute on such a type has nothing to annotate
  if not Assigned(AJSON) then
    Exit;

  LSchema := TRttiUtils.FindAttribute<JsonSchemaAttribute>(ANeonObject.Attributes);
  if not Assigned(LSchema) then
    Exit;

  LSchema.ParseTags;
  LTags := LSchema.Tags;
  LJSONType := GetPrimaryJSONType(AJSON);

  // Metadata
  if LTags.Exists('title') then
    AJSON.AddPair('title', LTags.GetValueAs<string>('title'));

  if LTags.Exists('description') then
    AJSON.AddPair('description', LTags.GetValueAs<string>('description'));

  if LTags.Exists('deprecated') then
    AJSON.AddPair('deprecated', TJSONBool.Create(True));

  if LTags.Exists('default') then
    AJSON.AddPair('default', TagValueToJSON(LTags, 'default', LJSONType));

  if LTags.Exists('const') then
    AJSON.AddPair('const', TagValueToJSON(LTags, 'const', LJSONType));

  if LTags.Exists('examples') then
  begin
    LExamples := TJSONArray.Create;
    LExamples.AddElement(TagValueToJSON(LTags, 'examples', LJSONType));
    AJSON.AddPair('examples', LExamples);
  end;

  // Note: the "required" tag is deliberately not written here. It belongs to the
  // parent schema, and WriteMembers reads it from the attribute (IsMemberRequired).
  // Emitting it as a member-level boolean would collide with the "required" array
  // an object/record member gets from its own members

  if LTags.Exists('readOnly') then
    AJSON.AddPair('readOnly', TJSONBool.Create(True));

  // Numeric constraints
  if LTags.Exists('minimum') then
    AJSON.AddPair('minimum', TJSONNumber.Create(LTags.GetValueAs<Double>('minimum')));

  if LTags.Exists('maximum') then
    AJSON.AddPair('maximum', TJSONNumber.Create(LTags.GetValueAs<Double>('maximum')));

  if LTags.Exists('exclusiveMinimum') then
    AJSON.AddPair('exclusiveMinimum', TJSONNumber.Create(LTags.GetValueAs<Double>('exclusiveMinimum')));

  if LTags.Exists('exclusiveMaximum') then
    AJSON.AddPair('exclusiveMaximum', TJSONNumber.Create(LTags.GetValueAs<Double>('exclusiveMaximum')));

  if LTags.Exists('multipleOf') then
    AJSON.AddPair('multipleOf', TJSONNumber.Create(LTags.GetValueAs<Double>('multipleOf')));

  // String constraints
  if LTags.Exists('minLength') then
    AJSON.AddPair('minLength', TJSONNumber.Create(LTags.GetValueAs<Integer>('minLength')));

  if LTags.Exists('maxLength') then
    AJSON.AddPair('maxLength', TJSONNumber.Create(LTags.GetValueAs<Integer>('maxLength')));

  if LTags.Exists('pattern') then
    AJSON.AddPair('pattern', LTags.GetValueAs<string>('pattern'));

  // Array constraints
  if LTags.Exists('minItems') then
    AJSON.AddPair('minItems', TJSONNumber.Create(LTags.GetValueAs<Integer>('minItems')));

  if LTags.Exists('maxItems') then
    AJSON.AddPair('maxItems', TJSONNumber.Create(LTags.GetValueAs<Integer>('maxItems')));

  if LTags.Exists('uniqueItems') then
    AJSON.AddPair('uniqueItems', TJSONBool.Create(True));

  // Object constraints
  if LTags.Exists('minProperties') then
    AJSON.AddPair('minProperties', TJSONNumber.Create(LTags.GetValueAs<Integer>('minProperties')));

  if LTags.Exists('maxProperties') then
    AJSON.AddPair('maxProperties', TJSONNumber.Create(LTags.GetValueAs<Integer>('maxProperties')));
end;

class function TNeonSchemaGenerator.SchemaURIFor(AVersion: TNeonJSchemaVersion): string;
begin
  case AVersion of
    TNeonJSchemaVersion.Draft07: Result := 'http://json-schema.org/draft-07/schema#';
    TNeonJSchemaVersion.v202012: Result := 'https://json-schema.org/draft/2020-12/schema';
  else
    Result := '';
  end;
end;

class function TNeonSchemaGenerator.TypeToJSONSchema(AType: TRttiType; AConfig: INeonConfiguration; AVersion: TNeonJSchemaVersion): TJSONObject;
var
  LGenerator: TNeonSchemaGenerator;
begin
  LGenerator := TNeonSchemaGenerator.Create(AConfig);
  try
    Result := LGenerator.WriteDataMember(AType);
    if Assigned(Result) then
      if (AVersion <> TNeonJSchemaVersion.None) then
        Result.AddPair('$schema', SchemaURIFor(AVersion));
  finally
    LGenerator.Free;
  end;
end;

class function TNeonSchemaGenerator.TypeToJSONSchema(AType: TRttiType; AVersion: TNeonJSchemaVersion): TJSONObject;
begin
  Result := TypeToJSONSchema(AType, TNeonConfiguration.Default, AVersion);
end;

function TNeonSchemaGenerator.WriteArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LItems: TJSONObject;
begin
  LItems := WriteDataMember((AType as TRttiArrayType).ElementType);
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LItems)
end;

function TNeonSchemaGenerator.WriteBoolean(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'boolean');
end;

function TNeonSchemaGenerator.WriteDataMember(AType: TRttiType): TJSONObject;
var
  LNeonObject: TNeonRttiObject;
begin
  LNeonObject := TNeonRttiObject.Create(AType, FOperation);
  LNeonObject.ParseAttributes;
  try
    Result := WriteDataMember(AType, LNeonObject);
  finally
    LNeonObject.Free;
  end;
end;

function TNeonSchemaGenerator.WriteDataMember(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LNeonTypeInfo: INeonTypeInfo;

  LNeonMap: INeonTypeInfoMap absolute LNeonTypeInfo;
  LNeonList: INeonTypeInfoList absolute LNeonTypeInfo;
  LNeonStream: INeonTypeInfoStream absolute LNeonTypeInfo;
  LNeonNullable: INeonTypeInfoNullable absolute LNeonTypeInfo;
begin
  Result := nil;

  case AType.TypeKind of
    tkChar,
    tkWChar,
    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AType, ANeonObject);
    end;

    tkEnumeration:
    begin
      if AType.Handle = System.TypeInfo(Boolean) then
        Result := WriteBoolean(AType, ANeonObject)
      else
        Result := WriteEnum(AType, ANeonObject);
    end;

    tkInteger:
    begin
      Result := WriteInteger(AType, ANeonObject);
    end;

    tkInt64:
    begin
      Result := WriteInt64(AType, ANeonObject);
    end;

    tkFloat:
    begin
      if AType.Handle = TypeInfo(Single) then
        Result := WriteFloat(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TDateTime) then
        Result := WriteDateTime(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TTime) then
        Result := WriteDateTime(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TDate) then
        Result := WriteDate(AType, ANeonObject)
      else
        Result := WriteDouble(AType, ANeonObject);
    end;

    tkClass:
    begin
      // Add the class to the RefTypes
      if AType.AsInstance.MetaclassType.InheritsFrom(TJSONValue) then
        Result := WriteJSONValue(AType, ANeonObject)
      else if AType.AsInstance.MetaclassType.InheritsFrom(TDataSet) then
        Result := WriteDataSet(AType, ANeonObject)
      else if AType.AsInstance.MetaclassType.InheritsFrom(TStream) then
        Result := WriteStream(AType, ANeonObject)
      else if IsEnumerableMap(AType, LNeonMap) then
        Result := WriteEnumerableMap(AType, ANeonObject, LNeonMap)
      else if IsEnumerable(AType, LNeonList) then
        Result := WriteEnumerable(AType, ANeonObject, LNeonList)
      else if IsStreamable(AType, LNeonStream) then
        Result := WriteStreamable(AType, ANeonObject, LNeonStream)
      else
        Result := WriteObjectOrRecord(AType, ANeonObject);
    end;

    tkArray:
    begin
      Result := WriteArray(AType, ANeonObject);
    end;

    tkDynArray:
    begin
      Result := WriteDynArray(AType, ANeonObject);
    end;

    tkSet:
    begin
      Result := WriteSet(AType, ANeonObject);
    end;

     tkRecord{$IFDEF HAS_MRECORDS}, tkMRecord{$ENDIF}:
    begin
      { TODO -opaolo -c : TValue 21/09/2025 18:59:13 }

      if IsNullable(AType, LNeonNullable) then
        Result := WriteNullable(AType, ANeonObject, LNeonNullable)
      else
        Result := WriteObjectOrRecord(AType, ANeonObject);
    end;

    tkInterface:
    begin
      Result := WriteInterface(AType, ANeonObject);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AType, ANeonObject);
    end;

  end;

  SetSchemaProperties(Result, ANeonObject);
end;

function TNeonSchemaGenerator.WriteDataSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  // TDataSetSerializer writes a dataset as an array of row objects. The shape of
  // a row comes from the field definitions, which only exist on a live instance
  // (see TDataSetUtils.RecordToJSONSchema) - unavailable to a type-only schema
  // generator - so the row itself is left unconstrained
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', TJSONObject.Create.AddPair('type', 'object'));
end;

function TNeonSchemaGenerator.WriteDate(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'date');
end;

function TNeonSchemaGenerator.WriteDateTime(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'date-time');
end;

function TNeonSchemaGenerator.WriteDouble(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'number')
    .AddPair('format', 'double');
end;

function TNeonSchemaGenerator.WriteDynArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LItems: TJSONObject;
begin
  LItems := WriteDataMember((AType as TRttiDynamicArrayType).ElementType);
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LItems)
end;

function TNeonSchemaGenerator.WriteEnum(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LTypeData: PTypeData;
  LIndex: Integer;
  LEnumArray: TJSONArray;
begin
  LTypeData := GetTypeData(AType.Handle);
  LEnumArray := TJSONArray.Create;

  // Must mirror TNeonSerializerJSON.WriteEnum: the ordinal is written when the
  // configuration asks for it, the enum name otherwise
  if FConfig.EnumAsInt then
  begin
    for LIndex := LTypeData.MinValue to LTypeData.MaxValue do
      LEnumArray.AddElement(TJSONNumber.Create(LIndex));

    Result := TJSONObject.Create
      .AddPair('type', 'integer')
      .AddPair('enum', LEnumArray);
  end
  else
  begin
    for LIndex := LTypeData.MinValue to LTypeData.MaxValue do
      LEnumArray.Add(TTypeInfoUtils.EnumToString(AType.Handle, LIndex));

    Result := TJSONObject.Create
      .AddPair('type', 'string')
      .AddPair('enum', LEnumArray);
  end;
end;

function TNeonSchemaGenerator.WriteFloat(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'number')
    .AddPair('format', 'float');
end;

function TNeonSchemaGenerator.WriteInt64(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'integer')
    .AddPair('format', 'int64');
end;

function TNeonSchemaGenerator.WriteInteger(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'integer')
    .AddPair('format', 'int32');
end;

function TNeonSchemaGenerator.WriteInterface(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := nil;
end;

function TNeonSchemaGenerator.WriteJSONValue(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LClass: TClass;
begin
  LClass := AType.AsInstance.MetaclassType;

  // Tested by inheritance, not by class identity, so that a descendant (or a
  // member merely declared as TJSONValue) is described instead of dropped.
  // TJSONNumber descends from TJSONString in the RTL, hence the order here
  if LClass.InheritsFrom(TJSONNumber) then
    Exit(TJSONObject.Create
      .AddPair('type', 'number')
      .AddPair('format', 'float'));

  if LClass.InheritsFrom(TJSONString) then
    Exit(TJSONObject.Create
      .AddPair('type', 'string'));

  if LClass.InheritsFrom(TJSONBool) then
    Exit(TJSONObject.Create
      .AddPair('type', 'boolean'));

  if LClass.InheritsFrom(TJSONNull) then
    Exit(TJSONObject.Create
      .AddPair('type', 'null'));

  if LClass.InheritsFrom(TJSONObject) then
    Exit(TJSONObject.Create
      .AddPair('type', 'object')
      .AddPair('additionalProperties', TJSONObject.Create));

  if LClass.InheritsFrom(TJSONArray) then
    Exit(TJSONObject.Create
      .AddPair('type', 'array')
      .AddPair('items', TJSONObject.Create));

  // TJSONValue itself: any JSON value at all, which an empty schema states
  Result := TJSONObject.Create;
end;

function TNeonSchemaGenerator.WriteMembers(AType: TRttiType; AResult: TJSONObject): TJSONArray;
var
  LJSONObj: TJSONObject;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LNeonName: string;
begin
  Result := nil;
  LMembers := GetNeonMembers(AType);
  LMembers.FilterSerialize(nil);

  for LNeonMember in LMembers do
  begin
    if LNeonMember.Serializable then
    begin
      LJSONObj := nil;
      try
        try
          LJSONObj := WriteDataMember(LNeonMember.RttiType, LNeonMember);
          if Assigned(LJSONObj) then
          begin
            LNeonName := GetNameFromMember(LNeonMember);

            if IsMemberRequired(LNeonMember) then
            begin
              if not Assigned(Result) then
                Result := TJSONArray.Create;
              Result.Add(LNeonName);
            end;

            AResult.AddPair(LNeonName, LJSONObj);
            LJSONObj := nil; // ownership passed to AResult
          end;
        except
          on E: ENeonException do
            raise; // e.g. a genuine recursive-type cycle - a real error, not a per-property fluke
          on E: Exception do
            LogError(Format(SNeonErrorConvertPropF2,
              [LNeonMember.Name, AType.Name]));
        end;
      finally
        LJSONObj.Free; // only reached when the member was not added
      end;
    end;
  end;
end;

function TNeonSchemaGenerator.WriteNullable(AType: TRttiType; ANeonObject: TNeonRttiObject; ANullable: INeonTypeInfoNullable): TJSONObject;
var
  LTypePair: TJSONPair;
  LTypeArray: TJSONArray;
  LItem: TJSONValue;
begin
  Result := nil;
  if not Assigned(ANullable) then
    Exit;

  Result := WriteDataMember(ANullable.GetBaseType);
  if not Assigned(Result) then
    Exit;

  // Reflect that the value may be absent: fold the base type's "type" into a
  // ["<base type(s)>", "null"] union (matches how jsonschema-go's inference
  // wraps a Go pointer type). Note: if the base schema also has "enum", the
  // enum array itself would still need "null" added for full correctness -
  // a known limitation, not addressed here.
  LTypePair := Result.RemovePair('type');
  if not Assigned(LTypePair) then
    Exit;

  try
    LTypeArray := TJSONArray.Create;
    if LTypePair.JsonValue is TJSONArray then
    begin
      for LItem in (LTypePair.JsonValue as TJSONArray) do
        LTypeArray.Add(LItem.Value);
    end
    else
      LTypeArray.Add(LTypePair.JsonValue.Value);

    LTypeArray.Add('null');
    Result.AddPair('type', LTypeArray);
  finally
    LTypePair.Free;
  end;
end;

function TNeonSchemaGenerator.WriteObjectOrRecord(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LProperties: TJSONObject;
  LRequired: TJSONArray;
begin
  if FVisitedTypes.ContainsKey(AType.Handle) then
    raise ENeonException.CreateFmt(SNeonErrorSchemaCycleF1, [AType.Name]);

  FVisitedTypes.Add(AType.Handle, True);
  try
    LProperties := TJSONObject.Create;

    LRequired := WriteMembers(AType, LProperties);

    Result := TJSONObject.Create
      .AddPair('type', 'object')
      .AddPair('properties', LProperties);

    if Assigned(LRequired) then
      Result.AddPair('required', LRequired);
  finally
    FVisitedTypes.Remove(AType.Handle);
  end;
end;

function TNeonSchemaGenerator.WriteEnumerable(AType: TRttiType; ANeonObject: TNeonRttiObject; AList: INeonTypeInfoList): TJSONObject;
var
  LJSONItems: TJSONObject;
begin
  // Is not an Enumerable compatible object
  if not Assigned(AList) then
    Exit(nil);

  LJSONItems := WriteDataMember(AList.GetItemType);

  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LJSONItems);
end;

function TNeonSchemaGenerator.WriteEnumerableMap(AType: TRttiType; ANeonObject: TNeonRttiObject; AMap: INeonTypeInfoMap): TJSONObject;
var
  LValueJSON: TJSONObject;
begin
  // Is not an EnumerableMap-compatible object
  if not Assigned(AMap) then
    Exit(nil);

  LValueJSON := WriteDataMember(AMap.GetValueType);
  Result := TJSONObject.Create
    .AddPair('type', 'object')
    .AddPair('additionalProperties', LValueJSON);
end;

function TNeonSchemaGenerator.WriteException(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LProps: TJSONObject;
  LInner: TJSONObject;
begin
  //Result := WriteObject(AType, ANeonObject);

  Result := TJSONObject.Create;

  LProps := TJSONObject.Create
      .AddPair('message', 'string')
      .AddPair('error', 'string');

  LInner := TJSONObject.Create
      .AddPair('type', 'object')
      .AddPair('properties', LProps);

  Result.AddPair('innerException', LInner);
end;

function TNeonSchemaGenerator.WriteSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LElementType: PPTypeInfo;
  LItems: TJSONObject;
begin
  // TNeonSerializerJSON.WriteSet writes one array element per member of the
  // set, each produced by the writer for the set's base type (so an enum
  // element follows the enum rules, name or ordinal)
  LItems := nil;

  LElementType := GetTypeData(AType.Handle)^.CompType;
  if (LElementType <> nil) and (LElementType^ <> nil) then
    LItems := WriteDataMember(TRttiUtils.Context.GetType(LElementType^));

  // No base type RTTI: the serializer falls back to writing the raw ordinals
  if not Assigned(LItems) then
    LItems := TJSONObject.Create.AddPair('type', 'integer');

  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LItems);
end;

function TNeonSchemaGenerator.WriteStream(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'byte');
end;

function TNeonSchemaGenerator.WriteStreamable(AType: TRttiType; ANeonObject: TNeonRttiObject; AStream: INeonTypeInfoStream): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'byte');
end;

function TNeonSchemaGenerator.WriteString(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  if ANeonObject.NeonRawValue then
    Exit(TJSONObject.Create);

  Result := TJSONObject.Create
    .AddPair('type', 'string');
end;

function TNeonSchemaGenerator.WriteVariant(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
{
  case ANeonObject.NeonInclude.Value of
    Include.NotNull:
    begin
      if VarIsNull(AValue.AsVariant) then
        Exit(nil);
    end;
    Include.NotEmpty:
    begin
      if VarIsEmpty(AValue.AsVariant) then
        Exit(nil);
    end;
  end;
}
  Result :=nil;
  //TJSONString.Create(AValue.AsVariant);
end;

{ JsonSchemaAttribute }

constructor JsonSchemaAttribute.Create(const ATagString: string);
begin
  FTagString := ATagString;
  FTags := TAttributeTags.Create();
end;

destructor JsonSchemaAttribute.Destroy;
begin
  FTags.Free;
  inherited;
end;

procedure JsonSchemaAttribute.ParseTags;
begin
  if FTags.Count = 0 then
    FTags.Parse(FTagString);
end;

{ TJSONValidationError }

constructor TJSONValidationError.Create(const APath, AKeyword, AMessage: string);
begin
  Path := APath;
  Keyword := AKeyword;
  Message := AMessage;
end;

{ TJSONSchemaValidator }

constructor TJSONSchemaValidator.Create(ARootSchema: TJSONValue);
begin
  FRoot := ARootSchema;
  FAnchors := TDictionary<string, TJSONValue>.Create;
  FRefStack := TList<TRefFrame>.Create;
  CollectAnchors(FRoot);
end;

destructor TJSONSchemaValidator.Destroy;
begin
  FRefStack.Free;
  FAnchors.Free;
  inherited;
end;

function TJSONSchemaValidator.IsRefFrameActive(ASchema, AInstance: TJSONValue): Boolean;
var
  LIndex: Integer;
begin
  // The stack is only as deep as the chain of $refs currently being followed,
  // so a linear scan is cheaper than hashing a composite key
  for LIndex := 0 to FRefStack.Count - 1 do
    if (FRefStack[LIndex].Schema = ASchema) and (FRefStack[LIndex].Instance = AInstance) then
      Exit(True);

  Result := False;
end;

procedure TJSONSchemaValidator.CollectAnchors(ASchema: TJSONValue);
var
  LObj: TJSONObject;
  LAnchor, LId, LItem: TJSONValue;
  LPair: TJSONPair;
begin
  // Subschemas live inside arrays as well as objects (allOf/anyOf/oneOf,
  // prefixItems, the Draft-07 tuple form of "items"), so array elements have
  // to be walked too or their anchors are unreachable
  if ASchema is TJSONArray then
  begin
    for LItem in (ASchema as TJSONArray) do
      CollectAnchors(LItem);
    Exit;
  end;

  if not (ASchema is TJSONObject) then
    Exit;

  LObj := ASchema as TJSONObject;

  LAnchor := LObj.GetValue('$anchor');
  if Assigned(LAnchor) and (LAnchor is TJSONString) then
    FAnchors.AddOrSetValue(LAnchor.Value, LObj);

  // Draft-07's equivalent of $anchor: a fragment-only "$id" (e.g. "$id": "#foo")
  LId := LObj.GetValue('$id');
  if Assigned(LId) and (LId is TJSONString) and LId.Value.StartsWith('#') and (LId.Value.Length > 1) then
    FAnchors.AddOrSetValue(LId.Value.Substring(1), LObj);

  for LPair in LObj do
  begin
    if LPair.JsonValue is TJSONObject then
      CollectAnchors(LPair.JsonValue as TJSONObject)
    else if LPair.JsonValue is TJSONArray then
      CollectAnchors(LPair.JsonValue as TJSONArray);
  end;
end;

function TJSONSchemaValidator.NavigatePointer(const APointer: string): TJSONValue;
var
  LSegments: TArray<string>;
  LSegment, LUnescaped: string;
  LCurrent: TJSONValue;
  LIndex: Integer;
begin
  if APointer = '' then
    Exit(FRoot);

  if not APointer.StartsWith('/') then
    Exit(nil);

  LSegments := APointer.Substring(1).Split(['/']);
  LCurrent := FRoot;
  for LSegment in LSegments do
  begin
    if not Assigned(LCurrent) then
      Exit(nil);

    LUnescaped := LSegment.Replace('~1', '/', [rfReplaceAll]).Replace('~0', '~', [rfReplaceAll]);

    if LCurrent is TJSONObject then
      LCurrent := (LCurrent as TJSONObject).GetValue(LUnescaped)
    else if LCurrent is TJSONArray then
    begin
      if TryStrToInt(LUnescaped, LIndex) and (LIndex >= 0) and (LIndex < (LCurrent as TJSONArray).Count) then
        LCurrent := (LCurrent as TJSONArray).Items[LIndex]
      else
        Exit(nil);
    end
    else
      Exit(nil);
  end;
  Result := LCurrent;
end;

function TJSONSchemaValidator.ResolveRef(const ARef: string): TJSONValue;
begin
  if (ARef = '') or (ARef = '#') then
    Exit(FRoot);

  if ARef.StartsWith('#/') then
  begin
    Result := NavigatePointer(ARef.Substring(1));
    if not Assigned(Result) then
      raise ENeonException.CreateFmt(SNeonErrorSchemaRefNotFoundF1, [ARef]);
    Exit;
  end;

  if ARef.StartsWith('#') then
  begin
    if not FAnchors.TryGetValue(ARef.Substring(1), Result) then
      raise ENeonException.CreateFmt(SNeonErrorSchemaRefNotFoundF1, [ARef]);
    Exit;
  end;

  raise ENeonException.CreateFmt(SNeonErrorSchemaRefUnsupportedF1, [ARef]);
end;

procedure TJSONSchemaValidator.AddError(AErrors: TList<TJSONValidationError>; const APath, AKeyword, AMessage: string);
begin
  AErrors.Add(TJSONValidationError.Create(APath, AKeyword, AMessage));
end;

function TJSONSchemaValidator.ShouldStop(AErrors: TList<TJSONValidationError>; ABaseline: Integer): Boolean;
begin
  Result := FStopOnFirstError and (AErrors.Count > ABaseline);
end;

function TJSONSchemaValidator.JSONTypeName(AInstance: TJSONValue): string;
begin
  if (not Assigned(AInstance)) or (AInstance is TJSONNull) then
    Result := 'null'
  else if AInstance is TJSONBool then
    Result := 'boolean'
  else if AInstance is TJSONObject then
    Result := 'object'
  else if AInstance is TJSONArray then
    Result := 'array'
  else if AInstance is TJSONNumber then
  begin
    if Frac((AInstance as TJSONNumber).AsDouble) = 0 then
      Result := 'integer'
    else
      Result := 'number';
  end
  else
    Result := 'string';
end;

function TJSONSchemaValidator.InstanceMatchesType(AInstance: TJSONValue; const AType: string): Boolean;
begin
  if AType = 'number' then
    // an integer-valued number still satisfies "number"
    Result := (AInstance is TJSONNumber)
  else if AType = 'integer' then
    Result := (AInstance is TJSONNumber) and (Frac((AInstance as TJSONNumber).AsDouble) = 0)
  else
    Result := JSONTypeName(AInstance) = AType;
end;

function TJSONSchemaValidator.InstanceMatchesAnyType(AInstance: TJSONValue; ASchema: TJSONObject): Boolean;
var
  LTypeValue: TJSONValue;
  LItem: TJSONValue;
begin
  LTypeValue := ASchema.GetValue('type');
  if not Assigned(LTypeValue) then
    Exit(True); // no "type" constraint

  if LTypeValue is TJSONArray then
  begin
    for LItem in (LTypeValue as TJSONArray) do
      if InstanceMatchesType(AInstance, LItem.Value) then
        Exit(True);
    Result := False;
  end
  else
    Result := InstanceMatchesType(AInstance, LTypeValue.Value);
end;

function TJSONSchemaValidator.JSONValuesEqual(AValue1, AValue2: TJSONValue): Boolean;
var
  LObj1, LObj2: TJSONObject;
  LArr1, LArr2: TJSONArray;
  LPair: TJSONPair;
  I: Integer;
begin
  if (not Assigned(AValue1)) or (not Assigned(AValue2)) then
    Exit(not Assigned(AValue1) and not Assigned(AValue2));

  if JSONTypeName(AValue1) <> JSONTypeName(AValue2) then
    // an integer-typed number can still equal a number-typed one (1 = 1.0)
    if not ((AValue1 is TJSONNumber) and (AValue2 is TJSONNumber)) then
      Exit(False);

  if AValue1 is TJSONNumber then
    Exit((AValue1 as TJSONNumber).AsDouble = (AValue2 as TJSONNumber).AsDouble);

  if AValue1 is TJSONString then
    Exit(AValue1.Value = AValue2.Value);

  if AValue1 is TJSONBool then
    Exit((AValue1 as TJSONBool).AsBoolean = (AValue2 as TJSONBool).AsBoolean);

  if AValue1 is TJSONNull then
    Exit(True);

  if AValue1 is TJSONArray then
  begin
    LArr1 := AValue1 as TJSONArray;
    LArr2 := AValue2 as TJSONArray;
    if LArr1.Count <> LArr2.Count then
      Exit(False);
    for I := 0 to LArr1.Count - 1 do
      if not JSONValuesEqual(LArr1.Items[I], LArr2.Items[I]) then
        Exit(False);
    Exit(True);
  end;

  if AValue1 is TJSONObject then
  begin
    LObj1 := AValue1 as TJSONObject;
    LObj2 := AValue2 as TJSONObject;
    if LObj1.Count <> LObj2.Count then
      Exit(False);
    for LPair in LObj1 do
      if not JSONValuesEqual(LPair.JsonValue, LObj2.GetValue(LPair.JsonString.Value)) then
        Exit(False);
    Exit(True);
  end;

  Result := False;
end;

function TJSONSchemaValidator.AsNumber(AInstance: TJSONValue; out AValue: Double): Boolean;
begin
  Result := AInstance is TJSONNumber;
  if Result then
    AValue := (AInstance as TJSONNumber).AsDouble;
end;

function TJSONSchemaValidator.CodepointLength(const AValue: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  I := 1;
  while I <= AValue.Length do
  begin
    Inc(Result);
    if (I < AValue.Length) and (Ord(AValue[I]) >= $D800) and (Ord(AValue[I]) <= $DBFF) and
       (Ord(AValue[I + 1]) >= $DC00) and (Ord(AValue[I + 1]) <= $DFFF) then
      Inc(I, 2)
    else
      Inc(I);
  end;
end;

procedure TJSONSchemaValidator.ValidateNumeric(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
var
  LNumber, LBound, LQuotient: Double;
  LValue: TJSONValue;
begin
  if not AsNumber(AInstance, LNumber) then
    Exit;

  LValue := ASchema.GetValue('multipleOf');
  if Assigned(LValue) and AsNumber(LValue, LBound) and (LBound <> 0) then
  begin
    LQuotient := LNumber / LBound;
    if Abs(LQuotient - Round(LQuotient)) > 1E-9 then
      AddError(AErrors, APath, 'multipleOf', Format('%g is not a multiple of %g', [LNumber, LBound]));
  end;

  LValue := ASchema.GetValue('minimum');
  if Assigned(LValue) and AsNumber(LValue, LBound) and (LNumber < LBound) then
    AddError(AErrors, APath, 'minimum', Format('%g is less than the minimum of %g', [LNumber, LBound]));

  LValue := ASchema.GetValue('maximum');
  if Assigned(LValue) and AsNumber(LValue, LBound) and (LNumber > LBound) then
    AddError(AErrors, APath, 'maximum', Format('%g is greater than the maximum of %g', [LNumber, LBound]));

  LValue := ASchema.GetValue('exclusiveMinimum');
  if Assigned(LValue) and AsNumber(LValue, LBound) and (LNumber <= LBound) then
    AddError(AErrors, APath, 'exclusiveMinimum', Format('%g is not greater than the exclusive minimum of %g', [LNumber, LBound]));

  LValue := ASchema.GetValue('exclusiveMaximum');
  if Assigned(LValue) and AsNumber(LValue, LBound) and (LNumber >= LBound) then
    AddError(AErrors, APath, 'exclusiveMaximum', Format('%g is not less than the exclusive maximum of %g', [LNumber, LBound]));
end;

procedure TJSONSchemaValidator.ValidateString(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
var
  LStr: string;
  LLength: Integer;
  LValue: TJSONValue;
  LMinMax: Integer;
begin
  // minLength/maxLength/pattern apply to strings only. TJSONNumber descends
  // from TJSONString in the RTL, so the plain "is" test would let numbers
  // through and measure their textual representation
  if not (AInstance is TJSONString) or (AInstance is TJSONNumber) then
    Exit;

  LStr := AInstance.Value;
  LLength := CodepointLength(LStr);

  LValue := ASchema.GetValue('minLength');
  if Assigned(LValue) and (LValue is TJSONNumber) then
  begin
    LMinMax := (LValue as TJSONNumber).AsInt;
    if LLength < LMinMax then
      AddError(AErrors, APath, 'minLength', Format('expected at least %d characters, got %d', [LMinMax, LLength]));
  end;

  LValue := ASchema.GetValue('maxLength');
  if Assigned(LValue) and (LValue is TJSONNumber) then
  begin
    LMinMax := (LValue as TJSONNumber).AsInt;
    if LLength > LMinMax then
      AddError(AErrors, APath, 'maxLength', Format('expected at most %d characters, got %d', [LMinMax, LLength]));
  end;

  LValue := ASchema.GetValue('pattern');
  if Assigned(LValue) and (LValue is TJSONString) then
  begin
    if not TRegEx.IsMatch(LStr, LValue.Value) then
      AddError(AErrors, APath, 'pattern', Format('"%s" does not match pattern "%s"', [LStr, LValue.Value]));
  end;
end;

procedure TJSONSchemaValidator.ValidateArray(AInstance: TJSONArray; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
var
  LPrefixItems, LItemsTuple: TJSONArray;
  LItems, LContains, LAdditionalItems: TJSONValue;
  LValue: TJSONValue;
  I, J, LMinMax, LContainsCount: Integer;
  LStartIndex, LBaseline: Integer;
  LTemp: TList<TJSONValidationError>;
begin
  LBaseline := AErrors.Count;
  LStartIndex := 0;

  LValue := ASchema.GetValue('prefixItems');
  if Assigned(LValue) and (LValue is TJSONArray) then
  begin
    LPrefixItems := LValue as TJSONArray;
    for I := 0 to LPrefixItems.Count - 1 do
    begin
      if I >= AInstance.Count then
        Break;
      ValidateNode(AInstance.Items[I], LPrefixItems.Items[I], Format('%s/%d', [APath, I]), AErrors);
      if ShouldStop(AErrors, LBaseline) then
        Exit;
    end;
    LStartIndex := LPrefixItems.Count;
  end;

  LItems := ASchema.GetValue('items');
  if Assigned(LItems) and (LItems is TJSONArray) and (LStartIndex = 0) then
  begin
    // Draft-07 tuple form: "items" is itself the per-index schema array,
    // with "additionalItems" governing indexes past the tuple (2020-12's
    // "prefixItems"/"items" split covers the same idea with different names,
    // handled by the prefixItems branch above)
    LItemsTuple := LItems as TJSONArray;
    for I := 0 to LItemsTuple.Count - 1 do
    begin
      if I >= AInstance.Count then
        Break;
      ValidateNode(AInstance.Items[I], LItemsTuple.Items[I], Format('%s/%d', [APath, I]), AErrors);
      if ShouldStop(AErrors, LBaseline) then
        Exit;
    end;
    LStartIndex := LItemsTuple.Count;

    LAdditionalItems := ASchema.GetValue('additionalItems');
    if Assigned(LAdditionalItems) then
      for I := LStartIndex to AInstance.Count - 1 do
      begin
        ValidateNode(AInstance.Items[I], LAdditionalItems, Format('%s/%d', [APath, I]), AErrors);
        if ShouldStop(AErrors, LBaseline) then
          Exit;
      end;
  end
  else if Assigned(LItems) then
    for I := LStartIndex to AInstance.Count - 1 do
    begin
      ValidateNode(AInstance.Items[I], LItems, Format('%s/%d', [APath, I]), AErrors);
      if ShouldStop(AErrors, LBaseline) then
        Exit;
    end;

  LContains := ASchema.GetValue('contains');
  if Assigned(LContains) then
  begin
    LContainsCount := 0;
    for I := 0 to AInstance.Count - 1 do
    begin
      LTemp := TList<TJSONValidationError>.Create;
      try
        if ValidateNode(AInstance.Items[I], LContains, Format('%s/%d', [APath, I]), LTemp) then
          Inc(LContainsCount);
      finally
        LTemp.Free;
      end;
    end;

    LMinMax := 1;
    LValue := ASchema.GetValue('minContains');
    if Assigned(LValue) and (LValue is TJSONNumber) then
      LMinMax := (LValue as TJSONNumber).AsInt;
    if LContainsCount < LMinMax then
      AddError(AErrors, APath, 'contains', Format('expected at least %d matching item(s), found %d', [LMinMax, LContainsCount]));
    if ShouldStop(AErrors, LBaseline) then
      Exit;

    LValue := ASchema.GetValue('maxContains');
    if Assigned(LValue) and (LValue is TJSONNumber) then
      if LContainsCount > (LValue as TJSONNumber).AsInt then
        AddError(AErrors, APath, 'maxContains', Format('expected at most %d matching item(s), found %d', [(LValue as TJSONNumber).AsInt, LContainsCount]));
    if ShouldStop(AErrors, LBaseline) then
      Exit;
  end;

  LValue := ASchema.GetValue('minItems');
  if Assigned(LValue) and (LValue is TJSONNumber) then
  begin
    LMinMax := (LValue as TJSONNumber).AsInt;
    if AInstance.Count < LMinMax then
      AddError(AErrors, APath, 'minItems', Format('expected at least %d items, got %d', [LMinMax, AInstance.Count]));
    if ShouldStop(AErrors, LBaseline) then
      Exit;
  end;

  LValue := ASchema.GetValue('maxItems');
  if Assigned(LValue) and (LValue is TJSONNumber) then
  begin
    LMinMax := (LValue as TJSONNumber).AsInt;
    if AInstance.Count > LMinMax then
      AddError(AErrors, APath, 'maxItems', Format('expected at most %d items, got %d', [LMinMax, AInstance.Count]));
    if ShouldStop(AErrors, LBaseline) then
      Exit;
  end;

  LValue := ASchema.GetValue('uniqueItems');
  if Assigned(LValue) and (LValue is TJSONBool) and (LValue as TJSONBool).AsBoolean then
  begin
    for I := 0 to AInstance.Count - 1 do
      for J := I + 1 to AInstance.Count - 1 do
        if JSONValuesEqual(AInstance.Items[I], AInstance.Items[J]) then
        begin
          AddError(AErrors, APath, 'uniqueItems', Format('items at index %d and %d are equal', [I, J]));
          Exit;
        end;
  end;
end;

procedure TJSONSchemaValidator.ValidateObject(AInstance: TJSONObject; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
var
  LProperties, LPatternProperties: TJSONValue;
  LAdditionalProperties, LPropertyNames, LRequired: TJSONValue;
  LDependentRequired: TJSONValue;
  LEvaluated: TDictionary<string, Boolean>;
  LPair, LInstPair: TJSONPair;
  LPropSchema: TJSONValue;
  LValue: TJSONValue;
  LDependency: string;
  LMinMax, LBaseline: Integer;
  I: Integer;
begin
  LBaseline := AErrors.Count;
  LEvaluated := TDictionary<string, Boolean>.Create;
  try
    LProperties := ASchema.GetValue('properties');
    if Assigned(LProperties) and (LProperties is TJSONObject) then
      for LPair in (LProperties as TJSONObject) do
      begin
        LValue := AInstance.GetValue(LPair.JsonString.Value);
        if Assigned(LValue) then
        begin
          ValidateNode(LValue, LPair.JsonValue, APath + '/' + LPair.JsonString.Value, AErrors);
          LEvaluated.AddOrSetValue(LPair.JsonString.Value, True);
          if ShouldStop(AErrors, LBaseline) then
            Exit;
        end;
      end;

    LPatternProperties := ASchema.GetValue('patternProperties');
    if Assigned(LPatternProperties) and (LPatternProperties is TJSONObject) then
      for LPair in (LPatternProperties as TJSONObject) do
        for LInstPair in AInstance do
          if TRegEx.IsMatch(LInstPair.JsonString.Value, LPair.JsonString.Value) then
          begin
            ValidateNode(LInstPair.JsonValue, LPair.JsonValue, APath + '/' + LInstPair.JsonString.Value, AErrors);
            LEvaluated.AddOrSetValue(LInstPair.JsonString.Value, True);
            if ShouldStop(AErrors, LBaseline) then
              Exit;
          end;

    LAdditionalProperties := ASchema.GetValue('additionalProperties');
    if Assigned(LAdditionalProperties) then
      for LPair in AInstance do
        if not LEvaluated.ContainsKey(LPair.JsonString.Value) then
        begin
          ValidateNode(LPair.JsonValue, LAdditionalProperties, APath + '/' + LPair.JsonString.Value, AErrors);
          if ShouldStop(AErrors, LBaseline) then
            Exit;
        end;

    LPropertyNames := ASchema.GetValue('propertyNames');
    if Assigned(LPropertyNames) then
      for LPair in AInstance do
      begin
        LPropSchema := TJSONString.Create(LPair.JsonString.Value);
        try
          ValidateNode(LPropSchema, LPropertyNames, APath + '/' + LPair.JsonString.Value, AErrors);
        finally
          LPropSchema.Free;
        end;
        if ShouldStop(AErrors, LBaseline) then
          Exit;
      end;

    LValue := ASchema.GetValue('minProperties');
    if Assigned(LValue) and (LValue is TJSONNumber) then
    begin
      LMinMax := (LValue as TJSONNumber).AsInt;
      if AInstance.Count < LMinMax then
        AddError(AErrors, APath, 'minProperties', Format('expected at least %d properties, got %d', [LMinMax, AInstance.Count]));
      if ShouldStop(AErrors, LBaseline) then
        Exit;
    end;

    LValue := ASchema.GetValue('maxProperties');
    if Assigned(LValue) and (LValue is TJSONNumber) then
    begin
      LMinMax := (LValue as TJSONNumber).AsInt;
      if AInstance.Count > LMinMax then
        AddError(AErrors, APath, 'maxProperties', Format('expected at most %d properties, got %d', [LMinMax, AInstance.Count]));
      if ShouldStop(AErrors, LBaseline) then
        Exit;
    end;

    LRequired := ASchema.GetValue('required');
    if Assigned(LRequired) and (LRequired is TJSONArray) then
      for I := 0 to (LRequired as TJSONArray).Count - 1 do
        if not Assigned(AInstance.GetValue((LRequired as TJSONArray).Items[I].Value)) then
        begin
          AddError(AErrors, APath, 'required', Format('missing required property "%s"', [(LRequired as TJSONArray).Items[I].Value]));
          if ShouldStop(AErrors, LBaseline) then
            Exit;
        end;

    // dependentRequired: {"a": ["b", "c"]} means "if the instance has a, it
    // must have b and c too". A property that is absent imposes nothing
    LDependentRequired := ASchema.GetValue('dependentRequired');
    if Assigned(LDependentRequired) and (LDependentRequired is TJSONObject) then
      for LPair in (LDependentRequired as TJSONObject) do
      begin
        if not (LPair.JsonValue is TJSONArray) then
          Continue;

        if not Assigned(AInstance.GetValue(LPair.JsonString.Value)) then
          Continue;

        for I := 0 to (LPair.JsonValue as TJSONArray).Count - 1 do
        begin
          LDependency := (LPair.JsonValue as TJSONArray).Items[I].Value;
          if not Assigned(AInstance.GetValue(LDependency)) then
          begin
            AddError(AErrors, APath, 'dependentRequired',
              Format('property "%s" requires "%s", which is missing',
                [LPair.JsonString.Value, LDependency]));
            if ShouldStop(AErrors, LBaseline) then
              Exit;
          end;
        end;
      end;
  finally
    LEvaluated.Free;
  end;
end;

function TJSONSchemaValidator.ValidateLogic(AInstance: TJSONValue; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>): Boolean;
var
  LAllOf, LAnyOf, LOneOf, LNot: TJSONValue;
  LIf, LBranchSchema: TJSONValue;
  LBranch: TJSONValue;
  LTemp: TList<TJSONValidationError>;
  LMatchedIndexes: TList<Integer>;
  LMatchCount, I: Integer;
  LCondition: Boolean;

  function IndexesToString(AIndexes: TList<Integer>): string;
  var
    LIndex: Integer;
  begin
    Result := '';
    for LIndex in AIndexes do
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + LIndex.ToString;
    end;
  end;

begin
  Result := True;

  LAllOf := ASchema.GetValue('allOf');
  if Assigned(LAllOf) and (LAllOf is TJSONArray) then
    for LBranch in (LAllOf as TJSONArray) do
    begin
      if not ValidateNode(AInstance, LBranch, APath, AErrors) then
      begin
        Result := False;
        if FStopOnFirstError then
          Exit;
      end;
    end;

  LAnyOf := ASchema.GetValue('anyOf');
  if Assigned(LAnyOf) and (LAnyOf is TJSONArray) then
  begin
    LMatchCount := 0;
    for LBranch in (LAnyOf as TJSONArray) do
    begin
      LTemp := TList<TJSONValidationError>.Create;
      try
        if ValidateNode(AInstance, LBranch, APath, LTemp) then
          Inc(LMatchCount);
      finally
        LTemp.Free;
      end;
    end;
    if LMatchCount = 0 then
    begin
      AddError(AErrors, APath, 'anyOf', 'instance does not match any of the schemas in "anyOf"');
      Result := False;
    end;
  end;

  LOneOf := ASchema.GetValue('oneOf');
  if Assigned(LOneOf) and (LOneOf is TJSONArray) then
  begin
    LMatchedIndexes := TList<Integer>.Create;
    try
      for I := 0 to (LOneOf as TJSONArray).Count - 1 do
      begin
        LTemp := TList<TJSONValidationError>.Create;
        try
          if ValidateNode(AInstance, (LOneOf as TJSONArray).Items[I], APath, LTemp) then
            LMatchedIndexes.Add(I);
        finally
          LTemp.Free;
        end;
      end;
      LMatchCount := LMatchedIndexes.Count;
      if LMatchCount = 0 then
      begin
        AddError(AErrors, APath, 'oneOf', 'instance does not match any of the schemas in "oneOf"');
        Result := False;
      end
      else if LMatchCount > 1 then
      begin
        AddError(AErrors, APath, 'oneOf', Format('instance matches more than one schema in "oneOf" (indexes %s)',
          [IndexesToString(LMatchedIndexes)]));
        Result := False;
      end;
    finally
      LMatchedIndexes.Free;
    end;
  end;

  LNot := ASchema.GetValue('not');
  if Assigned(LNot) then
  begin
    LTemp := TList<TJSONValidationError>.Create;
    try
      if ValidateNode(AInstance, LNot, APath, LTemp) then
      begin
        AddError(AErrors, APath, 'not', 'instance must not validate against the "not" schema');
        Result := False;
      end;
    finally
      LTemp.Free;
    end;
  end;

  // if/then/else. The "if" subschema is a condition only: it never contributes
  // errors of its own (they go to a throwaway list), it just selects which of
  // "then"/"else" is applied. Without an "if" both are inert
  LIf := ASchema.GetValue('if');
  if Assigned(LIf) then
  begin
    LTemp := TList<TJSONValidationError>.Create;
    try
      LCondition := ValidateNode(AInstance, LIf, APath, LTemp);
    finally
      LTemp.Free;
    end;

    if LCondition then
      LBranchSchema := ASchema.GetValue('then')
    else
      LBranchSchema := ASchema.GetValue('else');

    if Assigned(LBranchSchema) then
      if not ValidateNode(AInstance, LBranchSchema, APath, AErrors) then
        Result := False;
  end;
end;

function TJSONSchemaValidator.ValidateNode(AInstance: TJSONValue; ASchema: TJSONValue; const APath: string; AErrors: TList<TJSONValidationError>): Boolean;
var
  LErrorCountBefore: Integer;
  LSchemaObj: TJSONObject;
  LRef, LEnum, LConst: TJSONValue;
  LEnumItem, LTarget: TJSONValue;
  LFrame: TRefFrame;
  LMatched: Boolean;
begin
  LErrorCountBefore := AErrors.Count;

  // Boolean schema: `true` (or absent) always valid, `false` always invalid
  if not Assigned(ASchema) then
    Exit(True);

  if ASchema is TJSONBool then
  begin
    if not (ASchema as TJSONBool).AsBoolean then
      AddError(AErrors, APath, 'false', 'instance is not allowed (schema is `false`)');
    Exit(AErrors.Count = LErrorCountBefore);
  end;

  if not (ASchema is TJSONObject) then
    Exit(True); // malformed schema position - treat permissively

  LSchemaObj := ASchema as TJSONObject;

  // $ref
  LRef := LSchemaObj.GetValue('$ref');
  if Assigned(LRef) and (LRef is TJSONString) then
  begin
    LTarget := ResolveRef(LRef.Value);

    // A $ref leading back to a (schema, instance) pair already on the current
    // path cannot constrain anything further - the outer evaluation is applying
    // that very schema to that very instance - so following it again would only
    // recurse forever. Skipping it makes a non-productive cycle (e.g. a schema
    // that is just {"$ref": "#"}, or two $defs referencing each other) terminate,
    // while ordinary recursive schemas are unaffected: there every step descends
    // into a smaller instance, so the pair is never the same twice
    if not IsRefFrameActive(LTarget, AInstance) then
    begin
      LFrame.Schema := LTarget;
      LFrame.Instance := AInstance;
      FRefStack.Add(LFrame);
      try
        ValidateNode(AInstance, LTarget, APath, AErrors);
      finally
        FRefStack.Delete(FRefStack.Count - 1);
      end;

      if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
        Exit(False);
    end;
  end;

  // type / types
  if not InstanceMatchesAnyType(AInstance, LSchemaObj) then
    AddError(AErrors, APath, 'type', Format('%s is not of the expected type', [JSONTypeName(AInstance)]));
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  // enum
  LEnum := LSchemaObj.GetValue('enum');
  if Assigned(LEnum) and (LEnum is TJSONArray) then
  begin
    LMatched := False;
    for LEnumItem in (LEnum as TJSONArray) do
      if JSONValuesEqual(AInstance, LEnumItem) then
      begin
        LMatched := True;
        Break;
      end;
    if not LMatched then
      AddError(AErrors, APath, 'enum', 'instance does not match any value in "enum"');
  end;
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  // const
  LConst := LSchemaObj.GetValue('const');
  if Assigned(LConst) and not JSONValuesEqual(AInstance, LConst) then
    AddError(AErrors, APath, 'const', 'instance does not match "const"');
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  // numeric / string constraints
  ValidateNumeric(AInstance, LSchemaObj, APath, AErrors);
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  ValidateString(AInstance, LSchemaObj, APath, AErrors);
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  // logic keywords (allOf/anyOf/oneOf/not) - before array/object, per spec
  ValidateLogic(AInstance, LSchemaObj, APath, AErrors);
  if FStopOnFirstError and (AErrors.Count > LErrorCountBefore) then
    Exit(False);

  // array / object keywords
  if AInstance is TJSONArray then
    ValidateArray(AInstance as TJSONArray, LSchemaObj, APath, AErrors)
  else if AInstance is TJSONObject then
    ValidateObject(AInstance as TJSONObject, LSchemaObj, APath, AErrors);

  Result := AErrors.Count = LErrorCountBefore;
end;

function TJSONSchemaValidator.Validate(AInstance: TJSONValue): TJSONValidationResult;
var
  LErrors: TList<TJSONValidationError>;
begin
  LErrors := TList<TJSONValidationError>.Create;
  try
    Result.IsValid := ValidateNode(AInstance, FRoot, '', LErrors);
    Result.Errors := LErrors.ToArray;
  finally
    LErrors.Free;
  end;
end;

{ TNeonHelper }

class function TNeonHelper.ValidateJSON(AJSON, ASchema: TJSONValue): TJSONValidationResult;
var
  LValidator: TJSONSchemaValidator;
begin
  LValidator := TJSONSchemaValidator.Create(ASchema);
  try
    Result := LValidator.Validate(AJSON);
  finally
    LValidator.Free;
  end;
end;

end.
