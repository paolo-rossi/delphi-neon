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
    ///   before recursing into a class/record's members, removed after), so that
    ///   a self-referencing Delphi type is turned into a reference rather than
    ///   recursed into forever
    /// </summary>
    FVisitedTypes: TDictionary<PTypeInfo, Boolean>;

    /// <summary>
    ///   The definitions container for the document being generated, holding one
    ///   entry per type that had to be referenced. Attached to the root by
    ///   TypeToJSONSchema, which takes ownership; if the document ends up with no
    ///   references at all it stays empty and is never attached
    /// </summary>
    FDefs: TJSONObject;

    /// <summary>
    ///   Definition name assigned to a type, present from the moment something
    ///   first needs to reference it
    /// </summary>
    FDefNames: TDictionary<PTypeInfo, string>;

    /// <summary>
    ///   The draft the document is being generated for, so that the writers can
    ///   leave out keywords that draft does not have. None means "no dialect
    ///   declared", and is treated as the newest one
    /// </summary>
    FVersion: TNeonJSchemaVersion;

    /// <summary>
    ///   "$defs" from 2019-09 on, "definitions" for Draft-07
    /// </summary>
    function DefsKeyword: string;

    /// <summary>
    ///   The definition name for a type, assigned on first use and made unique
    ///   against names already taken by other types
    /// </summary>
    function DefNameFor(AType: TRttiType): string;

    /// <summary>
    ///   A schema that is nothing but a reference to one of the definitions
    /// </summary>
    function ReferenceTo(const ADefName: string): TJSONObject;

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
    ///   True if the schema's "type" is a union admitting "null" - a Nullable&lt;T&gt;
    ///   or a Variant. Keywords that enumerate allowed values have to admit null
    ///   too, or they contradict that union
    /// </summary>
    function IsNullableSchema(AJSON: TJSONObject): Boolean;

    /// <summary>
    ///   Converts a JsonSchema tag value to a JSON value of the appropriate
    ///   kind (number/integer/boolean/string) based on AJSONType
    /// </summary>
    function TagValueToJSON(ATags: TAttributeTags; const AName, AJSONType: string): TJSONValue;

    /// <summary>
    ///   Flattens a [NeonUnwrapped] member's schema into the parent: its
    ///   properties are copied into AProperties and its required member names
    ///   into ARequired. Returns False (leaving both untouched) if the member's
    ///   schema has no properties to flatten, in which case the caller must
    ///   nest it as an ordinary member
    /// </summary>
    function UnwrapMember(AMemberSchema, AProperties: TJSONObject; var ARequired: TJSONArray): Boolean;

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
  ///   if/then/else and dependentRequired/dependentSchemas are implemented (as
  ///   is Draft-07's "dependencies", which merges the last two);
  ///   unevaluatedProperties/unevaluatedItems are not yet (they need the
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
    /// <summary>
    ///   Applies one dependency map: for every property of it that the instance
    ///   actually has, an array value makes the listed property names mandatory
    ///   and a schema value is applied to the whole object. Draft-07's
    ///   "dependencies" allows both forms in the same map, which is why the form
    ///   is decided per entry rather than per keyword. Returns False when
    ///   validation must stop early
    /// </summary>
    function ValidateDependencyMap(AInstance: TJSONObject; ADependencies: TJSONValue;
      const AKeyword, APath: string; AErrors: TList<TJSONValidationError>; ABaseline: Integer): Boolean;

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

const
  /// <summary>
  ///   Keywords whose value is a subschema, or - for "items"/"additionalItems"
  ///   in the Draft-07 tuple form, and for the four logic keywords - an array of
  ///   subschemas. CollectAnchors handles both, since it walks arrays too
  /// </summary>
  SCHEMA_POSITIONS: array[0..15] of string = (
    'additionalProperties', 'propertyNames', 'items', 'additionalItems',
    'contains', 'not', 'if', 'then', 'else', 'unevaluatedItems',
    'unevaluatedProperties', 'contentSchema',
    'allOf', 'anyOf', 'oneOf', 'prefixItems'
  );

  /// <summary>
  ///   Keywords whose value is an object mapping a name to a subschema. Under
  ///   Draft-07's "dependencies" a value may instead be an array of property
  ///   names, which simply holds no subschema to find
  /// </summary>
  SCHEMA_MAP_POSITIONS: array[0..5] of string = (
    'properties', 'patternProperties', '$defs', 'definitions',
    'dependentSchemas', 'dependencies'
  );

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
  FVersion := TNeonJSchemaVersion.None;
  FVisitedTypes := TDictionary<PTypeInfo, Boolean>.Create;
  FDefNames := TDictionary<PTypeInfo, string>.Create;
  FDefs := TJSONObject.Create;
end;

