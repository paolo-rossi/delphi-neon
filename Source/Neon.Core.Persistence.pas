{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Persistence;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.JSON, System.Generics.Defaults,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.DynamicTypes;

{$SCOPEDENUMS ON}

type
  TNeonSerializerRegistry = class;
  TNeonRttiObject = class;

  INeonConfiguration = interface
  ['{F82AB790-1C65-4501-915C-0289EFD9D8CC}']
    function SetMembers(AValue: TNeonMembersSet): INeonConfiguration;
    function SetMemberCase(AValue: TNeonCase): INeonConfiguration;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguration;
    function SetVisibility(AValue: TNeonVisibility): INeonConfiguration;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguration;
    function SetUseUTCDate(AValue: Boolean): INeonConfiguration;
    function SetPrettyPrint(AValue: Boolean): INeonConfiguration;

    function GetPrettyPrint: Boolean;
    function GetUseUTCDate: Boolean;
    function GetSerializers: TNeonSerializerRegistry;
  end;

  IConfigurationContext = interface
  ['{3954FFB5-2D3D-4978-AADA-FEC5C0D73FD0}']
    function GetConfiguration: INeonConfiguration;
  end;

  ISerializerContext = interface(IConfigurationContext)
  ['{36A014FC-9E3F-4EBF-9545-CF9DBCBF507C}']
    function WriteDataMember(const AValue: TValue): TJSONValue;
  end;

  IDeserializerContext = interface(IConfigurationContext)
  ['{5351D1F9-99B3-4826-B981-4CBF926085D6}']
    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
  end;

  TCustomSerializer = class abstract(TObject)
  protected
    class function GetTargetInfo: PTypeInfo; virtual;
    class function CanHandle(AType: PTypeInfo): Boolean; virtual; abstract;
  protected
    class function ClassDistance: Integer;
    class function ClassIs(AClass: TClass): Boolean;
    class function TypeInfoIs(AInfo: PTypeInfo): Boolean;
    class function TypeInfoIsClass(AInfo: PTypeInfo): Boolean;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; virtual; abstract;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; virtual; abstract;
  end;

  TCustomSerializerClass = class of TCustomSerializer;

  TSerializerInfo = record
  public
    SerializerClass: TCustomSerializerClass;
    Distance: Integer;
  public
    class function FromSerializer(ASerializerClass: TCustomSerializerClass): TSerializerInfo; static;
  end;

  TNeonSerializerRegistry = class
  private type
    SerializerCacheRegistry = class(TObjectDictionary<PTypeInfo, TCustomSerializer>);
    SerializerClassRegistry = class(TList<TSerializerInfo>);
  private
    FRegistryClass: SerializerClassRegistry;
    FRegistryCache: SerializerCacheRegistry;
    function GetCount: Integer;

    function InternalGetSerializer(ATypeInfo: PTypeInfo): TCustomSerializer;
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure Clear;
    procedure ClearCache;
    procedure Assign(ARegistry: TNeonSerializerRegistry);

    function RegisterSerializer(ASerializerClass: TCustomSerializerClass): TNeonSerializerRegistry; overload;
    procedure UnregisterSerializer(ASerializerClass: TCustomSerializerClass);

    function GetSerializer<T>: TCustomSerializer; overload;
    function GetSerializer(AValue: TValue): TCustomSerializer; overload;
    function GetSerializer(ATargetClass: TClass): TCustomSerializer; overload;
    function GetSerializer(ATargetInfo: PTypeInfo): TCustomSerializer; overload;

  public
    property Count: Integer read GetCount;
  end;

  TCaseAlgorithm = class
  public
    class function PascalToCamel(const AString: string): string;
    class function CamelToPascal(const AString: string): string;
    class function PascalToSnake(const AString: string): string;
    class function SnakeToPascal(const AString: string): string;
  end;

  TNeonConfiguration = class sealed(TInterfacedObject, INeonConfiguration)
  private
    FVisibility: TNeonVisibility;
    FMembers: TNeonMembersSet;
    FMemberCase: TNeonCase;
    FMemberCustomCase: TCaseFunc;
    FIgnoreFieldPrefix: Boolean;
    FUseUTCDate: Boolean;
    FPrettyPrint: Boolean;
    FSerializers: TNeonSerializerRegistry;
  public
    constructor Create;
    destructor Destroy; override;

    class function Default: INeonConfiguration; static;
    class function Pretty: INeonConfiguration; static;
    class function Snake: INeonConfiguration; static;
    class function Camel: INeonConfiguration; static;

    function SetMembers(AValue: TNeonMembersSet): INeonConfiguration;
    function SetMemberCase(AValue: TNeonCase): INeonConfiguration;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguration;
    function SetVisibility(AValue: TNeonVisibility): INeonConfiguration;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguration;
    function SetUseUTCDate(AValue: Boolean): INeonConfiguration;
    function SetPrettyPrint(AValue: Boolean): INeonConfiguration;

    function GetUseUTCDate: Boolean;
    function GetPrettyPrint: Boolean;
    function GetSerializers: TNeonSerializerRegistry;

    property Members: TNeonMembersSet read FMembers write FMembers;
    property MemberCase: TNeonCase read FMemberCase write FMemberCase;
    property MemberCustomCase: TCaseFunc read FMemberCustomCase write FMemberCustomCase;
    property Visibility: TNeonVisibility read FVisibility write FVisibility;
    property IgnoreFieldPrefix: Boolean read FIgnoreFieldPrefix write FIgnoreFieldPrefix;
    property UseUTCDate: Boolean read FUseUTCDate write FUseUTCDate;
    property Serializers: TNeonSerializerRegistry read FSerializers write FSerializers;
  end;

  TNeonRttiObject = class
  protected
    FOperation: TNeonOperation;
    FRttiObject: TRttiObject;
    FNeonInclude: TIncludeValue;
    FAttributes: TArray<TCustomAttribute>;
    FNeonMembers: TNeonMembersSet;
    FNeonVisibility: TNeonVisibility;
    FNeonIgnore: Boolean;
    FNeonProperty: string;
    FNeonEnumNames: TArray<string>;
    FNeonSerializerName: string;
    FNeonSerializerClass: TClass;
  private
    FTypeAttributes: TArray<TCustomAttribute>;
  protected
    procedure InternalParseAttributes(const AAttr: TArray<TCustomAttribute>); virtual;
    procedure ProcessAttribute(AAttribute: TCustomAttribute); virtual;

    function AsRttiType: TRttiType;
  public
    constructor Create(ARttiObject: TRttiObject; AOperation: TNeonOperation);
  public
    procedure ParseAttributes; virtual;

    property Attributes: TArray<TCustomAttribute> read FAttributes write FAttributes;
    property TypeAttributes: TArray<TCustomAttribute> read FTypeAttributes write FTypeAttributes;
    // Neon-based properties
    property NeonIgnore: Boolean read FNeonIgnore write FNeonIgnore;
    property NeonInclude: TIncludeValue read FNeonInclude write FNeonInclude;
    property NeonSerializerName: string read FNeonSerializerName write FNeonSerializerName;
    property NeonSerializerClass: TClass read FNeonSerializerClass write FNeonSerializerClass;
    property NeonProperty: string read FNeonProperty write FNeonProperty;
    property NeonEnumNames: TArray<string> read FNeonEnumNames write FNeonEnumNames;
    property NeonMembers: TNeonMembersSet read FNeonMembers write FNeonMembers;
    property NeonVisibility: TNeonVisibility read FNeonVisibility write FNeonVisibility;
  end;

  TNeonRttiType = class(TNeonRttiObject)
  private
    FType: TRttiType;
    FInstance: Pointer;
  public
    constructor Create(AInstance: Pointer; AType: TRttiType; AOperation: TNeonOperation);
    property Instance: Pointer read FInstance write FInstance;
  end;

  TNeonRttiMember = class(TNeonRttiObject)
  private
    FMemberType: TNeonMemberType;
    FMemberRttiType: TRttiType;
    FMember: TRttiMember;
    FParent: TNeonRttiType;
    FSerializable: Boolean;

    function MemberAsProperty: TRttiProperty; inline;
    function MemberAsField: TRttiField; inline;
    function GetName: string;
  protected
    FNeonIncludeIf: TNeonIncludeOption;

    procedure ProcessAttribute(AAttribute: TCustomAttribute); override;
  public
    constructor Create(AMember: TRttiMember; AParent: TNeonRttiType; AOperation: TNeonOperation);

    function GetValue: TValue;
    procedure SetValue(const AValue: TValue);
    function RttiType: TRttiType;
    function MemberType: TNeonMemberType;
    function IsWritable: Boolean;
    function IsReadable: Boolean;
    function TypeKind: TTypeKind;
    function Visibility: TMemberVisibility;
    function IsField: Boolean;
    function IsProperty: Boolean;

    property Name: string read GetName;

    property NeonIncludeIf: TNeonIncludeOption read FNeonIncludeIf write FNeonIncludeIf;
    property Serializable: Boolean read FSerializable write FSerializable;
  end;

  TNeonRttiMembers = class(TObjectList<TNeonRttiMember>)
  private
    FOperation: TNeonOperation;
    FConfig: TNeonConfiguration;
    FInstance: Pointer;
    FParent: TNeonRttiType;
  private
    function MatchesVisibility(AVisibility: TMemberVisibility): Boolean;
    function MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;
  public
    constructor Create(AConfig: TNeonConfiguration; AInstance: Pointer; AType: TRttiType; AOperation: TNeonOperation);
    destructor Destroy; override;

    function NewMember(AMember: TRttiMember): TNeonRttiMember;

    procedure FilterSerialize;
    procedure FilterDeserialize;
  end;

  TNeonBase = class(TSingletonImplementation, IConfigurationContext)
  protected
    FConfig: TNeonConfiguration;
    FOperation: TNeonOperation;
    FOriginalInstance: TValue;
    FErrors: TStrings;
    function IsOriginalInstance(const AValue: TValue): Boolean;
    function GetTypeMembers(AType: TRttiType): TArray<TRttiMember>;
    function GetNeonMembers(AInstance: Pointer; AType: TRttiType): TNeonRttiMembers;
    function GetNameFromMember(AMember: TNeonRttiMember): string; virtual;
  public
    constructor Create(const AConfig: INeonConfiguration);
    destructor Destroy; override;

    procedure LogError(const AMessage: string);
    function GetConfiguration: INeonConfiguration;
  public
    property Config: TNeonConfiguration read FConfig write FConfig;
    property Errors: TStrings read FErrors write FErrors;
  end;

  TTypeInfoUtils = class
    class function EnumToString(ATypeInfo: PTypeInfo; AValue: Integer; ANeonObject: TNeonRttiObject): string; static;
  end;


implementation

uses
  System.RegularExpressions,
  Neon.Core.Utils;

{ TNeonBase }

constructor TNeonBase.Create(const AConfig: INeonConfiguration);
begin
  FConfig := AConfig as TNeonConfiguration;
  FErrors := TStringList.Create;
end;

destructor TNeonBase.Destroy;
begin
  FErrors.Free;
  inherited;
end;

function TNeonBase.GetConfiguration: INeonConfiguration;
begin
  Result := FConfig;
end;

function TNeonBase.GetNameFromMember(AMember: TNeonRttiMember): string;
var
  LMemberName: string;
begin
  if not AMember.NeonProperty.IsEmpty then
    Exit(AMember.NeonProperty);

  if FConfig.IgnoreFieldPrefix and AMember.IsField then
  begin

    if AMember.Name.StartsWith('F', True) and
       (AMember.Visibility in [mvPrivate, mvProtected])
    then
      LMemberName := AMember.Name.Substring(1)
    else
      LMemberName := AMember.Name;
  end
  else
    LMemberName := AMember.Name;

  case FConfig.MemberCase of
    TNeonCase.LowerCase : Result := LowerCase(LMemberName);
    TNeonCase.UpperCase : Result := UpperCase(LMemberName);
    TNeonCase.CamelCase : Result := TCaseAlgorithm.PascalToCamel(LMemberName);
    TNeonCase.SnakeCase : Result := TCaseAlgorithm.PascalToSnake(LMemberName);
    TNeonCase.PascalCase: Result := LMemberName;
    TNeonCase.CustomCase: Result := FConfig.MemberCustomCase(LMemberName);
  end;
end;

function TNeonBase.GetNeonMembers(AInstance: Pointer; AType: TRttiType): TNeonRttiMembers;
var
  LFields, LProps: TArray<TRttiMember>;
  LMember: TRttiMember;
  LNeonMember: TNeonRttiMember;
begin
  Result := TNeonRttiMembers.Create(FConfig, AInstance, AType, FOperation);

  SetLength(LFields, 0);
  SetLength(LProps, 0);

  if AType.IsRecord then
  begin
    LFields := TArray<TRttiMember>(AType.AsRecord.GetFields);
    LProps  := TArray<TRttiMember>(AType.AsRecord.GetProperties);
    // GetIndexedProperties
  end
  else if AType.IsInstance then
  begin
    LFields := TArray<TRttiMember>(AType.AsInstance.GetFields);
    LProps  := TArray<TRttiMember>(AType.AsInstance.GetProperties);
    // GetIndexedProperties
  end;

  for LMember in LFields do
  begin
    LNeonMember := Result.NewMember(LMember);
    Result.Add(LNeonMember);
  end;
  for LMember in LProps do
  begin
    LNeonMember := Result.NewMember(LMember);
    Result.Add(LNeonMember);
  end;
end;

function TNeonBase.GetTypeMembers(AType: TRttiType): TArray<TRttiMember>;
begin
  SetLength(Result, 0);

  if TNeonMembers.Standard in FConfig.Members then
  begin
    if AType.IsRecord then
      Result := TArray<TRttiMember>(AType.AsRecord.GetFields)
    else if AType.IsInstance then
      Result := TArray<TRttiMember>(AType.AsInstance.GetProperties);
  end;

  if TNeonMembers.Properties in FConfig.Members then
  begin
    if AType.IsRecord then
      Result := TArray<TRttiMember>(AType.AsRecord.GetProperties)
    else if AType.IsInstance then
      Result := TArray<TRttiMember>(AType.AsInstance.GetProperties);
  end;

  if TNeonMembers.Fields in FConfig.Members then
  begin
    if AType.IsRecord then
      Result := TArray<TRttiMember>(AType.AsRecord.GetFields)
    else if AType.IsInstance then
      Result := TArray<TRttiMember>(AType.AsInstance.GetFields);
  end;
end;

function TNeonBase.IsOriginalInstance(const AValue: TValue): Boolean;
begin
  if NativeInt(AValue.GetReferenceToRawData^) = NativeInt(FOriginalInstance.GetReferenceToRawData^) then
    Result := True
  else
    Result := False;
end;

procedure TNeonBase.LogError(const AMessage: string);
begin
  FErrors.Add(AMessage);
end;

{ TNeonConfiguration }

constructor TNeonConfiguration.Create;
begin
  FSerializers := TNeonSerializerRegistry.Create;
  SetMemberCase(TNeonCase.PascalCase);
  SetMembers([TNeonMembers.Standard]);
  SetIgnoreFieldPrefix(False);
  SetVisibility([mvPublic, mvPublished]);
  SetUseUTCDate(True);
  SetPrettyPrint(False);
end;

class function TNeonConfiguration.Default: INeonConfiguration;
begin
  Result := TNeonConfiguration.Create;
end;

destructor TNeonConfiguration.Destroy;
begin
  FSerializers.Free;
  inherited;
end;

function TNeonConfiguration.GetPrettyPrint: Boolean;
begin
  Result := FPrettyPrint;
end;

function TNeonConfiguration.GetSerializers: TNeonSerializerRegistry;
begin
  Result := FSerializers;
end;

function TNeonConfiguration.GetUseUTCDate: Boolean;
begin
  Result := FUseUTCDate;
end;

class function TNeonConfiguration.Pretty: INeonConfiguration;
begin
  Result := TNeonConfiguration.Create;
  Result.SetPrettyPrint(True);
end;

class function TNeonConfiguration.Camel: INeonConfiguration;
begin
  Result := TNeonConfiguration.Create;
  Result.SetMemberCase(TNeonCase.CamelCase);
end;

class function TNeonConfiguration.Snake: INeonConfiguration;
begin
  Result := TNeonConfiguration.Create;
  Result.SetIgnoreFieldPrefix(True);
  Result.SetMemberCase(TNeonCase.SnakeCase);
end;

function TNeonConfiguration.SetMembers(AValue: TNeonMembersSet): INeonConfiguration;
begin
  FMembers := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetPrettyPrint(AValue: Boolean): INeonConfiguration;
begin
  FPrettyPrint := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetUseUTCDate(AValue: Boolean): INeonConfiguration;
begin
  FUseUTCDate := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguration;
begin
  FIgnoreFieldPrefix := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetMemberCase(AValue: TNeonCase): INeonConfiguration;
begin
  FMemberCase := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguration;
begin
  FMemberCustomCase := AValue;
  Result := Self;
end;

function TNeonConfiguration.SetVisibility(AValue: TNeonVisibility): INeonConfiguration;
begin
  FVisibility := AValue;
  Result := Self;
end;

{ TNeonRttiMember }

constructor TNeonRttiMember.Create(AMember: TRttiMember; AParent: TNeonRttiType; AOperation: TNeonOperation);
begin
  inherited Create(AMember, AOperation);
  FMember := AMember;
  FParent := AParent;

  if FMember is TRttiProperty then
  begin
    FMemberType := TNeonMemberType.Prop;
    FMemberRttiType := (FMember as TRttiProperty).PropertyType;
  end
  else if FMember is TRttiField then
  begin
    FMemberType := TNeonMemberType.Field;
    FMemberRttiType := (FMember as TRttiField).FieldType;
  end;

  if Assigned(FMemberRttiType) then
    FTypeAttributes := FMemberRttiType.GetAttributes;

  ParseAttributes;
end;

function TNeonRttiMember.GetName: string;
begin
  Result := FMember.Name;
end;

function TNeonRttiMember.GetValue: TValue;
begin
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create('Member type must be Field or Property');
    TNeonMemberType.Prop   : Result := MemberAsProperty.GetValue(FParent.Instance);
    TNeonMemberType.Field  : Result := MemberAsField.GetValue(FParent.Instance);
  end;
end;

function TNeonRttiMember.IsField: Boolean;
begin
  Result := False;
  case FMemberType of
    TNeonMemberType.Field: Result := True;
  end;
end;

function TNeonRttiMember.IsProperty: Boolean;
begin
  Result := False;
  case FMemberType of
    TNeonMemberType.Prop: Result := True;
  end;
end;

function TNeonRttiMember.IsReadable: Boolean;
begin
  Result := False;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create('Member type must be Field or Property');
    TNeonMemberType.Prop   : Result := MemberAsProperty.IsReadable;
    TNeonMemberType.Field  : Result := True;
  end;
end;

function TNeonRttiMember.IsWritable: Boolean;
begin
  Result := False;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create('Member type must be Field or Property');
    TNeonMemberType.Prop   : Result := MemberAsProperty.IsWritable;
    TNeonMemberType.Field  : Result := True;
  end;
end;

function TNeonRttiMember.MemberAsField: TRttiField;
begin
  Result := FMember as TRttiField;
end;

function TNeonRttiMember.MemberAsProperty: TRttiProperty;
begin
  Result := FMember as TRttiProperty;
end;

function TNeonRttiMember.MemberType: TNeonMemberType;
begin
  Result := FMemberType;
end;

function TNeonRttiMember.RttiType: TRttiType;
begin
  Result := nil;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create('Member type must be Field or Property');
    TNeonMemberType.Prop   : Result := MemberAsProperty.PropertyType;
    TNeonMemberType.Field  : Result := MemberAsField.FieldType;
  end;
end;

procedure TNeonRttiMember.ProcessAttribute(AAttribute: TCustomAttribute);
var
  LIncludeAttribute: NeonIncludeAttribute;
  LContext: TNeonIgnoreIfContext;
  LMethodName: string;
  LMethod: TRttiMethod;
  LRes: TValue;
begin
  LRes := False;
  if AAttribute is NeonIncludeAttribute then
  begin
    LIncludeAttribute := AAttribute as NeonIncludeAttribute;
    if LIncludeAttribute.IncludeValue.Value = IncludeIf.CustomFunction then
    begin
      LMethodName := LIncludeAttribute.IncludeValue.IncludeFunction;
      LMethod := FParent.FType.GetMethod(LMethodName);
      if Assigned(LMethod) then
      begin
        LContext := TNeonIgnoreIfContext.Create(Self.Name, FOperation);
        LRes := LMethod.Invoke(TObject(FParent.Instance), [TValue.From<TNeonIgnoreIfContext>(LContext)]);
        case LRes.AsType<Boolean> of
          True: FNeonIncludeIf := TNeonIncludeOption.Include;
          False: FNeonIncludeIf := TNeonIncludeOption.Exclude;
        end;
      end;
    end;
  end;
end;

procedure TNeonRttiMember.SetValue(const AValue: TValue);
begin
  case FMemberType of
    TNeonMemberType.Prop :
    begin
      if MemberAsProperty.IsWritable then
        MemberAsProperty.SetValue(FParent.Instance, AValue);
    end;
    TNeonMemberType.Field: MemberAsField.SetValue(FParent.Instance, AValue);
  end;
end;

function TNeonRttiMember.TypeKind: TTypeKind;
begin
  Result := tkUnknown;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create('Member type must be Field or Property');
    TNeonMemberType.Prop   : Result := MemberAsProperty.PropertyType.TypeKind;
    TNeonMemberType.Field  : Result := MemberAsField.FieldType.TypeKind;
  end;
end;

function TNeonRttiMember.Visibility: TMemberVisibility;
begin
  Result := FMember.Visibility
end;

{ TCaseAlgorithm }

class function TCaseAlgorithm.CamelToPascal(const AString: string): string;
var
  LOld, LNew: Char;
begin
  Result := AString;
  if Result.IsEmpty then
    Exit;

  LOld := Result.Chars[0];
  LNew := UpperCase(LOld).Chars[0];

  Result := Result.Replace(LOld, LNew, []);
end;

class function TCaseAlgorithm.PascalToCamel(const AString: string): string;
var
  LOld, LNew: Char;
begin
  Result := AString;
  if Result.IsEmpty then
    Exit;

  LOld := Result.Chars[0];
  LNew := LowerCase(LOld).Chars[0];

  Result := Result.Replace(LOld, LNew, []);
end;

class function TCaseAlgorithm.PascalToSnake(const AString: string): string;
begin
  Result := LowerCase(
    TRegEx.Replace(AString,
    '([A-Z][a-z\d]+)(?=([A-Z][A-Z\a-z\d]+))', '$1_', [])
  );
end;

class function TCaseAlgorithm.SnakeToPascal(const AString: string): string;
var
  LChar: Char;
  LIndex: Integer;
  LSingleWord: string;
  LWords: TArray<string>;
begin
  LWords := AString.Split(['_']);
  for LIndex := 0 to Length(LWords) - 1 do
  begin
    LSingleWord := LWords[LIndex];
    if LSingleWord.IsEmpty then
      Continue;
    LChar := Upcase(LSingleWord.Chars[0]);
    LSingleWord := LSingleWord.Remove(0, 1);
    LSingleWord := LSingleWord.Insert(0, LChar);
    LWords[LIndex] := LSingleWord;
  end;

  Result := string.Join('', LWords);
end;

{ TNeonRttiMembers }

constructor TNeonRttiMembers.Create(AConfig: TNeonConfiguration; AInstance: Pointer;
  AType: TRttiType; AOperation: TNeonOperation);
begin
  inherited Create(True);

  FConfig := AConfig;
  FInstance := AInstance;
  FOperation := AOperation;
  FParent := TNeonRttiType.Create(AInstance, AType, AOperation);
end;

destructor TNeonRttiMembers.Destroy;
begin
  FParent.Free;
  inherited;
end;

procedure TNeonRttiMembers.FilterDeserialize;
var
  LMember: TNeonRttiMember;
begin
  for LMember in Self do
  begin
    if LMember.NeonInclude.Present and (LMember.NeonInclude.Value = IncludeIf.Always) then
    begin
      LMember.Serializable := True;
      Continue;
    end;

    if LMember.NeonIgnore then
      Continue;

    if not LMember.IsWritable then
      Continue;

    if MatchesVisibility(LMember.Visibility) then
    if MatchesMemberChoice(LMember.MemberType) then
      LMember.Serializable := True;
  end;
end;

procedure TNeonRttiMembers.FilterSerialize;
var
  LMember: TNeonRttiMember;
begin
  for LMember in Self do
  begin
    if LMember.NeonInclude.Present and (LMember.NeonInclude.Value = IncludeIf.Always) then
    begin
      LMember.Serializable := True;
      Continue;
    end;

    if LMember.NeonIgnore then
      Continue;

    case LMember.NeonIncludeIf of
      TNeonIncludeOption.Include:
      begin
        LMember.Serializable := True;
        Continue;
      end;
      TNeonIncludeOption.Exclude:
      begin
        Continue;
      end;
    end;

    // Exclusions
    if not LMember.IsReadable then
      Continue;

    { TODO -opaolo -c : Maybe controlled by a config item? 29/06/2018 23:14:17 }
    if SameText(LMember.Name, 'Parent') then
      Continue;

    if SameText(LMember.Name, 'Owner') then
      Continue;

    if not LMember.IsWritable and
       not (LMember.TypeKind in [tkClass, tkInterface]) then
      Continue;

    if MatchesVisibility(LMember.Visibility) then
    if MatchesMemberChoice(LMember.MemberType) then
      LMember.Serializable := True;
  end;
end;

function TNeonRttiMembers.MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;
var
  LRttiType: TRttiType;
  LMemberChoice: TNeonMembersSet;
begin
  Result := False;
  if FParent.NeonMembers = [] then
    LMemberChoice := FConfig.Members
  else
    LMemberChoice := FParent.NeonMembers;

  if TNeonMembers.Standard in LMemberChoice then
  begin
    LRttiType := FParent.AsRttiType;
    if Assigned(LRttiType) then
    begin
      if LRttiType.IsRecord then
        LMemberChoice := LMemberChoice + [TNeonMembers.Fields];
      if LRttiType.IsInstance then
        LMemberChoice := LMemberChoice + [TNeonMembers.Properties];
    end;
  end;

  case AMemberType of
    //TNeonMemberType.Unknown: Result := False;
    TNeonMemberType.Prop   :   Result := TNeonMembers.Properties in LMemberChoice;
    TNeonMemberType.Field  :   Result := TNeonMembers.Fields in LMemberChoice;
    //TNeonMemberType.Indexed: Result := False;
  end;
end;

function TNeonRttiMembers.MatchesVisibility(AVisibility: TMemberVisibility): Boolean;
var
  LVisibility: TNeonVisibility;
begin
  Result := False;

  if FParent.NeonVisibility = [] then
    LVisibility := FConfig.Visibility
  else
    LVisibility := FParent.NeonVisibility;

  if AVisibility in LVisibility then
    Result := True;
end;

function TNeonRttiMembers.NewMember(AMember: TRttiMember): TNeonRttiMember;
begin
  Result := TNeonRttiMember.Create(AMember, FParent, FOperation);
end;

{ TNeonRttiObject }

function TNeonRttiObject.AsRttiType: TRttiType;
begin
  Result := nil;
  if FRttiObject is TRttiType then
    Result := FRttiObject as TRttiType;
end;

constructor TNeonRttiObject.Create(ARttiObject: TRttiObject; AOperation: TNeonOperation);
begin
  FRttiObject := ARttiObject;
  FOperation := AOperation;
  FAttributes := FRttiObject.GetAttributes;
  FNeonMembers := [];
end;

procedure TNeonRttiObject.InternalParseAttributes(const AAttr: TArray<TCustomAttribute>);
var
  LAttribute: TCustomAttribute;
begin
  for LAttribute in AAttr do
  begin
    if LAttribute is NeonIncludeAttribute then
      FNeonInclude := (LAttribute as NeonIncludeAttribute).IncludeValue
    else if LAttribute is NeonSerializeAttribute then
    begin
      FNeonSerializerName := (LAttribute as NeonSerializeAttribute).Name;
      FNeonSerializerClass := (LAttribute as NeonSerializeAttribute).Clazz;
    end
    else if LAttribute is NeonIgnoreAttribute then
      FNeonIgnore := True
    else if LAttribute is NeonPropertyAttribute then
      FNeonProperty := (LAttribute as NeonPropertyAttribute).Value
    else if LAttribute is NeonEnumNamesAttribute then
      FNeonEnumNames := (LAttribute as NeonEnumNamesAttribute).Names
    else if LAttribute is NeonVisibilityAttribute then
      FNeonVisibility := (LAttribute as NeonVisibilityAttribute).Value
    else if LAttribute is NeonMembersSetAttribute then
      FNeonMembers := (LAttribute as NeonMembersSetAttribute).Value;

    // Further attribute processing
    ProcessAttribute(LAttribute);
  end;
end;

procedure TNeonRttiObject.ParseAttributes;
begin
  if Length(FTypeAttributes) > 0 then
    InternalParseAttributes(FTypeAttributes);
  if Length(FAttributes) > 0 then
    InternalParseAttributes(FAttributes);
end;

procedure TNeonRttiObject.ProcessAttribute(AAttribute: TCustomAttribute);
begin

end;

{ TNeonRttiType }

constructor TNeonRttiType.Create(AInstance: Pointer; AType: TRttiType; AOperation: TNeonOperation);
begin
  inherited Create(AType, AOperation);
  FType := AType;
  FInstance := AInstance;

  ParseAttributes;
end;

{ TNeonSerializerRegistry }

procedure TNeonSerializerRegistry.Assign(ARegistry: TNeonSerializerRegistry);
var
  LInfo: TSerializerInfo;
  LPair: TPair<PTypeInfo, TCustomSerializer>;
begin
  for LInfo in ARegistry.FRegistryClass do
    FRegistryClass.Add(LInfo);

  for LPair in ARegistry.FRegistryCache do
    FRegistryCache.Add(LPair.Key, LPair.Value);
end;

procedure TNeonSerializerRegistry.Clear;
begin
  FRegistryClass.Clear;
  FRegistryCache.Clear;
end;

procedure TNeonSerializerRegistry.ClearCache;
begin
  FRegistryCache.Clear;
end;

constructor TNeonSerializerRegistry.Create;
begin
  FRegistryClass := SerializerClassRegistry.Create();
  FRegistryCache := SerializerCacheRegistry.Create([doOwnsValues]);
end;

destructor TNeonSerializerRegistry.Destroy;
begin
  FRegistryClass.Free;
  FRegistryCache.Free;
  inherited;
end;

function TNeonSerializerRegistry.GetCount: Integer;
begin
  Result := FRegistryClass.Count;
end;

function TNeonSerializerRegistry.GetSerializer(AValue: TValue): TCustomSerializer;
begin
  Result := InternalGetSerializer(AValue.TypeInfo);
end;

function TNeonSerializerRegistry.GetSerializer<T>: TCustomSerializer;
begin
  Result := InternalGetSerializer(TypeInfo(T));
end;

function TNeonSerializerRegistry.GetSerializer(ATargetInfo: PTypeInfo): TCustomSerializer;
begin
  Result := InternalGetSerializer(ATargetInfo);
end;

function TNeonSerializerRegistry.GetSerializer(ATargetClass: TClass): TCustomSerializer;
begin
  Result := InternalGetSerializer(ATargetClass.ClassInfo);
end;

function TNeonSerializerRegistry.InternalGetSerializer(ATypeInfo: PTypeInfo): TCustomSerializer;
var
  LInfo: TSerializerInfo;
  LClass: TCustomSerializerClass;
  LDistanceMax: Integer;
begin
  Result := nil;
  LClass := nil;
  LDistanceMax := 0;

  if FRegistryCache.TryGetValue(ATypeInfo, Result) then
    Exit(Result);

  for LInfo in FRegistryClass do
  begin
    if LInfo.SerializerClass.CanHandle(ATypeInfo) then
    begin
      if LInfo.Distance = -1 then
      begin
        LClass := LInfo.SerializerClass;
        Break;
      end
      else
      begin
        if LInfo.Distance > LDistanceMax then
        begin
          LDistanceMax := LInfo.Distance;
          LClass := LInfo.SerializerClass;
        end;
      end;
    end;
  end;

  if Assigned(LClass) then
  begin
    Result := LClass.Create;
    FRegistryCache.Add(ATypeInfo, Result);
  end;
end;

function TNeonSerializerRegistry.RegisterSerializer(ASerializerClass: TCustomSerializerClass): TNeonSerializerRegistry;
begin
  FRegistryClass.Add(TSerializerInfo.FromSerializer(ASerializerClass));
  Result := Self;
end;

procedure TNeonSerializerRegistry.UnregisterSerializer(ASerializerClass: TCustomSerializerClass);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRegistryClass.Count - 1 do
    if FRegistryClass[LIndex].SerializerClass = ASerializerClass then
    begin
      FRegistryClass.Delete(LIndex);
      ClearCache;
      Break;
    end;
end;

{ TCustomSerializer }

class function TCustomSerializer.ClassDistance: Integer;
begin
  Result := TRttiUtils.ClassDistanceFromRoot(GetTargetInfo);
end;

class function TCustomSerializer.ClassIs(AClass: TClass): Boolean;
var
  LType: TRttiType;
begin
  Result := False;

  LType := TRttiUtils.Context.GetType(GetTargetInfo);
  if Assigned(LType) and (LType.TypeKind = tkClass) then
    Result := AClass.InheritsFrom(LType.AsInstance.MetaclassType);
end;

class function TCustomSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := nil;
end;

class function TCustomSerializer.TypeInfoIs(AInfo: PTypeInfo): Boolean;
var
  LType: TRttiType;
begin
  Result := False;
  LType := TRttiUtils.Context.GetType(AInfo);
  if Assigned(LType) and (LType.TypeKind = tkClass) then
    Result := ClassIs(LType.AsInstance.MetaclassType);
end;

class function TCustomSerializer.TypeInfoIsClass(AInfo: PTypeInfo): Boolean;
var
  LType: TRttiType;
begin
  Result := False;
  LType := TRttiUtils.Context.GetType(AInfo);
  if Assigned(LType) and (LType.TypeKind = tkClass) then
    Result := True;
end;

{ TSerializerInfo }

class function TSerializerInfo.FromSerializer(ASerializerClass: TCustomSerializerClass): TSerializerInfo;
begin
  Result.SerializerClass := ASerializerClass;
  Result.Distance := ASerializerClass.ClassDistance;
end;

{ TTypeInfoUtils }

class function TTypeInfoUtils.EnumToString(ATypeInfo: PTypeInfo; AValue: Integer;
    ANeonObject: TNeonRttiObject): string;
var
  LTypeData: PTypeData;
begin
  Result := '';

  LTypeData := GetTypeData(ATypeInfo);
  if (AValue >= LTypeData.MinValue) and (AValue <= LTypeData.MaxValue) then
  begin
    Result := GetEnumName(ATypeInfo, AValue);

    if Length(ANeonObject.NeonEnumNames) > 0 then
    begin
      if (AValue >= Low(ANeonObject.NeonEnumNames)) and
         (AValue <= High(ANeonObject.NeonEnumNames)) then
        Result := ANeonObject.NeonEnumNames[AValue]
    end;
  end
  else
    raise ENeonException.Create('Enum value out of bound: ' + AValue.ToString);
end;

end.
