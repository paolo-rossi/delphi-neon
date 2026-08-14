{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Generator;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Character,
  System.Generics.Collections, System.JSON,

  Neon.Core.Types,
  Neon.Core.Utils;

{$SCOPEDENUMS ON}

type
  /// <summary>
  ///   The Delphi construct emitted for a JSON object
  /// </summary>
  TNeonEntityKind = (Classes, Records);

  /// <summary>
  ///   The Delphi construct emitted for a JSON array of objects. Arrays of
  ///   simple values are always emitted as TArray&lt;T&gt;, and so are arrays of
  ///   objects when the entities are records
  /// </summary>
  TNeonArrayKind = (DynamicArray, ObjectList, GenericList);

  /// <summary>
  ///   How a JSON member name is turned into a Delphi identifier. Unchanged
  ///   keeps the name as it is in the document (minus the characters that are
  ///   not legal in an identifier)
  /// </summary>
  TNeonNameCase = (Pascal, Unchanged);

  /// <summary>
  ///   Configuration of the entity generator. Every field has a sensible
  ///   default (see TNeonEntityConfig.Default), and the Set* methods can be
  ///   chained to change only the ones that matter:
  ///   <code>
  ///   TNeonEntityConfig.Default.SetEntityKind(TNeonEntityKind.Records).SetTypePrefix('T')
  ///   </code>
  /// </summary>
  TNeonEntityConfig = record
  public
    /// <summary>
    ///   Classes (private fields + published-style properties) or records
    ///   (public fields)
    /// </summary>
    EntityKind: TNeonEntityKind;

    /// <summary>
    ///   Container emitted for a JSON array of objects
    /// </summary>
    ArrayKind: TNeonArrayKind;

    /// <summary>
    ///   Case algorithm applied to JSON member names
    /// </summary>
    NameCase: TNeonNameCase;

    /// <summary>
    ///   Prefix of every generated type name
    /// </summary>
    TypePrefix: string;

    /// <summary>
    ///   Base name of the type generated for the root of the document (the
    ///   prefix is prepended to it)
    /// </summary>
    RootName: string;

    /// <summary>
    ///   Delphi type used where the document carries no type information: a
    ///   member that is always null, or an array that is always empty
    /// </summary>
    UnknownType: string;

    /// <summary>
    ///   Number of spaces of one indentation level
    /// </summary>
    IndentSize: Integer;

    /// <summary>
    ///   Emit [NeonProperty] when the Delphi identifier is not identical to the
    ///   JSON member name. Without it the generated entities do not round-trip
    ///   unless the serializer is configured with a matching member case
    /// </summary>
    UseNeonProperty: Boolean;

    /// <summary>
    ///   Emit Nullable&lt;T&gt; for members that are null in some samples, or
    ///   missing from some elements of an array
    /// </summary>
    UseNullables: Boolean;

    /// <summary>
    ///   Map strings that look like an ISO8601 date/time to TDateTime
    /// </summary>
    DetectDateTime: Boolean;

    /// <summary>
    ///   Emit one type per distinct structure: two JSON objects with the same
    ///   members and the same member types share a single entity
    /// </summary>
    MergeEqualTypes: Boolean;

    /// <summary>
    ///   Emit a constructor/destructor pair for classes owning other entities
    ///   (nested objects and object lists), so that an entity is usable without
    ///   relying on the AutoCreate setting of the serializer
    /// </summary>
    GenerateLifetime: Boolean;

    /// <summary>
    ///   Write the "generated file" banner at the top of a generated unit
    /// </summary>
    WriteHeader: Boolean;

    class function Default: TNeonEntityConfig; static;
    class function Records: TNeonEntityConfig; static;

    function SetEntityKind(AValue: TNeonEntityKind): TNeonEntityConfig;
    function SetArrayKind(AValue: TNeonArrayKind): TNeonEntityConfig;
    function SetNameCase(AValue: TNeonNameCase): TNeonEntityConfig;
    function SetTypePrefix(const AValue: string): TNeonEntityConfig;
    function SetRootName(const AValue: string): TNeonEntityConfig;
    function SetUnknownType(const AValue: string): TNeonEntityConfig;
    function SetIndentSize(AValue: Integer): TNeonEntityConfig;
    function SetUseNeonProperty(AValue: Boolean): TNeonEntityConfig;
    function SetUseNullables(AValue: Boolean): TNeonEntityConfig;
    function SetDetectDateTime(AValue: Boolean): TNeonEntityConfig;
    function SetMergeEqualTypes(AValue: Boolean): TNeonEntityConfig;
    function SetGenerateLifetime(AValue: Boolean): TNeonEntityConfig;
    function SetWriteHeader(AValue: Boolean): TNeonEntityConfig;
  end;

  /// <summary>
  ///   The type of a position in the document, as inferred from the samples
  ///   found there. Unknown is both "nothing seen yet" (a null-only member, an
  ///   empty array) and the fallback for a position holding incompatible types
  /// </summary>
  TNeonJSONKind = (Unknown, Bool, Int, Float, Str, Obj, Arr);

  TNeonTypeNode = class;

  /// <summary>
  ///   One member of a JSON object, with the JSON name it was read from and the
  ///   Delphi identifier it will be emitted as
  /// </summary>
  TNeonEntityMember = class
  private
    FJSONName: string;
    FName: string;
    FEscaped: Boolean;
    FNode: TNeonTypeNode;
    FSampleCount: Integer;
  public
    constructor Create(const AJSONName: string);
    destructor Destroy; override;

    /// <summary>
    ///   The identifier as it appears in the generated source, escaped with the
    ///   ampersand when it collides with a Delphi reserved word
    /// </summary>
    function DeclaredName: string;

    /// <summary>
    ///   Name of the backing field of the property (classes only)
    /// </summary>
    function FieldName: string;

    property JSONName: string read FJSONName;
    property Name: string read FName write FName;
    property Escaped: Boolean read FEscaped write FEscaped;
    property Node: TNeonTypeNode read FNode;

    /// <summary>
    ///   How many of the samples of the owning object carried this member
    /// </summary>
    property SampleCount: Integer read FSampleCount write FSampleCount;
  end;

  /// <summary>
  ///   A position in the document (the root, a member, an array item) together
  ///   with the type inferred for it. The nodes form a tree mirroring the shape
  ///   of the JSON, not of the generated code: several nodes can end up sharing
  ///   one generated entity (see Canonical)
  /// </summary>
  TNeonTypeNode = class
  private
    FKind: TNeonJSONKind;
    FConflict: Boolean;
    FNullable: Boolean;
    FIsDateTime: Boolean;
    FIsInt64: Boolean;
    FSampleCount: Integer;
    FItemType: TNeonTypeNode;
    FMembers: TObjectList<TNeonEntityMember>;
    FIndex: TDictionary<string, TNeonEntityMember>;
    FTypeName: string;
    FCanonical: TNeonTypeNode;
  public
    constructor Create;
    destructor Destroy; override;

    function FindMember(const AJSONName: string): TNeonEntityMember;
    function AddMember(const AJSONName: string): TNeonEntityMember;

    /// <summary>
    ///   The node describing the items of an array, created on first use
    /// </summary>
    function EnsureItemType: TNeonTypeNode;

    /// <summary>
    ///   True when the member was absent from at least one of the samples of
    ///   this object
    /// </summary>
    function IsOptional(AMember: TNeonEntityMember): Boolean;

    property Kind: TNeonJSONKind read FKind write FKind;
    property Conflict: Boolean read FConflict write FConflict;
    property Nullable: Boolean read FNullable write FNullable;
    property IsDateTime: Boolean read FIsDateTime write FIsDateTime;
    property IsInt64: Boolean read FIsInt64 write FIsInt64;
    property SampleCount: Integer read FSampleCount write FSampleCount;
    property ItemType: TNeonTypeNode read FItemType;
    property Members: TObjectList<TNeonEntityMember> read FMembers;

    /// <summary>
    ///   Name of the generated entity (objects only), assigned while preparing
    ///   the generation
    /// </summary>
    property TypeName: string read FTypeName write FTypeName;

    /// <summary>
    ///   The node whose entity is generated for this position: itself, or the
    ///   first structurally identical node met when merging equal types
    /// </summary>
    property Canonical: TNeonTypeNode read FCanonical write FCanonical;
  end;

  /// <summary>
  ///   Generates Delphi entities (classes or records, plus the Neon attributes
  ///   needed to round-trip them) from a JSON document used as a sample.
  ///   <para>
  ///   The document is read once into a tree of TNeonTypeNode, then the tree is
  ///   named and emitted. An array is a sample of every one of its items, so a
  ///   JSON array of objects produces a single entity holding the union of the
  ///   members found in the items
  ///   </para>
  /// </summary>
  TNeonEntityGenerator = class
  private
    FConfig: TNeonEntityConfig;
    FWarnings: TStrings;
    FRoot: TNeonTypeNode;
    FRootTypeName: string;
    FEntities: TList<TNeonTypeNode>;
    FCollected: TDictionary<TNeonTypeNode, Boolean>;
    FSignatures: TDictionary<string, TNeonTypeNode>;
    FUsedNames: TDictionary<string, Boolean>;
    FUsesGenerics: Boolean;
    FUsesAttributes: Boolean;
    FUsesNullables: Boolean;

    procedure AddWarning(const AMessage: string);

    { Inference }

    /// <summary>
    ///   Refines the type of ANode with one more sample. APath is the position
    ///   of the sample in the document, and is only used to report conflicts
    /// </summary>
    procedure Infer(ANode: TNeonTypeNode; AJSON: TJSONValue; const APath: string);
    function KindOf(AJSON: TJSONValue): TNeonJSONKind;

    { Naming }

    /// <summary>
    ///   Runs the naming pass over the tree and collects the entities to emit.
    ///   Called by every Generate* method, so that a configuration change after
    ///   the parsing is still taken into account
    /// </summary>
    procedure Prepare;
    procedure AssignNames(ANode: TNeonTypeNode; const ABaseName: string);
    procedure CollectEntities(ANode: TNeonTypeNode);

    /// <summary>
    ///   A textual description of the structure of a node, equal for two nodes
    ///   that can share one generated entity
    /// </summary>
    function Signature(ANode: TNeonTypeNode): string;

    function UniqueTypeName(const ABaseName: string): string;
    function MakeMemberName(const AJSONName: string; AUsed: TDictionary<string, Boolean>;
      out AEscaped: Boolean): string;

    { Emission }

    /// <summary>
    ///   The Delphi type of a position, registering along the way the units the
    ///   generated code will have to use
    /// </summary>
    function DelphiType(ANode: TNeonTypeNode; AOptional: Boolean; const APath: string): string;
    function ScalarType(ANode: TNeonTypeNode; const APath: string): string;
    function ArrayType(ANode: TNeonTypeNode; const APath: string): string;

    /// <summary>
    ///   True for members the owning class has to create and destroy: nested
    ///   entities and the list containers
    /// </summary>
    function IsOwned(ANode: TNeonTypeNode): Boolean;
    function NeedsLifetime(ANode: TNeonTypeNode): Boolean;

    procedure WriteEntity(ABuilder: TStringBuilder; ANode: TNeonTypeNode);
    procedure WriteEntityImpl(ABuilder: TStringBuilder; ANode: TNeonTypeNode);
    procedure WriteMember(ABuilder: TStringBuilder; ANode: TNeonTypeNode;
      AMember: TNeonEntityMember; const AIndent: string);

    function Indent(ALevel: Integer): string;
    function UsesClause: string;
    function Header: string;
  public
    constructor Create; overload;
    constructor Create(const AConfig: TNeonEntityConfig); overload;
    destructor Destroy; override;

    /// <summary>
    ///   Reads a JSON document, replacing any document read before
    /// </summary>
    procedure ParseValue(AJSON: TJSONValue);

    /// <summary>
    ///   Reads a JSON document from its textual form
    /// </summary>
    procedure Parse(const AJSON: string);

    /// <summary>
    ///   Adds one more sample to the document already read, so that entities
    ///   can be generated from a set of documents (several responses of the
    ///   same endpoint, for instance) instead of a single one
    /// </summary>
    procedure AddSample(const AJSON: string); overload;
    procedure AddSample(AJSON: TJSONValue); overload;

    /// <summary>
    ///   The type declarations, starting with the "type" keyword
    /// </summary>
    function GenerateTypes: string;

    /// <summary>
    ///   The bodies of the constructors and destructors of the generated
    ///   classes, empty when no class owns another entity
    /// </summary>
    function GenerateImplementation: string;

    /// <summary>
    ///   A complete, compilable unit
    /// </summary>
    function GenerateUnit(const AUnitName: string): string;

    /// <summary>
    ///   The Delphi type of the root of the document, available after any of
    ///   the Generate* methods has run. It is the name of an entity for an
    ///   object, and the name of the list alias for an array
    /// </summary>
    property RootTypeName: string read FRootTypeName;

    /// <summary>
    ///   What the document could not tell: type conflicts, positions with no
    ///   samples at all. Never fatal, always worth a look at the generated code
    /// </summary>
    property Warnings: TStrings read FWarnings;

    property Config: TNeonEntityConfig read FConfig write FConfig;
  public
    class function JSONToTypes(const AJSON: string): string; overload; static;
    class function JSONToTypes(const AJSON: string; const AConfig: TNeonEntityConfig): string; overload; static;
    class function JSONToUnit(const AJSON, AUnitName: string): string; overload; static;
    class function JSONToUnit(const AJSON, AUnitName: string; const AConfig: TNeonEntityConfig): string; overload; static;
  end;

implementation

uses
  System.RegularExpressions;

const
  /// <summary>
  ///   Delphi reserved words: a member named after one of these is emitted as
  ///   an escaped identifier (&amp;Type)
  /// </summary>
  RESERVED_WORDS: array[0..64] of string = (
    'and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const',
    'constructor', 'destructor', 'dispinterface', 'div', 'do', 'downto',
    'else', 'end', 'except', 'exports', 'file', 'finalization', 'finally',
    'for', 'function', 'goto', 'if', 'implementation', 'in', 'inherited',
    'initialization', 'inline', 'interface', 'is', 'label', 'library', 'mod',
    'nil', 'not', 'object', 'of', 'or', 'out', 'packed', 'procedure',
    'program', 'property', 'raise', 'record', 'repeat', 'resourcestring',
    'set', 'shl', 'shr', 'string', 'then', 'threadvar', 'to', 'try', 'type',
    'unit', 'until', 'uses', 'var', 'while', 'with', 'xor'
  );

  /// <summary>
  ///   Names already taken by TObject (or by the generated lifetime methods):
  ///   escaping does not help here, the member has to be renamed
  /// </summary>
  RESERVED_MEMBERS: array[0..14] of string = (
    'create', 'destroy', 'free', 'disposeof', 'classname', 'classtype',
    'classinfo', 'classparent', 'instancesize', 'dispatch', 'tostring',
    'equals', 'gethashcode', 'unitname', 'qualifiedclassname'
  );

  /// <summary>
  ///   Date, date/time with an optional time zone, and time. Deliberately
  ///   strict: anything looser starts turning identifiers and codes into dates
  /// </summary>
  ISO_DATETIME_PATTERN =
    '^(\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d{1,9})?)?(Z|[+-]\d{2}:?\d{2})?)?' +
    '|\d{2}:\d{2}:\d{2}(\.\d{1,9})?)$';

/// <summary>
///   Parses a JSON document, raising the exception of the library instead of
///   returning nil on a malformed one. The generator needs a parser and nothing
///   else, which is why it does not go through the serialization engine
/// </summary>
function ParseJSONText(const AJSON: string): TJSONValue;
begin
{$IFDEF HAS_JSON_BOOL}
  Result := TJSONObject.ParseJSONValue(AJSON, True);
{$ELSE}
  Result := TJSONObject.ParseJSONValue(AJSON);
{$ENDIF}
  if not Assigned(Result) then
    raise ENeonException.Create(SNeonErrorParse);
end;

function IsReservedWord(const AName: string): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  LName := LowerCase(AName);
  for LIndex := Low(RESERVED_WORDS) to High(RESERVED_WORDS) do
    if RESERVED_WORDS[LIndex] = LName then
      Exit(True);
  Result := False;
end;

function IsReservedMember(const AName: string): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  LName := LowerCase(AName);
  for LIndex := Low(RESERVED_MEMBERS) to High(RESERVED_MEMBERS) do
    if RESERVED_MEMBERS[LIndex] = LName then
      Exit(True);
  Result := False;
end;

function IsDateTimeString(const AValue: string): Boolean;
begin
  Result := (Length(AValue) >= 8) and TRegEx.IsMatch(AValue, ISO_DATETIME_PATTERN);
end;

/// <summary>
///   Splits an identifier into the words it is made of, whatever convention it
///   follows: separators (anything that is not a letter or a digit) and case
///   transitions both start a new word
/// </summary>
function SplitWords(const AName: string): TArray<string>;
var
  LIndex: Integer;
  LChar: Char;
  LWord: string;
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LWord := '';
    for LIndex := 1 to Length(AName) do
    begin
      LChar := AName[LIndex];

      if not (LChar.IsLetterOrDigit) then
      begin
        if LWord <> '' then
          LList.Add(LWord);
        LWord := '';
        Continue;
      end;

      if (LWord <> '') and LChar.IsUpper then
      begin
        // "userName" -> "user" | "Name", and "JSONValue" -> "JSON" | "Value",
        // where the word breaks on the last uppercase of the run
        if not LWord[Length(LWord)].IsUpper then
        begin
          LList.Add(LWord);
          LWord := '';
        end
        else if (LIndex < Length(AName)) and AName[LIndex + 1].IsLower then
        begin
          LList.Add(LWord);
          LWord := '';
        end;
      end;

      LWord := LWord + LChar;
    end;

    if LWord <> '' then
      LList.Add(LWord);

    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

/// <summary>
///   Joins the words of a name in PascalCase. A word written all in uppercase
///   is an acronym and is folded ("USER_ID" -> "UserId"), a word that is not is
///   left alone but for its first letter
/// </summary>
function ToPascalCase(const AName: string): string;
var
  LWords: TArray<string>;
  LWord: string;
  LIndex: Integer;
begin
  Result := '';
  LWords := SplitWords(AName);
  for LIndex := Low(LWords) to High(LWords) do
  begin
    LWord := LWords[LIndex];
    if LWord = UpperCase(LWord) then
      LWord := UpperCase(LWord[1]) + LowerCase(Copy(LWord, 2, MaxInt))
    else
      LWord := UpperCase(LWord[1]) + Copy(LWord, 2, MaxInt);
    Result := Result + LWord;
  end;
end;

/// <summary>
///   Keeps every character that is legal in a Delphi identifier and replaces
///   the others with an underscore
/// </summary>
function ToIdentifier(const AName: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AName) do
    if AName[LIndex].IsLetterOrDigit or (AName[LIndex] = '_') then
      Result := Result + AName[LIndex]
    else
      Result := Result + '_';
end;

/// <summary>
///   The singular of the name of a collection, used to name the entity
///   generated for its items ("Addresses" -> "Address"). Only the regular
///   English forms are handled: an unknown form is left as it is, which costs
///   nothing but a plural type name
/// </summary>
function Singularize(const AName: string): string;
var
  LName: string;
begin
  Result := AName;
  if Length(Result) < 3 then
    Exit;

  LName := LowerCase(Result);

  if EndsStr('ies', LName) then
    Result := Copy(Result, 1, Length(Result) - 3) + 'y'
  else if EndsStr('sses', LName) or EndsStr('shes', LName) or
          EndsStr('ches', LName) or EndsStr('xes', LName) or
          EndsStr('zes', LName) then
    Result := Copy(Result, 1, Length(Result) - 2)
  else if EndsStr('ss', LName) or EndsStr('us', LName) or EndsStr('is', LName) then
    // "Address", "Status", "Analysis": already singular
  else if EndsStr('s', LName) then
    Result := Copy(Result, 1, Length(Result) - 1);
end;

function QuotedJSONName(const AName: string): string;
begin
  Result := StringReplace(AName, '''', '''''', [rfReplaceAll]);
end;

{ TNeonEntityConfig }

class function TNeonEntityConfig.Default: TNeonEntityConfig;
begin
  Result.EntityKind := TNeonEntityKind.Classes;
  Result.ArrayKind := TNeonArrayKind.ObjectList;
  Result.NameCase := TNeonNameCase.Pascal;
  Result.TypePrefix := 'T';
  Result.RootName := 'Root';
  Result.UnknownType := 'string';
  Result.IndentSize := 2;
  Result.UseNeonProperty := True;
  Result.UseNullables := False;
  Result.DetectDateTime := True;
  Result.MergeEqualTypes := True;
  Result.GenerateLifetime := True;
  Result.WriteHeader := True;
end;

class function TNeonEntityConfig.Records: TNeonEntityConfig;
begin
  Result := TNeonEntityConfig.Default;
  Result.EntityKind := TNeonEntityKind.Records;
  Result.ArrayKind := TNeonArrayKind.DynamicArray;
end;

function TNeonEntityConfig.SetArrayKind(AValue: TNeonArrayKind): TNeonEntityConfig;
begin
  ArrayKind := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetDetectDateTime(AValue: Boolean): TNeonEntityConfig;
begin
  DetectDateTime := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetEntityKind(AValue: TNeonEntityKind): TNeonEntityConfig;
begin
  EntityKind := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetGenerateLifetime(AValue: Boolean): TNeonEntityConfig;
begin
  GenerateLifetime := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetIndentSize(AValue: Integer): TNeonEntityConfig;
begin
  IndentSize := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetMergeEqualTypes(AValue: Boolean): TNeonEntityConfig;
begin
  MergeEqualTypes := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetNameCase(AValue: TNeonNameCase): TNeonEntityConfig;
begin
  NameCase := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetRootName(const AValue: string): TNeonEntityConfig;
begin
  RootName := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetTypePrefix(const AValue: string): TNeonEntityConfig;
begin
  TypePrefix := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetUnknownType(const AValue: string): TNeonEntityConfig;
begin
  UnknownType := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetUseNeonProperty(AValue: Boolean): TNeonEntityConfig;
begin
  UseNeonProperty := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetUseNullables(AValue: Boolean): TNeonEntityConfig;
begin
  UseNullables := AValue;
  Result := Self;
end;

function TNeonEntityConfig.SetWriteHeader(AValue: Boolean): TNeonEntityConfig;
begin
  WriteHeader := AValue;
  Result := Self;
end;

{ TNeonEntityMember }

constructor TNeonEntityMember.Create(const AJSONName: string);
begin
  inherited Create;
  FJSONName := AJSONName;
  FNode := TNeonTypeNode.Create;
end;

destructor TNeonEntityMember.Destroy;
begin
  FNode.Free;
  inherited Destroy;
end;

function TNeonEntityMember.DeclaredName: string;
begin
  if FEscaped then
    Result := '&' + FName
  else
    Result := FName;
end;

function TNeonEntityMember.FieldName: string;
begin
  Result := 'F' + FName;
end;

{ TNeonTypeNode }

constructor TNeonTypeNode.Create;
begin
  inherited Create;
  FKind := TNeonJSONKind.Unknown;
  FMembers := TObjectList<TNeonEntityMember>.Create(True);
  FIndex := TDictionary<string, TNeonEntityMember>.Create;
  FCanonical := Self;
end;

destructor TNeonTypeNode.Destroy;
begin
  FItemType.Free;
  FIndex.Free;
  FMembers.Free;
  inherited Destroy;
end;

function TNeonTypeNode.AddMember(const AJSONName: string): TNeonEntityMember;
begin
  Result := TNeonEntityMember.Create(AJSONName);
  FMembers.Add(Result);
  FIndex.Add(AJSONName, Result);
end;

function TNeonTypeNode.EnsureItemType: TNeonTypeNode;
begin
  if not Assigned(FItemType) then
    FItemType := TNeonTypeNode.Create;
  Result := FItemType;
end;

function TNeonTypeNode.FindMember(const AJSONName: string): TNeonEntityMember;
begin
  if not FIndex.TryGetValue(AJSONName, Result) then
    Result := nil;
end;

function TNeonTypeNode.IsOptional(AMember: TNeonEntityMember): Boolean;
begin
  Result := AMember.SampleCount < FSampleCount;
end;

{ TNeonEntityGenerator }

constructor TNeonEntityGenerator.Create;
begin
  Create(TNeonEntityConfig.Default);
end;

constructor TNeonEntityGenerator.Create(const AConfig: TNeonEntityConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FWarnings := TStringList.Create;
  FEntities := TList<TNeonTypeNode>.Create;
  FCollected := TDictionary<TNeonTypeNode, Boolean>.Create;
  FSignatures := TDictionary<string, TNeonTypeNode>.Create;
  FUsedNames := TDictionary<string, Boolean>.Create;
end;

destructor TNeonEntityGenerator.Destroy;
begin
  FRoot.Free;
  FUsedNames.Free;
  FSignatures.Free;
  FCollected.Free;
  FEntities.Free;
  FWarnings.Free;
  inherited Destroy;
end;

procedure TNeonEntityGenerator.AddWarning(const AMessage: string);
begin
  if FWarnings.IndexOf(AMessage) < 0 then
    FWarnings.Add(AMessage);
end;

procedure TNeonEntityGenerator.Parse(const AJSON: string);
var
  LJSON: TJSONValue;
begin
  LJSON := ParseJSONText(AJSON);
  try
    ParseValue(LJSON);
  finally
    LJSON.Free;
  end;
end;

procedure TNeonEntityGenerator.ParseValue(AJSON: TJSONValue);
begin
  FreeAndNil(FRoot);
  FWarnings.Clear;
  AddSample(AJSON);
end;

procedure TNeonEntityGenerator.AddSample(const AJSON: string);
var
  LJSON: TJSONValue;
begin
  LJSON := ParseJSONText(AJSON);
  try
    AddSample(LJSON);
  finally
    LJSON.Free;
  end;
end;

procedure TNeonEntityGenerator.AddSample(AJSON: TJSONValue);
begin
  if not Assigned(AJSON) then
    raise ENeonException.Create(SNeonErrorGenNoSample);

  if not Assigned(FRoot) then
    FRoot := TNeonTypeNode.Create;

  Infer(FRoot, AJSON, '');
end;

function TNeonEntityGenerator.KindOf(AJSON: TJSONValue): TNeonJSONKind;
var
  LText: string;
  LValue: Int64;
begin
  if AJSON is TJSONObject then
    Result := TNeonJSONKind.Obj
  else if AJSON is TJSONArray then
    Result := TNeonJSONKind.Arr
  else if TJSONUtils.IsBool(AJSON) then
    Result := TNeonJSONKind.Bool
  else if AJSON is TJSONNumber then
  begin
    LText := (AJSON as TJSONNumber).Value;
    // The lexical form is what tells an integer from a float: a JSON document
    // writing 1.0 is describing a floating point member
    if (Pos('.', LText) > 0) or (Pos('e', LowerCase(LText)) > 0) or
       not TryStrToInt64(LText, LValue) then
      Result := TNeonJSONKind.Float
    else
      Result := TNeonJSONKind.Int;
  end
  else
    Result := TNeonJSONKind.Str;
end;

procedure TNeonEntityGenerator.Infer(ANode: TNeonTypeNode; AJSON: TJSONValue;
  const APath: string);
var
  LKind: TNeonJSONKind;
  LIndex: Integer;
  LPair: TJSONPair;
  LObject: TJSONObject;
  LArray: TJSONArray;
  LMember: TNeonEntityMember;
  LValue: Int64;
  LPosition: string;
begin
  if ANode.Conflict then
    Exit;

  if (AJSON = nil) or (AJSON is TJSONNull) then
  begin
    ANode.Nullable := True;
    Exit;
  end;

  LPosition := IfThen(APath = '', '(root)', APath);
  LKind := KindOf(AJSON);

  if ANode.Kind = TNeonJSONKind.Unknown then
  begin
    ANode.Kind := LKind;
    // Optimistic: the flags below can only be narrowed by the samples to come
    ANode.IsDateTime := LKind = TNeonJSONKind.Str;
  end
  else if ANode.Kind <> LKind then
  begin
    if (ANode.Kind = TNeonJSONKind.Int) and (LKind = TNeonJSONKind.Float) then
      ANode.Kind := TNeonJSONKind.Float
    else if (ANode.Kind = TNeonJSONKind.Float) and (LKind = TNeonJSONKind.Int) then
      // an integer sample of a member already known to be floating point
    else
    begin
      ANode.Conflict := True;
      ANode.Kind := TNeonJSONKind.Unknown;
      AddWarning(Format(SNeonWarnGenConflictF2, [LPosition, FConfig.UnknownType]));
      Exit;
    end;
  end;

  case ANode.Kind of
    TNeonJSONKind.Str:
      ANode.IsDateTime := ANode.IsDateTime and FConfig.DetectDateTime and
        IsDateTimeString(AJSON.Value);

    TNeonJSONKind.Int:
      if TryStrToInt64((AJSON as TJSONNumber).Value, LValue) and
         ((LValue > High(Integer)) or (LValue < Low(Integer))) then
        ANode.IsInt64 := True;

    TNeonJSONKind.Obj:
    begin
      LObject := AJSON as TJSONObject;
      ANode.SampleCount := ANode.SampleCount + 1;
      for LIndex := 0 to LObject.Count - 1 do
      begin
        LPair := LObject.Pairs[LIndex];
        LMember := ANode.FindMember(LPair.JsonString.Value);
        if not Assigned(LMember) then
          LMember := ANode.AddMember(LPair.JsonString.Value);
        LMember.SampleCount := LMember.SampleCount + 1;
        Infer(LMember.Node, LPair.JsonValue, APath + '/' + LPair.JsonString.Value);
      end;
    end;

    TNeonJSONKind.Arr:
    begin
      LArray := AJSON as TJSONArray;
      ANode.SampleCount := ANode.SampleCount + 1;
      for LIndex := 0 to LArray.Count - 1 do
        Infer(ANode.EnsureItemType, LArray.Items[LIndex], APath + '[]');
    end;
  end;
end;

function TNeonEntityGenerator.Signature(ANode: TNeonTypeNode): string;
var
  LIndex: Integer;
  LMember: TNeonEntityMember;
  LBuilder: TStringBuilder;
begin
  if not Assigned(ANode) then
    Exit('?');

  case ANode.Kind of
    TNeonJSONKind.Obj:
    begin
      LBuilder := TStringBuilder.Create;
      try
        LBuilder.Append('{');
        for LIndex := 0 to ANode.Members.Count - 1 do
        begin
          LMember := ANode.Members[LIndex];
          if LIndex > 0 then
            LBuilder.Append(',');
          LBuilder.Append(LMember.JSONName).Append(':').Append(Signature(LMember.Node));
          if ANode.IsOptional(LMember) then
            LBuilder.Append('?');
        end;
        LBuilder.Append('}');
        Result := LBuilder.ToString;
      finally
        LBuilder.Free;
      end;
    end;

    TNeonJSONKind.Arr:
      Result := '[' + Signature(ANode.ItemType) + ']';
  else
    Result := Format('%d.%d.%d', [Ord(ANode.Kind), Ord(ANode.IsDateTime), Ord(ANode.IsInt64)]);
  end;

  if ANode.Nullable then
    Result := Result + '!';
end;

function TNeonEntityGenerator.UniqueTypeName(const ABaseName: string): string;
var
  LSuffix: Integer;
begin
  Result := ABaseName;
  LSuffix := 1;
  while FUsedNames.ContainsKey(UpperCase(Result)) do
  begin
    Inc(LSuffix);
    Result := ABaseName + IntToStr(LSuffix);
  end;
  FUsedNames.Add(UpperCase(Result), True);
end;

function TNeonEntityGenerator.MakeMemberName(const AJSONName: string;
  AUsed: TDictionary<string, Boolean>; out AEscaped: Boolean): string;
var
  LBase: string;
  LSuffix: Integer;
begin
  case FConfig.NameCase of
    TNeonNameCase.Pascal: Result := ToPascalCase(AJSONName);
  else
    Result := ToIdentifier(AJSONName);
  end;

  if Result = '' then
    Result := '_';
  if Result[1].IsDigit then
    Result := '_' + Result;

  // A member named after a TObject method cannot be escaped out of the way:
  // whatever the source says, the two would still collide
  if (FConfig.EntityKind = TNeonEntityKind.Classes) and IsReservedMember(Result) then
    Result := Result + '_';

  LBase := Result;
  LSuffix := 1;
  while AUsed.ContainsKey(UpperCase(Result)) do
  begin
    Inc(LSuffix);
    Result := LBase + IntToStr(LSuffix);
  end;
  AUsed.Add(UpperCase(Result), True);

  AEscaped := IsReservedWord(Result);
end;

procedure TNeonEntityGenerator.AssignNames(ANode: TNeonTypeNode; const ABaseName: string);
var
  LIndex: Integer;
  LMember: TNeonEntityMember;
  LSignature: string;
  LCanonical: TNeonTypeNode;
  LUsed: TDictionary<string, Boolean>;
  LEscaped: Boolean;
begin
  if not Assigned(ANode) then
    Exit;

  case ANode.Kind of
    TNeonJSONKind.Obj:
    begin
      LSignature := Signature(ANode);
      if FConfig.MergeEqualTypes and FSignatures.TryGetValue(LSignature, LCanonical) then
      begin
        ANode.Canonical := LCanonical;
        Exit;
      end;

      ANode.Canonical := ANode;
      ANode.TypeName := UniqueTypeName(FConfig.TypePrefix + ToPascalCase(ABaseName));
      FSignatures.AddOrSetValue(LSignature, ANode);

      LUsed := TDictionary<string, Boolean>.Create;
      try
        for LIndex := 0 to ANode.Members.Count - 1 do
        begin
          LMember := ANode.Members[LIndex];
          LMember.Name := MakeMemberName(LMember.JSONName, LUsed, LEscaped);
          LMember.Escaped := LEscaped;
          AssignNames(LMember.Node, LMember.JSONName);
        end;
      finally
        LUsed.Free;
      end;
    end;

    TNeonJSONKind.Arr:
      AssignNames(ANode.ItemType, Singularize(ABaseName));
  end;
end;

procedure TNeonEntityGenerator.CollectEntities(ANode: TNeonTypeNode);
var
  LIndex: Integer;
  LCanonical: TNeonTypeNode;
begin
  if not Assigned(ANode) then
    Exit;

  case ANode.Kind of
    TNeonJSONKind.Obj:
    begin
      LCanonical := ANode.Canonical;
      if FCollected.ContainsKey(LCanonical) then
        Exit;

      // Members first: a JSON document cannot describe a cycle, so emitting the
      // entities in this order is enough to make forward declarations useless
      for LIndex := 0 to LCanonical.Members.Count - 1 do
        CollectEntities(LCanonical.Members[LIndex].Node);

      FCollected.Add(LCanonical, True);
      FEntities.Add(LCanonical);
    end;

    TNeonJSONKind.Arr:
      CollectEntities(ANode.ItemType);
  end;
end;

procedure TNeonEntityGenerator.Prepare;
var
  LItem: TNeonTypeNode;
begin
  if not Assigned(FRoot) then
    raise ENeonException.Create(SNeonErrorGenNoDocument);

  FEntities.Clear;
  FCollected.Clear;
  FSignatures.Clear;
  FUsedNames.Clear;
  FUsesGenerics := False;
  FUsesAttributes := False;
  FUsesNullables := False;
  FRootTypeName := '';

  case FRoot.Kind of
    TNeonJSONKind.Obj:
    begin
      AssignNames(FRoot, FConfig.RootName);
      CollectEntities(FRoot);
      FRootTypeName := FRoot.Canonical.TypeName;
    end;

    TNeonJSONKind.Arr:
    begin
      LItem := FRoot.ItemType;
      if Assigned(LItem) and (LItem.Kind = TNeonJSONKind.Obj) then
      begin
        // The items are what the document is about: they take the root name,
        // and the root itself becomes an alias for their container
        AssignNames(LItem, FConfig.RootName);
        CollectEntities(LItem);
        FRootTypeName := UniqueTypeName(FConfig.TypePrefix + ToPascalCase(FConfig.RootName) + 'List');
      end
      else
      begin
        AddWarning(SNeonWarnGenRootNotEntity);
        FRootTypeName := ArrayType(FRoot, '(root)');
      end;
    end;
  else
    AddWarning(SNeonWarnGenRootNotEntity);
    FRootTypeName := DelphiType(FRoot, False, '(root)');
  end;
end;

function TNeonEntityGenerator.ScalarType(ANode: TNeonTypeNode; const APath: string): string;
begin
  case ANode.Kind of
    TNeonJSONKind.Bool: Result := 'Boolean';
    TNeonJSONKind.Int: Result := IfThen(ANode.IsInt64, 'Int64', 'Integer');
    TNeonJSONKind.Float: Result := 'Double';
    TNeonJSONKind.Str: Result := IfThen(ANode.IsDateTime, 'TDateTime', 'string');
  else
    // Nothing in the document says what this is: a member that was always null,
    // or an array that was always empty
    Result := FConfig.UnknownType;
    if ANode.Conflict then
      // already reported, with the position of the conflicting sample
    else
      AddWarning(Format(SNeonWarnGenNoTypeF2, [APath, FConfig.UnknownType]));
  end;
end;

function TNeonEntityGenerator.ArrayType(ANode: TNeonTypeNode; const APath: string): string;
var
  LItem: TNeonTypeNode;
  LItemType: string;
begin
  LItem := ANode.ItemType;
  if not Assigned(LItem) then
  begin
    AddWarning(Format(SNeonWarnGenEmptyArrayF2, [APath, FConfig.UnknownType]));
    Exit('TArray<' + FConfig.UnknownType + '>');
  end;

  LItemType := DelphiType(LItem, False, APath + '[]');

  if (LItem.Kind = TNeonJSONKind.Obj) and (FConfig.EntityKind = TNeonEntityKind.Classes) then
    case FConfig.ArrayKind of
      TNeonArrayKind.ObjectList:
      begin
        FUsesGenerics := True;
        Exit('TObjectList<' + LItemType + '>');
      end;
      TNeonArrayKind.GenericList:
      begin
        FUsesGenerics := True;
        Exit('TList<' + LItemType + '>');
      end;
    end;

  Result := 'TArray<' + LItemType + '>';
end;

function TNeonEntityGenerator.DelphiType(ANode: TNeonTypeNode; AOptional: Boolean;
  const APath: string): string;
begin
  case ANode.Kind of
    TNeonJSONKind.Obj:
      Exit(ANode.Canonical.TypeName);

    TNeonJSONKind.Arr:
      Exit(ArrayType(ANode, APath));
  end;

  Result := ScalarType(ANode, APath);

  // Nullable only makes sense where the Delphi type has no empty state of its
  // own: a class member is already nil when the document says null
  if FConfig.UseNullables and (ANode.Nullable or AOptional) and
     (ANode.Kind <> TNeonJSONKind.Unknown) then
  begin
    FUsesNullables := True;
    Result := 'Nullable<' + Result + '>';
  end;
end;

function TNeonEntityGenerator.IsOwned(ANode: TNeonTypeNode): Boolean;
begin
  if FConfig.EntityKind <> TNeonEntityKind.Classes then
    Exit(False);

  case ANode.Kind of
    TNeonJSONKind.Obj:
      Result := True;
    TNeonJSONKind.Arr:
      Result := Assigned(ANode.ItemType) and (ANode.ItemType.Kind = TNeonJSONKind.Obj) and
        (FConfig.ArrayKind <> TNeonArrayKind.DynamicArray);
  else
    Result := False;
  end;
end;

function TNeonEntityGenerator.NeedsLifetime(ANode: TNeonTypeNode): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if not FConfig.GenerateLifetime then
    Exit;

  for LIndex := 0 to ANode.Members.Count - 1 do
    if IsOwned(ANode.Members[LIndex].Node) then
      Exit(True);
end;

function TNeonEntityGenerator.Indent(ALevel: Integer): string;
begin
  Result := StringOfChar(' ', ALevel * FConfig.IndentSize);
end;

procedure TNeonEntityGenerator.WriteMember(ABuilder: TStringBuilder;
  ANode: TNeonTypeNode; AMember: TNeonEntityMember; const AIndent: string);
var
  LType: string;
begin
  LType := DelphiType(AMember.Node, ANode.IsOptional(AMember),
    ANode.TypeName + '.' + AMember.JSONName);

  if FConfig.UseNeonProperty and (AMember.Name <> AMember.JSONName) then
  begin
    FUsesAttributes := True;
    ABuilder.Append(AIndent).Append('[NeonProperty(''')
      .Append(QuotedJSONName(AMember.JSONName)).AppendLine(''')]');
  end;

  if FConfig.EntityKind = TNeonEntityKind.Records then
    ABuilder.Append(AIndent).Append(AMember.DeclaredName).Append(': ')
      .Append(LType).AppendLine(';')
  else
    ABuilder.Append(AIndent).Append('property ').Append(AMember.DeclaredName)
      .Append(': ').Append(LType)
      .Append(' read ').Append(AMember.FieldName)
      .Append(' write ').Append(AMember.FieldName).AppendLine(';');
end;

procedure TNeonEntityGenerator.WriteEntity(ABuilder: TStringBuilder; ANode: TNeonTypeNode);
var
  LIndex: Integer;
  LMember: TNeonEntityMember;
  LLifetime: Boolean;
begin
  if FConfig.EntityKind = TNeonEntityKind.Records then
  begin
    ABuilder.Append(Indent(1)).Append(ANode.TypeName).AppendLine(' = record');
    for LIndex := 0 to ANode.Members.Count - 1 do
      WriteMember(ABuilder, ANode, ANode.Members[LIndex], Indent(2));
    ABuilder.Append(Indent(1)).AppendLine('end;');
    Exit;
  end;

  LLifetime := NeedsLifetime(ANode);

  ABuilder.Append(Indent(1)).Append(ANode.TypeName).AppendLine(' = class');

  if ANode.Members.Count > 0 then
  begin
    ABuilder.Append(Indent(1)).AppendLine('private');
    for LIndex := 0 to ANode.Members.Count - 1 do
    begin
      LMember := ANode.Members[LIndex];
      ABuilder.Append(Indent(2)).Append(LMember.FieldName).Append(': ')
        .Append(DelphiType(LMember.Node, ANode.IsOptional(LMember),
          ANode.TypeName + '.' + LMember.JSONName)).AppendLine(';');
    end;
    ABuilder.Append(Indent(1)).AppendLine('public');
  end
  else if LLifetime then
    ABuilder.Append(Indent(1)).AppendLine('public');

  if LLifetime then
  begin
    ABuilder.Append(Indent(2)).AppendLine('constructor Create;');
    ABuilder.Append(Indent(2)).AppendLine('destructor Destroy; override;');
    if ANode.Members.Count > 0 then
      ABuilder.AppendLine;
  end;

  for LIndex := 0 to ANode.Members.Count - 1 do
    WriteMember(ABuilder, ANode, ANode.Members[LIndex], Indent(2));

  ABuilder.Append(Indent(1)).AppendLine('end;');
end;

procedure TNeonEntityGenerator.WriteEntityImpl(ABuilder: TStringBuilder; ANode: TNeonTypeNode);
var
  LIndex: Integer;
  LMember: TNeonEntityMember;
  LType: string;
begin
  if not NeedsLifetime(ANode) then
    Exit;

  ABuilder.Append('{ ').Append(ANode.TypeName).AppendLine(' }');
  ABuilder.AppendLine;

  ABuilder.Append('constructor ').Append(ANode.TypeName).AppendLine('.Create;');
  ABuilder.AppendLine('begin');
  ABuilder.Append(Indent(1)).AppendLine('inherited Create;');
  for LIndex := 0 to ANode.Members.Count - 1 do
  begin
    LMember := ANode.Members[LIndex];
    if not IsOwned(LMember.Node) then
      Continue;

    LType := DelphiType(LMember.Node, False, ANode.TypeName + '.' + LMember.JSONName);
    if LMember.Node.Kind = TNeonJSONKind.Obj then
      ABuilder.Append(Indent(1)).Append(LMember.FieldName).Append(' := ')
        .Append(LType).AppendLine('.Create;')
    else if FConfig.ArrayKind = TNeonArrayKind.ObjectList then
      // The list owns its items: freeing it is enough to free the entities
      ABuilder.Append(Indent(1)).Append(LMember.FieldName).Append(' := ')
        .Append(LType).AppendLine('.Create(True);')
    else
      ABuilder.Append(Indent(1)).Append(LMember.FieldName).Append(' := ')
        .Append(LType).AppendLine('.Create;');
  end;
  ABuilder.AppendLine('end;');
  ABuilder.AppendLine;

  ABuilder.Append('destructor ').Append(ANode.TypeName).AppendLine('.Destroy;');
  ABuilder.AppendLine('begin');
  for LIndex := ANode.Members.Count - 1 downto 0 do
  begin
    LMember := ANode.Members[LIndex];
    if IsOwned(LMember.Node) then
      ABuilder.Append(Indent(1)).Append(LMember.FieldName).AppendLine('.Free;');
  end;
  ABuilder.Append(Indent(1)).AppendLine('inherited Destroy;');
  ABuilder.AppendLine('end;');
  ABuilder.AppendLine;
end;

function TNeonEntityGenerator.GenerateTypes: string;
var
  LIndex: Integer;
  LBuilder: TStringBuilder;
  LRootAlias: string;
begin
  Prepare;

  if FEntities.Count = 0 then
    // The document describes no entity at all: see the warnings, and RootTypeName
    // for the Delphi type its root maps to
    Exit('');

  LBuilder := TStringBuilder.Create;
  try
    LBuilder.AppendLine('type');

    for LIndex := 0 to FEntities.Count - 1 do
    begin
      if LIndex > 0 then
        LBuilder.AppendLine;
      WriteEntity(LBuilder, FEntities[LIndex]);
    end;

    // A document whose root is an array is described by the alias, not by the
    // entity generated for its items
    if (FRoot.Kind = TNeonJSONKind.Arr) and (FEntities.Count > 0) then
    begin
      LRootAlias := ArrayType(FRoot, '(root)');
      LBuilder.AppendLine;
      LBuilder.Append(Indent(1)).Append(FRootTypeName).Append(' = ')
        .Append(LRootAlias).AppendLine(';');
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TNeonEntityGenerator.GenerateImplementation: string;
var
  LIndex: Integer;
  LBuilder: TStringBuilder;
begin
  Prepare;

  LBuilder := TStringBuilder.Create;
  try
    for LIndex := 0 to FEntities.Count - 1 do
      WriteEntityImpl(LBuilder, FEntities[LIndex]);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TNeonEntityGenerator.UsesClause: string;
var
  LUnits: TStringList;
begin
  LUnits := TStringList.Create;
  try
    if FUsesGenerics then
      LUnits.Add('System.Generics.Collections');
    if FUsesNullables then
      LUnits.Add('Neon.Core.Nullables');
    if FUsesAttributes then
      LUnits.Add('Neon.Core.Attributes');

    if LUnits.Count = 0 then
      Exit('');

    Result := 'uses' + sLineBreak + Indent(1) +
      string.Join(', ', LUnits.ToStringArray) + ';' + sLineBreak + sLineBreak;
  finally
    LUnits.Free;
  end;
end;

function TNeonEntityGenerator.Header: string;
begin
  Result :=
    '{******************************************************************************}' + sLineBreak +
    '{                                                                              }' + sLineBreak +
    '{  Entities generated from a JSON document by Neon                             }' + sLineBreak +
    '{  https://github.com/paolo-rossi/neon-library                                 }' + sLineBreak +
    '{                                                                              }' + sLineBreak +
    '{  Changes made here are lost the next time the unit is generated              }' + sLineBreak +
    '{                                                                              }' + sLineBreak +
    '{******************************************************************************}' + sLineBreak;
end;

function TNeonEntityGenerator.GenerateUnit(const AUnitName: string): string;
var
  LBuilder: TStringBuilder;
  LTypes, LImplementation: string;
begin
  // The types are emitted last on purpose: writing them is what tells which
  // units the generated code needs, and only that pass walks every member
  LImplementation := GenerateImplementation;
  LTypes := GenerateTypes;

  LBuilder := TStringBuilder.Create;
  try
    if FConfig.WriteHeader then
      LBuilder.Append(Header);

    LBuilder.Append('unit ').Append(AUnitName).AppendLine(';');
    LBuilder.AppendLine;
    LBuilder.AppendLine('interface');
    LBuilder.AppendLine;
    LBuilder.Append(UsesClause);
    LBuilder.Append(LTypes);
    LBuilder.AppendLine;
    LBuilder.AppendLine('implementation');
    LBuilder.AppendLine;
    LBuilder.Append(LImplementation);
    LBuilder.AppendLine('end.');

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TNeonEntityGenerator.JSONToTypes(const AJSON: string): string;
begin
  Result := JSONToTypes(AJSON, TNeonEntityConfig.Default);
end;

class function TNeonEntityGenerator.JSONToTypes(const AJSON: string;
  const AConfig: TNeonEntityConfig): string;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create(AConfig);
  try
    LGenerator.Parse(AJSON);
    Result := LGenerator.GenerateTypes;
  finally
    LGenerator.Free;
  end;
end;

class function TNeonEntityGenerator.JSONToUnit(const AJSON, AUnitName: string): string;
begin
  Result := JSONToUnit(AJSON, AUnitName, TNeonEntityConfig.Default);
end;

class function TNeonEntityGenerator.JSONToUnit(const AJSON, AUnitName: string;
  const AConfig: TNeonEntityConfig): string;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create(AConfig);
  try
    LGenerator.Parse(AJSON);
    Result := LGenerator.GenerateUnit(AUnitName);
  finally
    LGenerator.Free;
  end;
end;

end.