destructor TNeonSchemaGenerator.Destroy;
begin
  FDefs.Free; // nil once TypeToJSONSchema has attached it to the document
  FDefNames.Free;
  FVisitedTypes.Free;
  inherited;
end;

function TNeonSchemaGenerator.DefsKeyword: string;
begin
  if FVersion = TNeonJSchemaVersion.Draft07 then
    Result := 'definitions'
  else
    Result := '$defs';
end;

function TNeonSchemaGenerator.DefNameFor(AType: TRttiType): string;
var
  LName: string;
  LIndex: Integer;
  LTaken: Boolean;
  LOther: TPair<PTypeInfo, string>;
begin
  if FDefNames.TryGetValue(AType.Handle, Result) then
    Exit;

  // Two units can declare types of the same name, and they would otherwise
  // collide in a single flat definitions object
  LName := AType.Name;
  LIndex := 1;
  repeat
    LTaken := False;
    for LOther in FDefNames do
      if LOther.Value = LName then
      begin
        LTaken := True;
        Break;
      end;

    if LTaken then
    begin
      Inc(LIndex);
      LName := AType.Name + LIndex.ToString;
    end;
  until not LTaken;

  FDefNames.Add(AType.Handle, LName);
  Result := LName;
end;

function TNeonSchemaGenerator.ReferenceTo(const ADefName: string): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('$ref', '#/' + DefsKeyword + '/' + ADefName);
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

function TNeonSchemaGenerator.IsNullableSchema(AJSON: TJSONObject): Boolean;
var
  LType: TJSONValue;
  LItem: TJSONValue;
begin
  Result := False;

  LType := AJSON.GetValue('type');
  if not (Assigned(LType) and (LType is TJSONArray)) then
    Exit;

  for LItem in (LType as TJSONArray) do
    if LItem.Value = 'null' then
      Exit(True);
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
  LExamples, LConstEnum: TJSONArray;
begin
  // The writer for an interface produces no schema at all, so an attribute on
  // such a type has nothing to annotate
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

  // "deprecated" only exists from 2019-09 onwards, so it is left out of a
  // Draft-07 document. ("const", by contrast, dates from Draft-06 and is emitted
  // for every draft this generator can target.)
  if LTags.Exists('deprecated') and (FVersion <> TNeonJSchemaVersion.Draft07) then
    AJSON.AddPair('deprecated', TJSONBool.Create(True));

  if LTags.Exists('default') then
    AJSON.AddPair('default', TagValueToJSON(LTags, 'default', LJSONType));

  if LTags.Exists('const') then
    if IsNullableSchema(AJSON) then
    begin
      // The member is a Nullable<T>, whose "type" union admits null: a "const"
      // would contradict that, so the equivalent two-value "enum" is used instead
      LConstEnum := TJSONArray.Create;
      LConstEnum.AddElement(TagValueToJSON(LTags, 'const', LJSONType));
      LConstEnum.AddElement(TJSONNull.Create);
      AJSON.AddPair('enum', LConstEnum);
    end
    else
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
    // Known before generating, not just when stamping "$schema" at the end, so
    // the writers can keep to the keywords the chosen draft actually defines
    LGenerator.FVersion := AVersion;

    Result := LGenerator.WriteDataMember(AType);
    if Assigned(Result) then
    begin
      // Definitions are collected as generation proceeds and belong at the root
      // of the document, whatever depth the reference to them was made at
      if LGenerator.FDefs.Count > 0 then
      begin
        Result.AddPair(LGenerator.DefsKeyword, LGenerator.FDefs);
        LGenerator.FDefs := nil; // ownership passed to the document
      end;

      if (AVersion <> TNeonJSchemaVersion.None) then
        Result.AddPair('$schema', SchemaURIFor(AVersion));
    end;
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
  // TNeonSerializerJSON.WriteInterface casts the interface to its implementing
  // object and writes that object's members. Which members those are cannot be
  // known from the declared type: interface RTTI carries methods only - no
  // properties, no fields - and the concrete class may add more besides (its
  // TInterfacedObject.RefCount, for one). An unconstrained object is therefore
  // as precise as this can honestly be, and it never rejects what is written
  Result := TJSONObject.Create
    .AddPair('type', 'object');
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

function TNeonSchemaGenerator.UnwrapMember(AMemberSchema, AProperties: TJSONObject; var ARequired: TJSONArray): Boolean;
var
  LProperties, LRequired: TJSONValue;
  LPair: TJSONPair;
  LIndex: Integer;
begin
  // Only a schema describing a fixed set of properties can be flattened, which
  // matches TNeonSerializerJSON.WriteMembers unwrapping only what it wrote as a
  // TJSONObject. Anything else (a string, an array, or a map's open-ended
  // "additionalProperties") is left for the caller to nest as usual
  LProperties := AMemberSchema.GetValue('properties');
  if not (Assigned(LProperties) and (LProperties is TJSONObject)) then
    Exit(False);

  for LPair in (LProperties as TJSONObject) do
    AProperties.AddPair(LPair.Clone as TJSONPair);

  // The nested members keep their "required" status, now against the parent
  LRequired := AMemberSchema.GetValue('required');
  if Assigned(LRequired) and (LRequired is TJSONArray) then
    for LIndex := 0 to (LRequired as TJSONArray).Count - 1 do
    begin
      if not Assigned(ARequired) then
        ARequired := TJSONArray.Create;
      ARequired.Add((LRequired as TJSONArray).Items[LIndex].Value);
    end;

  Result := True;
end;

function TNeonSchemaGenerator.WriteMembers(AType: TRttiType; AResult: TJSONObject): TJSONArray;
var
  LJSONObj: TJSONObject;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LNeonName: string;
  LUnwrapped: Boolean;
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
            // [NeonUnwrapped] members contribute their own members to the parent
            // instead of a property of their own, so there is no name to give
            // them here and no name to put in the parent's "required" either.
            // UnwrapMember writes into AResult/Result, so it is called from a
            // statement rather than from inside a boolean expression, where
            // whether it ran at all would depend on the evaluation mode
            LUnwrapped := False;
            if LNeonMember.NeonUnwrapped then
              LUnwrapped := UnwrapMember(LJSONObj, AResult, Result);

            if not LUnwrapped then
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
  LTypePair, LConstPair: TJSONPair;
  LTypeArray, LEnumArray: TJSONArray;
  LEnum: TJSONValue;
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
  // wraps a Go pointer type)
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

  // Widening "type" is not enough on its own: a base schema that also enumerates
  // or pins its allowed values would go on rejecting null, contradicting the
  // union just built. Both keywords have to admit null as well. (They are
  // mutually exclusive in practice - a schema carrying both is already
  // self-contradictory - so this is an either/or)
  LEnum := Result.GetValue('enum');
  if Assigned(LEnum) and (LEnum is TJSONArray) then
    (LEnum as TJSONArray).AddElement(TJSONNull.Create)
  else
  begin
    // "const" holds exactly one value and cannot be widened, but the two-value
    // "enum" says precisely the same thing and has room for null
    LConstPair := Result.RemovePair('const');
    if Assigned(LConstPair) then
    try
      LEnumArray := TJSONArray.Create;
      LEnumArray.AddElement(LConstPair.JsonValue.Clone as TJSONValue);
      LEnumArray.AddElement(TJSONNull.Create);
      Result.AddPair('enum', LEnumArray);
    finally
      LConstPair.Free;
    end;
  end;
end;

function TNeonSchemaGenerator.WriteObjectOrRecord(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LProperties: TJSONObject;
  LRequired: TJSONArray;
  LSchema: TJSONObject;
  LDefName: string;
begin
  // Already being written further up the path, so this is a self-referencing
  // type: emit a reference to it instead of expanding it a second time. That is
  // what $defs exists for, and it is the only way to describe such a type at all
  if FVisitedTypes.ContainsKey(AType.Handle) then
    Exit(ReferenceTo(DefNameFor(AType)));

  FVisitedTypes.Add(AType.Handle, True);
  try
    LProperties := TJSONObject.Create;

    LRequired := WriteMembers(AType, LProperties);

    LSchema := TJSONObject.Create
      .AddPair('type', 'object')
      .AddPair('properties', LProperties);

    if Assigned(LRequired) then
      LSchema.AddPair('required', LRequired);
  finally
    FVisitedTypes.Remove(AType.Handle);
  end;

  // Nothing referenced this type while it was being written, so it can stay
  // where it is and the document needs no definitions on its account
  if not FDefNames.TryGetValue(AType.Handle, LDefName) then
    Exit(LSchema);

  // Something did: the schema itself belongs in the definitions, and this
  // position becomes a reference like the others
  if Assigned(FDefs.GetValue(LDefName)) then
    LSchema.Free // an identical definition was already stored by an earlier use
  else
    FDefs.AddPair(LDefName, LSchema);

  Result := ReferenceTo(LDefName);
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
  // The stream is written as a Base64 string (TStreamSerializer). "byte" was
  // OpenAPI 3.0's way of saying that; 2020-12 has a keyword of its own, which
  // unlike a "format" annotation actually carries meaning to a validator
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('contentEncoding', 'base64');
end;

function TNeonSchemaGenerator.WriteStreamable(AType: TRttiType; ANeonObject: TNeonRttiObject; AStream: INeonTypeInfoStream): TJSONObject;
begin
  // Saved to a stream and Base64-encoded, exactly as for a TStream member
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('contentEncoding', 'base64');
end;

function TNeonSchemaGenerator.WriteString(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  if ANeonObject.NeonRawValue then
    Exit(TJSONObject.Create);

  Result := TJSONObject.Create
    .AddPair('type', 'string');
end;

function TNeonSchemaGenerator.WriteVariant(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LTypes: TJSONArray;
begin
  // A Variant's JSON type is only settled at run time, so the schema is the union
  // of everything TNeonSerializerJSON.WriteVariant can write: a number for the
  // integer/float/currency variants, a boolean, null, and a string for dates, for
  // varString and for every variant type it does not recognise. It never writes
  // an object or an array - a variant array fails to convert and is logged instead
  //
  // "string" leads deliberately: GetPrimaryJSONType reports the first non-null
  // entry, and a string is the one interpretation of a "default"/"const" tag that
  // cannot fail to convert
  LTypes := TJSONArray.Create;
  LTypes.Add('string');
  LTypes.Add('number');
  LTypes.Add('boolean');
  LTypes.Add('null');

  Result := TJSONObject.Create.AddPair('type', LTypes);
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
  LAnchor, LId, LItem, LValue: TJSONValue;
  LPair: TJSONPair;
  LKeyword: string;
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

  // Descend only where a subschema can actually live. Walking every member would
  // walk instance data as well - the object under a "const", "default" or
  // "examples" is a value, and an "$anchor" key inside one names nothing.
  // Unknown keywords are skipped for the same reason: 2020-12 says their
  // contents are annotations, not schemas
  for LKeyword in SCHEMA_POSITIONS do
    CollectAnchors(LObj.GetValue(LKeyword));

  for LKeyword in SCHEMA_MAP_POSITIONS do
  begin
    LValue := LObj.GetValue(LKeyword);
    if LValue is TJSONObject then
      for LPair in (LValue as TJSONObject) do
        CollectAnchors(LPair.JsonValue);
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

function TJSONSchemaValidator.ValidateDependencyMap(AInstance: TJSONObject;
  ADependencies: TJSONValue; const AKeyword, APath: string;
  AErrors: TList<TJSONValidationError>; ABaseline: Integer): Boolean;
var
  LPair: TJSONPair;
  LNames: TJSONArray;
  LDependency: string;
  LIndex: Integer;
begin
  Result := True;

  if not (Assigned(ADependencies) and (ADependencies is TJSONObject)) then
    Exit;

  for LPair in (ADependencies as TJSONObject) do
  begin
    // A property absent from the instance triggers nothing
    if not Assigned(AInstance.GetValue(LPair.JsonString.Value)) then
      Continue;

    if LPair.JsonValue is TJSONArray then
    begin
      // Array form: the listed properties become mandatory as well
      LNames := LPair.JsonValue as TJSONArray;
      for LIndex := 0 to LNames.Count - 1 do
      begin
        LDependency := LNames.Items[LIndex].Value;
        if not Assigned(AInstance.GetValue(LDependency)) then
        begin
          AddError(AErrors, APath, AKeyword,
            Format('property "%s" requires "%s", which is missing',
              [LPair.JsonString.Value, LDependency]));
          if ShouldStop(AErrors, ABaseline) then
            Exit(False);
        end;
      end;
    end
    else
    begin
      // Schema form: applied to the whole object, not to the value of the
      // property that triggered it, so instance and path are passed through
      ValidateNode(AInstance, LPair.JsonValue, APath, AErrors);
      if ShouldStop(AErrors, ABaseline) then
        Exit(False);
    end;
  end;
end;

procedure TJSONSchemaValidator.ValidateObject(AInstance: TJSONObject; ASchema: TJSONObject; const APath: string; AErrors: TList<TJSONValidationError>);
var
  LProperties, LPatternProperties: TJSONValue;
  LAdditionalProperties, LPropertyNames, LRequired: TJSONValue;
  LEvaluated: TDictionary<string, Boolean>;
  LPair, LInstPair: TJSONPair;
  LPropSchema: TJSONValue;
  LValue: TJSONValue;
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

    // The 2020-12 pair, plus Draft-07's "dependencies", which is exactly these
    // two keywords merged into one: an array value behaves as dependentRequired
    // and a schema value as dependentSchemas, which is what ValidateDependencyMap
    // dispatches on
    if not ValidateDependencyMap(AInstance, ASchema.GetValue('dependentRequired'),
        'dependentRequired', APath, AErrors, LBaseline) then
      Exit;

    if not ValidateDependencyMap(AInstance, ASchema.GetValue('dependentSchemas'),
        'dependentSchemas', APath, AErrors, LBaseline) then
      Exit;

    if not ValidateDependencyMap(AInstance, ASchema.GetValue('dependencies'),
        'dependencies', APath, AErrors, LBaseline) then
      Exit;
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
