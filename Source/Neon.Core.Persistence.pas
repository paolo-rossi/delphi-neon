{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018 Paolo Rossi                                              }
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

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.JSON, System.Generics.Defaults,

  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Attributes,
  Neon.Core.DynamicTypes;

{$SCOPEDENUMS ON}

type

  {$REGION 'Forward Declarations'}

  TCustomFactory = class;
  TCustomFactoryClass = class of TCustomFactory;

  TCustomSerializer = class;
  TCustomSerializerClass = class of TCustomSerializer;

  TNeonSerializerRegistry = class;
  TNeonRttiType = class;

  TNeonSettingsType = class;
  TNeonSettings = class;

  INeonConfigurator = interface;
  TNeonConfigurator = class;

  {$ENDREGION}

  {$REGION 'Custom Serializer'}

  IConfigurationContext = interface
  ['{3954FFB5-2D3D-4978-AADA-FEC5C0D73FD0}']
    function GetSettings: TNeonSettings;
  end;

  IOperationContext = interface(IConfigurationContext)
  ['{EEEC8296-5B47-4057-A458-E1A2246C46F8}']
    function GetOperation: TNeonOperation;
  end;

  ISerializerContext = interface(IOperationContext)
  ['{36A014FC-9E3F-4EBF-9545-CF9DBCBF507C}']

    /// <summary>
    ///   Method to write value from a custom serializer
    /// </summary>
    function WriteDataMember(const AValue: TValue; ACustomProcess: Boolean = True): TJSONValue;

    /// <summary>
    ///   Writer for members of objects and records. In a custom serializer can
    ///   be used to process the **same** object or record
    /// </summary>
    procedure WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);

    /// <summary>
    ///   Useful method to add serialization errors in the serializer's log
    /// </summary>
    procedure AddError(const AMessage: string);
  end;

  IDeserializerContext = interface(IConfigurationContext)
  ['{5351D1F9-99B3-4826-B981-4CBF926085D6}']
    /// <summary>
    ///   Method to convert a TJSONValue into a TValue (from a custom
    ///   serializer)
    /// </summary>
    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue; ACustomProcess: Boolean = True): TValue;

    /// <summary>
    ///   Reader for members of objects and record. In a custom serializer can
    ///   be used to process the **same** object or record
    /// </summary>
    procedure ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);

    /// <summary>
    ///   Useful method to add deserialization errors in the deserializer's log
    /// </summary>
    procedure AddError(const AMessage: string);
  end;

  //TCustomItemCreator = reference to function (AType: TRttiType; AValue: TJSONValue): TObject;

  /// <summary>
  ///   Base class for an Object Factory
  /// </summary>
  TCustomFactory = class abstract(TObject)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; virtual; abstract;
  end;
  TNeonFactoryRegistry = class(TList<TCustomFactoryClass>)
    procedure Assign(ASource: TNeonFactoryRegistry);
  end;

  /// <summary>
  ///   Base class for a Custom Serializer
  /// </summary>
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
    class procedure ChangeConfig(AConfig: INeonConfigurator); virtual;
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiType; AContext: ISerializerContext): TJSONValue; virtual; abstract;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiType; AContext: IDeserializerContext): TValue; virtual; abstract;
  end;

  TNeonSerializerRegistry = class
  private type
    TSerializerInfo = record
    public
      SerializerClass: TCustomSerializerClass;
      Distance: Integer;
    public
      class function FromSerializer(ASerializerClass: TCustomSerializerClass): TSerializerInfo; static;
    end;
  private type
    SerializerCacheRegistry = class(TObjectDictionary<PTypeInfo, TCustomSerializer>);
    SerializerClassRegistry = class(TList<TSerializerInfo>);
  private
    FRegistryClass: SerializerClassRegistry;
    FRegistryCache: SerializerCacheRegistry;
    FRegistryCacheLock: TCriticalSection;
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

  {$ENDREGION}

  {$REGION 'Neon Settings'}

  TNeonSettingsType = class
  protected
    FMembers: Nullable<TNeonMembersSet>;
    FMemberSort: Nullable<TNeonSort>;
    FMemberCase: Nullable<TNeonCase>;
    FMemberCustomCase: TCaseFunc;
    FVisibility: Nullable<TNeonVisibility>;
    FIgnoreFieldPrefix: Nullable<Boolean>;
    FIgnoreMembers: TArray<string>;
  public
    procedure Assign(ASource: TNeonSettingsType); virtual;

    function Clone: TNeonSettingsType;
    function IgnoreMember(const AMember: string): Boolean;

    property Members: Nullable<TNeonMembersSet> read FMembers write FMembers;
    property MemberSort: Nullable<TNeonSort> read FMemberSort write FMemberSort;
    property MemberCase: Nullable<TNeonCase> read FMemberCase write FMemberCase;
    property MemberCustomCase: TCaseFunc read FMemberCustomCase write FMemberCustomCase;
    property Visibility: Nullable<TNeonVisibility> read FVisibility write FVisibility;
    property IgnoreFieldPrefix: Nullable<Boolean> read FIgnoreFieldPrefix write FIgnoreFieldPrefix;
    property IgnoreMembers: TArray<string> read FIgnoreMembers write FIgnoreMembers;
  end;

  TSettingsTypePair = TPair<TRttiType, TNeonSettingsType>;
  TSettingsTypeList = class(TList<TSettingsTypePair>)
  public
    procedure Assign(ASource: TSettingsTypeList);

    function IgnoreClass(AType: TRttiInstanceType; const AMember: string): Boolean;
    function IgnoreRecord(AType: TRttiRecordType; const AMember: string): Boolean;
  end;

  TNeonSettings = class(TNeonSettingsType)
  private
    FUseUTCDate: Nullable<Boolean>;
    FPrettyPrint: Nullable<Boolean>;
    FRaiseExceptions: Nullable<Boolean>;
    FEnumAsInt: Nullable<Boolean>;
    FAutoCreate: Nullable<Boolean>;
    FStrictTypes: Nullable<Boolean>;

    FSerializers: TNeonSerializerRegistry;
    FFactoryList: TNeonFactoryRegistry;
    FTypeSettings: TSettingsTypeList;

    procedure FreeTypeSettings;
  public
    constructor Create;
    destructor Destroy; override;

    class function Default: TNeonSettings; static;
    class function Pretty: TNeonSettings; static;
    class function Snake: TNeonSettings; static;
    class function Camel: TNeonSettings; static;
    class function Kebab: TNeonSettings; static;
    class function ScreamingSnake: TNeonSettings; static;

    function Clone: TNeonSettings;
    procedure Assign(ASource: TNeonSettingsType); override;

    function GetSettingsByType(AType: TRttiType): TNeonSettingsType;
    function GetCreateSettingsByType(AType: TRttiType): TNeonSettingsType;
    function IgnoreMember(AType: TRttiType; const AMember: string): Boolean;
  public
    property UseUTCDate: Nullable<Boolean> read FUseUTCDate write FUseUTCDate;
    property RaiseExceptions: Nullable<Boolean> read FRaiseExceptions write FRaiseExceptions;
    property EnumAsInt: Nullable<Boolean> read FEnumAsInt write FEnumAsInt;
    property AutoCreate: Nullable<Boolean> read FAutoCreate write FAutoCreate;
    property StrictTypes: Nullable<Boolean> read FStrictTypes write FStrictTypes;
    property PrettyPrint: Nullable<Boolean> read FPrettyPrint write FPrettyPrint;

    property Serializers: TNeonSerializerRegistry read FSerializers write FSerializers;
    property FactoryList: TNeonFactoryRegistry read FFactoryList write FFactoryList;
    property TypeSettings: TSettingsTypeList read FTypeSettings write FTypeSettings;
  end;

  TNeonSettingsProxy = class
  private
    FGlobal: TNeonSettings;
    FType: TRttiType;
    FLoaded: Boolean;

    FStrictTypes: Boolean;
    FIgnoreFieldPrefix: Boolean;
    FMemberCustomCase: TCaseFunc;
    FUseUTCDate: Boolean;
    FAutoCreate: Boolean;
    FRaiseExceptions: Boolean;
    FVisibility: TNeonVisibility;
    FMemberSort: TNeonSort;
    FIgnoreMembers: TArray<string>;
    FEnumAsInt: Boolean;
    FPrettyPrint: Boolean;
    FMemberCase: TNeonCase;
    FMembers: TNeonMembersSet;
    procedure LoadFromSettings(ACustom: TNeonSettingsType);
    procedure DefaultSettings;
  public
    constructor Create(ASettings: TNeonSettings; AType: TRttiType);
    procedure LoadValues; inline;
  public
    // Type Settings
    property Members: TNeonMembersSet read FMembers;
    property MemberSort: TNeonSort read FMemberSort;
    property MemberCase: TNeonCase read FMemberCase;
    property MemberCustomCase: TCaseFunc read FMemberCustomCase;
    property Visibility: TNeonVisibility read FVisibility;
    property IgnoreFieldPrefix: Boolean read FIgnoreFieldPrefix;
    property IgnoreMembers: TArray<string> read FIgnoreMembers;
    // Global Settings
    property UseUTCDate: Boolean read FUseUTCDate;
    property RaiseExceptions: Boolean read FRaiseExceptions;
    property EnumAsInt: Boolean read FEnumAsInt;
    property AutoCreate: Boolean read FAutoCreate;
    property StrictTypes: Boolean read FStrictTypes;
    property PrettyPrint: Boolean read FPrettyPrint;
    // Global Settings
    //property Globlal: TNeonSettings read FGlobal;
  end;

  {$ENDREGION}

  {$REGION 'Neon Configurator'}

  INeonConfiguratorType = interface
  ['{E9E85E1D-329C-4ED4-895C-D4DA8021A4C5}']
    function SetMembers(AValue: TNeonMembersSet): INeonConfiguratorType;
    function SetMemberSort(AValue: TNeonSort): INeonConfiguratorType;
    function SetMemberCase(AValue: TNeonCase): INeonConfiguratorType;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguratorType;
    function SetVisibility(AValue: TNeonVisibility): INeonConfiguratorType;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguratorType;
//    function SetEnumAsInt(AValue: Boolean): INeonConfiguratorType;
//    function SetAutoCreate(AValue: Boolean): INeonConfiguratorType;
    function SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType; overload;
    function AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType; overload;

    function BackToConfig: INeonConfigurator;
  end;

  /// <summary>
  ///   Utility class to provide generic functions to the main configuration
  /// </summary>
  TTypeConfigurator = class
  private
    [unsafe] FConfigurator: INeonConfigurator;
    function CreateConfigForType(AType: TRttiType): INeonConfiguratorType;
    function Rules<T>: INeonConfiguratorType;
  public
    constructor Create(AConfigurator: TNeonConfigurator);

    function ForClass<T: class>: INeonConfiguratorType;
    function ForRecord<T: record>: INeonConfiguratorType;
  end;

  /// <summary>
  ///   Configurator Interface
  /// </summary>
  INeonConfigurator = interface
  ['{F82AB790-1C65-4501-915C-0289EFD9D8CC}']
    // Member-related settings
    function SetMembers(AValue: TNeonMembersSet): INeonConfigurator;
    function SetMemberSort(AValue: TNeonSort): INeonConfigurator;
    function SetMemberCase(AValue: TNeonCase): INeonConfigurator;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfigurator;
    function SetVisibility(AValue: TNeonVisibility): INeonConfigurator;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfigurator;
    function SetEnumAsInt(AValue: Boolean): INeonConfigurator;
    function SetAutoCreate(AValue: Boolean): INeonConfigurator;
    function SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator;
    function AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator; overload;

    // Global Settings
    function SetStrictTypes(AValue: Boolean): INeonConfigurator;
    function SetUseUTCDate(AValue: Boolean): INeonConfigurator;
    function SetRaiseExceptions(AValue: Boolean): INeonConfigurator;
    function SetPrettyPrint(AValue: Boolean): INeonConfigurator;
    function RegisterSerializer(AClass: TCustomSerializerClass): INeonConfigurator;
    function RegisterFactory(AClass: TCustomFactoryClass): INeonConfigurator;

    function GetSerializers: TNeonSerializerRegistry;
    function GetTypeConfigurator: TTypeConfigurator;

    function BuildSettings: TNeonSettings;

    property Rules: TTypeConfigurator read GetTypeConfigurator;
    property Serializers: TNeonSerializerRegistry read GetSerializers;
  end;
  INeonConfiguration = INeonConfigurator;

  /// <summary>
  ///   Utility class for case management
  /// </summary>
  TCaseAlgorithm = class
  public
    class function PascalToCamel(const AString: string): string;
    class function CamelToPascal(const AString: string): string;

    class function PascalToSnake(const AString: string): string;
    class function PascalToScreamingSnake(const AString: string): string;
    class function SnakeToPascal(const AString: string): string;

    class function PascalToKebab(const AString: string): string;
    class function KebabToPascal(const AString: string): string;
  end;

  /// <summary>
  ///   Configuration builder utility for the TNeonSettingsType
  /// </summary>
  TNeonConfiguratorType = class sealed(TInterfacedObject, INeonConfiguratorType)
  private
    [unsafe] FConfigurator: INeonConfigurator;
    FSettings: TNeonSettingsType;
  public
    constructor Create(AConfigurator: INeonConfigurator; ATypeSettings: TNeonSettingsType);

    // Interface INeonConfiguratorType
    function SetMembers(AValue: TNeonMembersSet): INeonConfiguratorType;
    function SetMemberSort(AValue: TNeonSort): INeonConfiguratorType;
    function SetMemberCase(AValue: TNeonCase): INeonConfiguratorType;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguratorType;
    function SetVisibility(AValue: TNeonVisibility): INeonConfiguratorType;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguratorType;
    function SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType; overload;
    function AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType; overload;

    function BackToConfig: INeonConfigurator;
  end;

  /// <summary>
  ///   Configuration builder utility for the TNeonSettings type
  /// </summary>
  TNeonConfigurator = class sealed(TInterfacedObject, INeonConfigurator)
  private
    FInternalSettings: TNeonSettings;
    FTypeConfigurator: TTypeConfigurator;
  public
    constructor Create; overload;
    constructor Create(ASettings: TNeonSettings); overload;
    destructor Destroy; override;

    class function Default: INeonConfigurator; static;
    class function Pretty: INeonConfigurator; static;
    class function Snake: INeonConfigurator; static;
    class function Camel: INeonConfigurator; static;
    class function Kebab: INeonConfigurator; static;
    class function ScreamingSnake: INeonConfigurator; static;

    function SetMembers(AValue: TNeonMembersSet): INeonConfigurator;
    function SetMemberSort(AValue: TNeonSort): INeonConfigurator;
    function SetMemberCase(AValue: TNeonCase): INeonConfigurator;
    function SetMemberCustomCase(AValue: TCaseFunc): INeonConfigurator;
    function SetVisibility(AValue: TNeonVisibility): INeonConfigurator;
    function SetIgnoreFieldPrefix(AValue: Boolean): INeonConfigurator;
    function SetUseUTCDate(AValue: Boolean): INeonConfigurator;
    function SetRaiseExceptions(AValue: Boolean): INeonConfigurator;
    function SetPrettyPrint(AValue: Boolean): INeonConfigurator;
    function SetEnumAsInt(AValue: Boolean): INeonConfigurator;
    function SetAutoCreate(AValue: Boolean): INeonConfigurator;
    function SetStrictTypes(AValue: Boolean): INeonConfigurator;
    function SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator;
    function AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator; overload;
    function RegisterSerializer(AClass: TCustomSerializerClass): INeonConfigurator;
    function RegisterFactory(AClass: TCustomFactoryClass): INeonConfigurator;
    function GetSerializers: TNeonSerializerRegistry;
    function GetTypeConfigurator: TTypeConfigurator;

    function BuildSettings: TNeonSettings;
  end;
  TNeonConfiguration = TNeonConfigurator;

  {$ENDREGION}

  {$REGION 'Rtti Proxies'}

  TNeonRttiType = class
  private
    FNeonFactoryClass: TCustomFactoryClass;
    FNeonItemFactoryClass: TCustomFactoryClass;
  protected
    FGlobalSettings: TNeonSettings; { TODO -opaolo -c : To remove? 01/01/2025 15:30:20 }
    FComputed: TNeonSettingsProxy;
    FNeonAutoCreate: Boolean;
    FRttiType: TRttiType;
    FAttributes: TArray<TCustomAttribute>;
    FMemberAttributes: TArray<TCustomAttribute>;
    FNeonInclude: TIncludeValue;
    FNeonMembers: TNeonMembersSet;
    FNeonVisibility: TNeonVisibility;
    FNeonIgnore: Boolean;
    FNeonProperty: string;
    FNeonEnumNames: TArray<string>;
    FNeonSerializerName: string;
    FNeonSerializerClass: TClass;
    FNeonRawValue: Boolean;
    FNeonUnwrapped: Boolean;

    function GetAttributeFrom<T: TCustomAttribute>(const AList: TArray<TCustomAttribute>): T;
  protected
    procedure InternalParseAttributes(const AAttr: TArray<TCustomAttribute>); virtual;
    procedure ProcessAttribute(AAttribute: TCustomAttribute); virtual;
  public
    constructor Create(AGlobalSettings: TNeonSettings; AType: TRttiType);
    destructor Destroy; override;
  public
    procedure ParseAttributes; virtual;
    function GetAttribute<T: TCustomAttribute>: T;
    function GetMemberAttribute<T: TCustomAttribute>: T;
    function GetDateTime(const AValue: string): TDateTime;
    function EnumToString(const AValue: TValue): string; overload;
    function EnumToString(ATypeInfo: PTypeInfo; AValue: Integer): string; overload;
  public
    property Attributes: TArray<TCustomAttribute> read FAttributes write FAttributes;
    property TypeAttributes: TArray<TCustomAttribute> read FMemberAttributes write FMemberAttributes;
    // Neon-based properties
    property NeonIgnore: Boolean read FNeonIgnore write FNeonIgnore;
    property NeonRawValue: Boolean read FNeonRawValue write FNeonRawValue;
    property NeonInclude: TIncludeValue read FNeonInclude write FNeonInclude;
    property NeonSerializerName: string read FNeonSerializerName write FNeonSerializerName;
    property NeonSerializerClass: TClass read FNeonSerializerClass write FNeonSerializerClass;
    property NeonProperty: string read FNeonProperty write FNeonProperty;
    property NeonEnumNames: TArray<string> read FNeonEnumNames write FNeonEnumNames;
    property NeonMembers: TNeonMembersSet read FNeonMembers write FNeonMembers;
    property NeonVisibility: TNeonVisibility read FNeonVisibility write FNeonVisibility;
    property NeonUnwrapped: Boolean read FNeonUnwrapped write FNeonUnwrapped;
    property NeonAutoCreate: Boolean read FNeonAutoCreate write FNeonAutoCreate;
    property NeonFactoryClass: TCustomFactoryClass read FNeonFactoryClass write FNeonFactoryClass;
    property NeonItemFactoryClass: TCustomFactoryClass read FNeonItemFactoryClass write FNeonItemFactoryClass;

    property RttiType: TRttiType read FRttiType write FRttiType;
    property Computed: TNeonSettingsProxy read FComputed;
  end;
  TNeonRttiObject = TNeonRttiType;

  TNeonRttiADT = class;

  TNeonRttiMember = class(TNeonRttiType)
  private
    FParent: TNeonRttiADT; // da sostituire con FOwner
    FComputedName: string;
    FMemberType: TNeonMemberType;
    FMember: TRttiMember;
    FMethodIf: TRttiMethod;
    FMethodIfContext: TNeonIgnoreIfContext;
    FCacheable: Boolean;

    function MemberAsProperty: TRttiProperty; inline;
    function MemberAsField: TRttiField; inline;
    function GetName: string;
    function GetComputedName: string;

    function EvalInclude(AInstance: Pointer): Nullable<Boolean>;

    function MatchesVisibility(AVisibility: TMemberVisibility): Boolean;
    function MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;

    function InternalIncludeSerialize(AInstance: Pointer): Boolean;
  protected
    procedure ProcessAttribute(AAttribute: TCustomAttribute); override;
  public
    constructor Create(AGlobalSettings: TNeonSettings; AMember: TRttiMember; AParent: TNeonRttiADT);

    function IncludeSerialize(AInstance: Pointer): Boolean; inline;
    function IncludeDeserialize(AInstance: Pointer): Boolean; inline;

    // Instance-based methods
    function GetValue(AInstance: Pointer): TValue;
    procedure SetValue(const AValue: TValue; AInstance: Pointer);

    function RttiType: TRttiType;
    function MemberType: TNeonMemberType;
    function IsWritable: Boolean;
    function IsReadable: Boolean;
    function TypeKind: TTypeKind;
    function Visibility: TMemberVisibility;
    function IsField: Boolean;
    function IsProperty: Boolean;
  public
    property Name: string read GetName;
    property ComputedName: string read GetComputedName;
    property Parent: TNeonRttiADT read FParent write FParent;
    //property Serializable: Boolean read FSerializable write FSerializable;
  end;

  TNeonRttiADT = class(TNeonRttiType)
  private type
    TMembersCache = record
      Cacheable: Boolean;
      Cache: TArray<TNeonRttiMember>;
      function Cached: Boolean;
    end;
  private
    FMembers: TObjectList<TNeonRttiMember>;
    FTypeSettings: TNeonSettingsType;

    FCacheSer: TMembersCache;
    FCacheDes: TMembersCache;
  private
    function IgnoredName(const AName: string): Boolean; inline;
    function MatchesVisibility(AVisibility: TMemberVisibility): Boolean;

    { TODO -opaolo -c : Controllare con gli ignore 29/12/2024 21:46:20 }
    function MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;
    function NewMember(AMember: TRttiMember): TNeonRttiMember;

    procedure CreateMembers(AType: TRttiType);
    procedure SortMembers;
  public
    class function New(AGlobalSettings: TNeonSettings; AType: TRttiType): TNeonRttiADT;

    constructor Create(AGlobalSettings: TNeonSettings; AType: TRttiType);
    destructor Destroy; override;

    function FilterSer(AInstance: Pointer): TArray<TNeonRttiMember>;
    function FilterDes(AInstance: Pointer): TArray<TNeonRttiMember>;
  public
    property Members: TObjectList<TNeonRttiMember> read FMembers;
    property GlobalSettings: TNeonSettings read FGlobalSettings;
  end;

  {$ENDREGION}

  {$REGION 'Neon Engine Base Class'}

  {$IFDEF HAS_NO_REF_COUNT}
  TNeonBase = class(TNoRefCountObject, IOperationContext)
  {$ELSE}
  TNeonBase = class(TSingletonImplementation, IConfigurationContext)
  {$ENDIF}
  private type
    TADTRegistry = class(TObjectDictionary<PTypeInfo, TNeonRttiADT>);
    TError = record
      Info: string;
      Message: string;
      function ToString: string;
    end;
    TErrors = class(TList<TError>)
      procedure AddError(const AInfo, AMessage: string);
      function ToStrings: TArray<string>;
    end;
  protected
    FGlobalSettings: TNeonSettings;
    FOperation: TNeonOperation;
    FOriginalInstance: TValue;
    FADTCache: TADTRegistry;
    FErrors: TErrors;
    function IsOriginalInstance(const AValue: TValue): Boolean;
    { TODO -opaolo -c : remove? 06/01/2025 16:36:57 }
    function GetTypeMembers(AType: TRttiType): TArray<TRttiMember>; deprecated;
    function GetNeonADT(AType: TRttiType): TNeonRttiADT;
  public
    constructor Create(const ASettings: TNeonSettings);
    destructor Destroy; override;

    procedure AddError(const AMessage: string); overload;
    procedure AddError(AException: Exception); overload;
    function GetSettings: TNeonSettings;
    function GetOperation: TNeonOperation;
  public
    property Errors: TErrors read FErrors;
    property Settings: TNeonSettings read FGlobalSettings;
  end;

  {$ENDREGION}

implementation

uses
  System.DateUtils,
  System.RegularExpressions,
  Neon.Core.Utils;

{ TNeonBase }

constructor TNeonBase.Create(const ASettings: TNeonSettings);
begin
  FGlobalSettings := ASettings;
  FADTCache := TADTRegistry.Create([doOwnsValues]);
  FErrors := TErrors.Create;
end;

destructor TNeonBase.Destroy;
begin
  FGlobalSettings.Free;
  FErrors.Free;
  FADTCache.Free;
  inherited;
end;

function TNeonBase.GetNeonADT(AType: TRttiType): TNeonRttiADT;
begin
  if FADTCache.TryGetValue(AType.Handle, Result) then
    Exit(Result);

  Result := TNeonRttiADT.New(FGlobalSettings, AType);
  FADTCache.Add(AType.Handle, Result);
end;

function TNeonBase.GetOperation: TNeonOperation;
begin
  Result := FOperation;
end;

function TNeonBase.GetSettings: TNeonSettings;
begin
  Result := FGlobalSettings.Clone;
end;

function TNeonBase.GetTypeMembers(AType: TRttiType): TArray<TRttiMember>;
begin
  SetLength(Result, 0);

  if TNeonMembers.Standard in FGlobalSettings.Members.Value then
  begin
    if AType.IsRecord then
      Result := TArray<TRttiMember>(AType.AsRecord.GetFields)
    else if AType.IsInstance then
      Result := TArray<TRttiMember>(AType.AsInstance.GetProperties);
  end;

  if TNeonMembers.Properties in FGlobalSettings.Members.Value then
  begin
    if AType.IsRecord then
      Result := TArray<TRttiMember>(AType.AsRecord.GetProperties)
    else if AType.IsInstance then
      Result := TArray<TRttiMember>(AType.AsInstance.GetProperties);
  end;

  if TNeonMembers.Fields in FGlobalSettings.Members.Value then
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

procedure TNeonBase.AddError(AException: Exception);
begin
  FErrors.AddError(AException.ClassName, AException.Message);
end;

procedure TNeonBase.AddError(const AMessage: string);
begin
  FErrors.AddError('', AMessage);
end;

{ TNeonConfigurator }

constructor TNeonConfigurator.Create;
begin
  Create(TNeonSettings.Create);
end;

constructor TNeonConfigurator.Create(ASettings: TNeonSettings);
begin
  FInternalSettings := ASettings;

  FTypeConfigurator := TTypeConfigurator.Create(Self);
  SetMemberCase(TNeonCase.Unchanged);
  SetMembers([TNeonMembers.Standard]);
  SetIgnoreFieldPrefix(False);
  SetVisibility([mvPublic, mvPublished]);
  SetUseUTCDate(True);
  SetPrettyPrint(False);
  SetStrictTypes(True);
end;

destructor TNeonConfigurator.Destroy;
begin
  FTypeConfigurator.Free;
  inherited;
end;

class function TNeonConfigurator.Default: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetMemberCase(TNeonCase.PascalCase);
end;

class function TNeonConfigurator.Pretty: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetMemberCase(TNeonCase.PascalCase)
    .SetPrettyPrint(True);
end;

function TNeonConfigurator.RegisterFactory(AClass: TCustomFactoryClass): INeonConfigurator;
begin
  FInternalSettings.FactoryList.Add(AClass);
  Result := Self;
end;

function TNeonConfigurator.RegisterSerializer(AClass: TCustomSerializerClass): INeonConfigurator;
begin
  FInternalSettings.Serializers.RegisterSerializer(AClass);
  AClass.ChangeConfig(Self);
  Result := Self;
end;

function TNeonConfigurator.AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator;
begin
  FInternalSettings.IgnoreMembers := FInternalSettings.IgnoreMembers + AMemberList;
  Result := Self;
end;

function TNeonConfigurator.BuildSettings: TNeonSettings;
begin
  Result := FInternalSettings.Clone;
end;

class function TNeonConfigurator.Camel: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetMemberCase(TNeonCase.CamelCase);
end;

class function TNeonConfigurator.Snake: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetIgnoreFieldPrefix(True)
    .SetMemberCase(TNeonCase.SnakeCase);
end;

function TNeonConfigurator.GetSerializers: TNeonSerializerRegistry;
begin
  Result := FInternalSettings.Serializers;
end;

function TNeonConfigurator.GetTypeConfigurator: TTypeConfigurator;
begin
  Result := FTypeConfigurator;
end;

class function TNeonConfigurator.Kebab: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetMemberCase(TNeonCase.KebabCase);
end;

class function TNeonConfigurator.ScreamingSnake: INeonConfigurator;
begin
  Result := TNeonConfigurator.Create
    .SetIgnoreFieldPrefix(True)
    .SetMemberCase(TNeonCase.ScreamingSnakeCase);
end;

function TNeonConfigurator.SetMembers(AValue: TNeonMembersSet): INeonConfigurator;
begin
  FInternalSettings.Members := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetMemberSort(AValue: TNeonSort): INeonConfigurator;
begin
  FInternalSettings.MemberSort := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetPrettyPrint(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.PrettyPrint := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetRaiseExceptions(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.RaiseExceptions := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetUseUTCDate(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.UseUTCDate := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetAutoCreate(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.AutoCreate := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetEnumAsInt(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.EnumAsInt := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetIgnoreFieldPrefix(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.IgnoreFieldPrefix := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfigurator;
begin
  FInternalSettings.IgnoreMembers := AMemberList;
  Result := Self;
end;

function TNeonConfigurator.SetStrictTypes(AValue: Boolean): INeonConfigurator;
begin
  FInternalSettings.StrictTypes := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetMemberCase(AValue: TNeonCase): INeonConfigurator;
begin
  FInternalSettings.MemberCase := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetMemberCustomCase(AValue: TCaseFunc): INeonConfigurator;
begin
  FInternalSettings.MemberCustomCase := AValue;
  Result := Self;
end;

function TNeonConfigurator.SetVisibility(AValue: TNeonVisibility): INeonConfigurator;
begin
  FInternalSettings.Visibility := AValue;
  Result := Self;
end;

{ TNeonRttiMember }

constructor TNeonRttiMember.Create(AGlobalSettings: TNeonSettings; AMember: TRttiMember; AParent: TNeonRttiADT);
var
  LType: TRttiType;
begin
  LType := (AMember as TRttiDataMember).DataType;
  inherited Create(AGlobalSettings, LType);

  FMember := AMember;
  FParent := AParent;

  if FMember is TRttiProperty then
    FMemberType := TNeonMemberType.Prop
  else if FMember is TRttiField then
    FMemberType := TNeonMemberType.Field;

  { TODO -opaolo -c : Merge the two? 15/01/2025 09:39:06 }
  //FAttributes := LType.GetAttributes;
  FMemberAttributes := FMember.GetAttributes;
  ParseAttributes;
end;

function TNeonRttiMember.EvalInclude(AInstance: Pointer): Nullable<Boolean>;
var
  LRes: TValue;
begin
  // try to invoke a regular method on an existing object
  if Assigned(AInstance) and (FMethodIf.MethodKind = mkFunction) then
  begin
    LRes := FMethodIf.Invoke(TObject(AInstance), [TValue.From<TNeonIgnoreIfContext>(FMethodIfContext)]);
    Exit(LRes.AsType<Boolean>);
  end;

  // if the method is a class method, we can invoke it too, but have to do it a bit differently
  if FMethodIf.MethodKind = mkClassFunction then
  begin
    LRes := FMethodIf.Invoke(FParent.RttiType.AsInstance.MetaClassType, [TValue.From<TNeonIgnoreIfContext>(FMethodIfContext)]);
    Exit(LRes.AsType<Boolean>);
  end;
end;

function TNeonRttiMember.IncludeDeserialize(AInstance: Pointer): Boolean;
begin
  if FNeonInclude.Present and (FNeonInclude.Value = IncludeIf.Always) then
    Exit(True);

  if FNeonIgnore then
    Exit(False);

  if FParent.IgnoredName(Name) then
    Exit(False);

  if not IsWritable then
    Exit(False);

  if MatchesVisibility(Visibility) and MatchesMemberChoice(MemberType) then
    Exit(True);

  Result := False;
end;

function TNeonRttiMember.IncludeSerialize(AInstance: Pointer): Boolean;
var
  LRes: Nullable<Boolean>;
begin
  Result := InternalIncludeSerialize(AInstance);

  if Assigned(FMethodIf) then
  begin
    FMethodIfContext.Operation := TNeonOperation.Serialize;
    LRes := EvalInclude(AInstance);
    if LRes.HasValue then
      Result := LRes;
  end;
end;

function TNeonRttiMember.GetComputedName: string;
var
  LName: string;
begin
  if not FNeonProperty.IsEmpty then
    Exit(FNeonProperty);

  if not FComputedName.IsEmpty then
    Exit(FComputedName);

  LName := Name;

  if FComputed.IgnoreFieldPrefix and IsField and
     LName.StartsWith('F', True) and
     (Visibility in [mvPrivate, mvProtected]) then
    LName := LName.Substring(1);

  case FComputed.Membercase of
    TNeonCase.Unchanged : LName := LName;
    TNeonCase.LowerCase : LName := LowerCase(LName);
    TNeonCase.UpperCase : LName := UpperCase(LName);
    TNeonCase.PascalCase: LName := LName;
    TNeonCase.CamelCase : LName := TCaseAlgorithm.PascalToCamel(LName);
    TNeonCase.SnakeCase : LName := TCaseAlgorithm.PascalToSnake(LName);
    TNeonCase.KebabCase : LName := TCaseAlgorithm.PascalToKebab(LName);
    TNeonCase.ScreamingSnakeCase : LName := TCaseAlgorithm.PascalToScreamingSnake(LName);
    TNeonCase.CustomCase: LName := FParent.Computed.MemberCustomCase(LName);
  end;
  FComputedName := LName;
  Result := FComputedName;
end;

function TNeonRttiMember.GetName: string;
begin
  Result := FMember.Name;
end;

function TNeonRttiMember.GetValue(AInstance: Pointer): TValue;
begin
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create(TNeonError.FIELD_PROP);
    TNeonMemberType.Prop   : Result := MemberAsProperty.GetValue(AInstance);
    TNeonMemberType.Field  : Result := MemberAsField.GetValue(AInstance);
  end;
end;

function TNeonRttiMember.InternalIncludeSerialize(AInstance: Pointer): Boolean;
begin
  if FNeonInclude.Present and (FNeonInclude.Value = IncludeIf.Always) then
    Exit(True);

  // Exclusions
  if FNeonIgnore then
    Exit(False);

  if not IsReadable then
    Exit(False);

  if FParent.IgnoredName(Name) then
    Exit(False);

  if not IsWritable and not (TypeKind in [tkClass, tkInterface]) then
    Exit(False);

  if MatchesVisibility(Visibility) and MatchesMemberChoice(MemberType) then
    Exit(True);

  Result := False;
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
    TNeonMemberType.Unknown: raise ENeonException.Create(TNeonError.FIELD_PROP);
    TNeonMemberType.Prop   : Result := MemberAsProperty.IsReadable;
    TNeonMemberType.Field  : Result := True;
  end;
end;

function TNeonRttiMember.IsWritable: Boolean;
begin
  Result := False;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create(TNeonError.FIELD_PROP);
    TNeonMemberType.Prop   : Result := MemberAsProperty.IsWritable;
    TNeonMemberType.Field  : Result := True;
  end;
end;

function TNeonRttiMember.MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;
var
  LRttiType: TRttiType;
  LMemberChoice: TNeonMembersSet;
begin
  Result := False;
  if FParent.NeonMembers = [] then
    LMemberChoice := FComputed.Members
  else
    LMemberChoice := FParent.NeonMembers;

  if TNeonMembers.Standard in LMemberChoice then
  begin
    LRttiType := FParent.RttiType;
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

function TNeonRttiMember.MatchesVisibility(AVisibility: TMemberVisibility): Boolean;
var
  LVisibility: TNeonVisibility;
begin
  Result := False;

  if FParent.NeonVisibility = [] then
    LVisibility := FComputed.Visibility
  else
    LVisibility := FParent.NeonVisibility;

  if AVisibility in LVisibility then
    Result := True;
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
    TNeonMemberType.Unknown: raise ENeonException.Create(TNeonError.FIELD_PROP);
    TNeonMemberType.Prop   : Result := MemberAsProperty.PropertyType;
    TNeonMemberType.Field  : Result := MemberAsField.FieldType;
  end;
end;

procedure TNeonRttiMember.ProcessAttribute(AAttribute: TCustomAttribute);
var
  LIncludeAttribute: NeonIncludeAttribute;
  LMethodName: string;
begin
  FCacheable := True;
  if AAttribute is NeonIncludeAttribute then
  begin
    LIncludeAttribute := AAttribute as NeonIncludeAttribute;
    if LIncludeAttribute.IncludeValue.Value = IncludeIf.CustomFunction then
    begin
      LMethodName := LIncludeAttribute.IncludeValue.IncludeFunction;
      FMethodIf := FParent.RttiType.GetMethod(LMethodName);
      if not Assigned(FMethodIf) then
        raise ENeonException.CreateFmt(TNeonError.NO_METHOD_F2, [LMethodName, FParent.RttiType.Name]);

      FMethodIfContext := TNeonIgnoreIfContext.Create(Self.Name);
      FCacheable := False;
    end;
  end;
end;

procedure TNeonRttiMember.SetValue(const AValue: TValue; AInstance: Pointer);
begin
  case FMemberType of
    TNeonMemberType.Prop :
    begin
      if MemberAsProperty.IsWritable then
        MemberAsProperty.SetValue(AInstance, AValue);
    end;
    TNeonMemberType.Field: MemberAsField.SetValue(AInstance, AValue);
  end;
end;

function TNeonRttiMember.TypeKind: TTypeKind;
begin
  Result := tkUnknown;
  case FMemberType of
    TNeonMemberType.Unknown: raise ENeonException.Create(TNeonError.FIELD_PROP);
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

class function TCaseAlgorithm.KebabToPascal(const AString: string): string;
var
  LChar: Char;
  LIndex: Integer;
  LSingleWord: string;
  LWords: TArray<string>;
begin
  LWords := AString.Split(['-']);
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

class function TCaseAlgorithm.PascalToKebab(const AString: string): string;
begin
  Result := LowerCase(
    TRegEx.Replace(AString,
    '([A-Z][a-z\d]+)(?=([A-Z][A-Z\a-z\d]+))', '$1-', [])
  );
end;

class function TCaseAlgorithm.PascalToSnake(const AString: string): string;
begin
  Result := LowerCase(
    TRegEx.Replace(AString,
    '([A-Z][a-z\d]+)(?=([A-Z][A-Z\a-z\d]+))', '$1_', [])
  );
end;

class function TCaseAlgorithm.PascalToScreamingSnake(const AString: string):
    string;
begin
  Result := UpperCase(
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

{ TNeonRttiADT }

constructor TNeonRttiADT.Create(AGlobalSettings: TNeonSettings; AType: TRttiType);
begin
  inherited Create(AGlobalSettings, AType);

  FMembers := TObjectList<TNeonRttiMember>.Create(True);
  FTypeSettings := FGlobalSettings.GetSettingsByType(AType);
end;

procedure TNeonRttiADT.CreateMembers(AType: TRttiType);
var
  LFields, LProps: TArray<TRttiMember>;
  LMember: TRttiMember;
  LNeonMember: TNeonRttiMember;
begin
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
    LNeonMember := NewMember(LMember);
    FMembers.Add(LNeonMember);
  end;
  for LMember in LProps do
  begin
    LNeonMember := NewMember(LMember);
    FMembers.Add(LNeonMember);
  end;

  SortMembers;
end;

destructor TNeonRttiADT.Destroy;
begin
  FMembers.Free;
  inherited;
end;

function TNeonRttiADT.FilterDes(AInstance: Pointer): TArray<TNeonRttiMember>;
var
  LMember: TNeonRttiMember;
begin
  if FCacheDes.Cached then
    Exit(FCacheDes.Cache);

  Result := [];
  FCacheDes.Cacheable := True;  // Always cacheable AInstance not used
  for LMember in FMembers do
    if LMember.IncludeDeserialize(AInstance) then
      Result := Result + [LMember];
  FCacheDes.Cache := Result;
end;

function TNeonRttiADT.FilterSer(AInstance: Pointer): TArray<TNeonRttiMember>;
var
  LMember: TNeonRttiMember;
begin
  if FCacheSer.Cached then
    Exit(FCacheSer.Cache);

  Result := [];
  FCacheSer.Cacheable := True;
  for LMember in FMembers do
  begin
    if not LMember.FCacheable then
      FCacheSer.Cacheable := False;

    if LMember.IncludeSerialize(AInstance) then
      Result := Result + [LMember];
  end;
  FCacheSer.Cache := Result;
end;

function TNeonRttiADT.IgnoredName(const AName: string): Boolean;
begin
  Result := FGlobalSettings.IgnoreMember(FRttiType, AName);
end;

function TNeonRttiADT.MatchesMemberChoice(AMemberType: TNeonMemberType): Boolean;
var
  LRttiType: TRttiType;
  LMemberChoice: TNeonMembersSet;
begin
  Result := False;
  if FNeonMembers = [] then
    LMemberChoice := FComputed.Members
  else
    LMemberChoice := FNeonMembers;

  if TNeonMembers.Standard in LMemberChoice then
  begin
    LRttiType := FRttiType;
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

function TNeonRttiADT.MatchesVisibility(AVisibility: TMemberVisibility): Boolean;
var
  LVisibility: TNeonVisibility;
begin
  Result := False;

  if FNeonVisibility = [] then
    LVisibility := FComputed.Visibility
  else
    LVisibility := FNeonVisibility;

  if AVisibility in LVisibility then
    Result := True;
end;

class function TNeonRttiADT.New(AGlobalSettings: TNeonSettings; AType: TRttiType): TNeonRttiADT;
begin
  Result := TNeonRttiADT.Create(AGlobalSettings, AType);
  try
    Result.CreateMembers(AType);
  except
    Result.Free;
    raise;
  end;
end;

function TNeonRttiADT.NewMember(AMember: TRttiMember): TNeonRttiMember;
begin
  Result := TNeonRttiMember.Create(FGlobalSettings, AMember, Self);
end;

procedure TNeonRttiADT.SortMembers;

  function AlphaComparer(AReverse: Boolean): IComparer<TNeonRttiMember>;
  begin
    Result := TComparer<TNeonRttiMember>.Construct(
      function (const L, R: TNeonRttiMember): Integer
      begin
        if AReverse then
          Result := CompareStr(R.Name, L.Name)
        else
          Result := CompareStr(L.Name, R.Name);
      end
    );
  end;

begin
  case FComputed.MemberSort of
    TNeonSort.Rtti: ; // Default, do nothing
    TNeonSort.RttiReverse: FMembers.Reverse;
    TNeonSort.Alpha: FMembers.Sort(AlphaComparer(False));
    TNeonSort.AlphaReverse: FMembers.Sort(AlphaComparer(True));
  end;
end;

{ TNeonRttiType }

constructor TNeonRttiType.Create(AGlobalSettings: TNeonSettings; AType: TRttiType);
begin
  FComputed := TNeonSettingsProxy.Create(AGlobalSettings,AType);
  FComputed.LoadValues;
  FGlobalSettings := AGlobalSettings; //remove?
  FRttiType := AType;
  FAttributes := FRttiType.GetAttributes;
  FNeonMembers := [];

  ParseAttributes;
end;

destructor TNeonRttiType.Destroy;
begin
  FComputed.Free;
  inherited;
end;

function TNeonRttiType.EnumToString(ATypeInfo: PTypeInfo; AValue: Integer): string;
var
  LTypeData: PTypeData;
begin
  Result := '';

  LTypeData := GetTypeData(ATypeInfo);
  if (AValue >= LTypeData.MinValue) and (AValue <= LTypeData.MaxValue) then
  begin
    Result := GetEnumName(ATypeInfo, AValue);

    if Length(FNeonEnumNames) > 0 then
    begin
      if (AValue >= Low(FNeonEnumNames)) and
         (AValue <= High(FNeonEnumNames)) then
        Result := FNeonEnumNames[AValue]
    end;
  end
  else
    raise ENeonException.CreateFmt(TNeonError.ENUM_VALUE_F1, [AValue]);
end;

function TNeonRttiType.EnumToString(const AValue: TValue): string;
begin
  Result := EnumToString(AValue.TypeInfo, AValue.AsOrdinal);
end;

function TNeonRttiType.GetAttribute<T>: T;
begin
  Result := GetAttributeFrom<T>(FAttributes);
end;

function TNeonRttiType.GetAttributeFrom<T>(const AList: TArray<TCustomAttribute>): T;
var
  LAttr: TCustomAttribute;
begin
  Result := nil;
  for LAttr in AList do
    if LAttr is T then
      Exit(LAttr as T);
end;

function TNeonRttiType.GetDateTime(const AValue: string): TDateTime;
begin
  Result := 0.0;
  if AValue <> '' then
    Result := ISO8601ToDate(AValue, FComputed.UseUTCDate);
end;

function TNeonRttiType.GetMemberAttribute<T>: T;
begin
  Result := GetAttributeFrom<T>(FMemberAttributes);
end;

procedure TNeonRttiType.InternalParseAttributes(const AAttr: TArray<TCustomAttribute>);
var
  LAttribute: TCustomAttribute;
  LClass: TClass;
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
    else if LAttribute is NeonFactoryAttribute then
    begin
      LClass := (LAttribute as NeonFactoryAttribute).FactoryClass;
      if LClass.InheritsFrom(TCustomFactory) then
        FNeonFactoryClass := TCustomFactoryClass(LClass);
    end
    else if LAttribute is NeonItemFactoryAttribute then
    begin
      LClass := (LAttribute as NeonItemFactoryAttribute).FactoryClass;
      if LClass.InheritsFrom(TCustomFactory) then
        FNeonItemFactoryClass := TCustomFactoryClass(LClass);
    end
    else if LAttribute is NeonIgnoreAttribute then
      FNeonIgnore := True
    else if LAttribute is NeonRawValueAttribute then
      FNeonRawValue := True
    else if LAttribute is NeonPropertyAttribute then
      FNeonProperty := (LAttribute as NeonPropertyAttribute).Value
    else if LAttribute is NeonEnumNamesAttribute then
      FNeonEnumNames := (LAttribute as NeonEnumNamesAttribute).Names
    else if LAttribute is NeonVisibilityAttribute then
      FNeonVisibility := (LAttribute as NeonVisibilityAttribute).Value
    else if LAttribute is NeonMembersSetAttribute then
      FNeonMembers := (LAttribute as NeonMembersSetAttribute).Value
    else if LAttribute is NeonUnwrappedAttribute then
      FNeonUnwrapped := True  //Only applicable to complex types (classes, records, interfaces)
    else if LAttribute is NeonAutoCreateAttribute then
      FNeonAutoCreate := True;  //Only applicable to class types

    // Further attribute processing
    ProcessAttribute(LAttribute);
  end;
end;

procedure TNeonRttiType.ParseAttributes;
begin
  if Length(FMemberAttributes) > 0 then
    InternalParseAttributes(FMemberAttributes);
  if Length(FAttributes) > 0 then
    InternalParseAttributes(FAttributes);
end;

procedure TNeonRttiType.ProcessAttribute(AAttribute: TCustomAttribute);
begin

end;

{ TNeonSerializerRegistry }

procedure TNeonSerializerRegistry.Assign(ARegistry: TNeonSerializerRegistry);
var
  LInfo: TSerializerInfo;
  LPair: TPair<PTypeInfo, TCustomSerializer>;
begin
  for LInfo in ARegistry.FRegistryClass do
    FRegistryClass.Add(LInfo);

  ARegistry.FRegistryCacheLock.Enter;
  FRegistryCacheLock.Enter;
  try
    for LPair in ARegistry.FRegistryCache do
      FRegistryCache.Add(LPair.Key, LPair.Value);
  finally
    FRegistryCacheLock.Leave;
    ARegistry.FRegistryCacheLock.Leave
  end;
end;

procedure TNeonSerializerRegistry.Clear;
begin
  FRegistryClass.Clear;
  ClearCache;
end;

procedure TNeonSerializerRegistry.ClearCache;
begin
  FRegistryCacheLock.Enter;
  try
    FRegistryCache.Clear;
  finally
    FRegistryCacheLock.Leave
  end;
end;

constructor TNeonSerializerRegistry.Create;
begin
  FRegistryClass := SerializerClassRegistry.Create();
  FRegistryCache := SerializerCacheRegistry.Create([doOwnsValues]);
  FRegistryCacheLock := TCriticalSection.Create;
end;

destructor TNeonSerializerRegistry.Destroy;
begin
  FRegistryClass.Free;
  FRegistryCache.Free;
  FRegistryCacheLock.Free;
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

  FRegistryCacheLock.Enter;
  try
    if FRegistryCache.TryGetValue(ATypeInfo, Result) then
      Exit(Result);
  finally
    FRegistryCacheLock.Leave
  end;

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
    FRegistryCacheLock.Enter;
    try
      if FRegistryCache.TryGetValue(ATypeInfo, Result) then
        Exit(Result);

      Result := LClass.Create;
      FRegistryCache.Add(ATypeInfo, Result);
    finally
      FRegistryCacheLock.Leave
    end;
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

{ TNeonSerializerRegistry.TSerializerInfo }

class function TNeonSerializerRegistry.TSerializerInfo.FromSerializer(ASerializerClass: TCustomSerializerClass): TSerializerInfo;
begin
  Result.SerializerClass := ASerializerClass;
  Result.Distance := ASerializerClass.ClassDistance;
end;


{ TCustomSerializer }

class procedure TCustomSerializer.ChangeConfig(AConfig: INeonConfigurator);
begin

end;

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

{ TTypeConfigurator }

constructor TTypeConfigurator.Create(AConfigurator: TNeonConfigurator);
begin
  FConfigurator := AConfigurator;
end;

function TTypeConfigurator.CreateConfigForType(AType: TRttiType): INeonConfiguratorType;
var
  LSettings: TNeonSettingsType;
begin
  LSettings := (FConfigurator as TNeonConfigurator).FInternalSettings.GetCreateSettingsByType(AType);
  Result := TNeonConfiguratorType.Create(FConfigurator, LSettings);
end;

function TTypeConfigurator.Rules<T>: INeonConfiguratorType;
var
  LType: TRttiType;
begin
  LType := TRttiUtils.Context.GetType(TypeInfo(T));

  if not Assigned(LType) then
    raise ENeonException.Create('TTypeConfigurator: Unknown type T');

  // Create and register the config for the specific type
  Result := CreateConfigForType(LType);
end;

function TTypeConfigurator.ForClass<T>: INeonConfiguratorType;
begin
  Result := Rules<T>;
end;

function TTypeConfigurator.ForRecord<T>: INeonConfiguratorType;
begin
  Result := Rules<T>;
end;

{ TNeonConfiguratorType }

function TNeonConfiguratorType.AddIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType;
begin
  FSettings.IgnoreMembers := FSettings.IgnoreMembers + AMemberList;
  Result := Self;
end;

function TNeonConfiguratorType.SetIgnoreFieldPrefix(AValue: Boolean): INeonConfiguratorType;
begin
  FSettings.IgnoreFieldPrefix := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.SetIgnoreMembers(const AMemberList: TArray<string>): INeonConfiguratorType;
begin
  FSettings.IgnoreMembers := AMemberList;
  Result := Self;
end;

function TNeonConfiguratorType.SetMemberCase(AValue: TNeonCase): INeonConfiguratorType;
begin
  FSettings.MemberCase := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.SetMemberCustomCase(AValue: TCaseFunc): INeonConfiguratorType;
begin
  FSettings.MemberCustomCase := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.SetMembers(AValue: TNeonMembersSet): INeonConfiguratorType;
begin
  FSettings.Members := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.SetMemberSort(AValue: TNeonSort): INeonConfiguratorType;
begin
  FSettings.MemberSort := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.SetVisibility(AValue: TNeonVisibility): INeonConfiguratorType;
begin
  FSettings.Visibility := AValue;
  Result := Self;
end;

function TNeonConfiguratorType.BackToConfig: INeonConfigurator;
begin
  Result := FConfigurator;
end;

constructor TNeonConfiguratorType.Create(AConfigurator: INeonConfigurator; ATypeSettings: TNeonSettingsType);
begin
  FConfigurator := AConfigurator;
  FSettings := ATypeSettings;
end;

{ TNeonSettings }

function TNeonSettings.Clone: TNeonSettings;
begin
  Result := TNeonSettings.Create;
  Result.Assign(Self);
end;

constructor TNeonSettings.Create;
begin
  FTypeSettings := TSettingsTypeList.Create;
  FSerializers := TNeonSerializerRegistry.Create;
  FFactoryList := TNeonFactoryRegistry.Create;

  FMembers := [TNeonMembers.Standard];
  FMemberCase := TNeonCase.Unchanged;
  FIgnoreFieldPrefix := False;
  FVisibility := [mvPublic, mvPublished];
  FUseUTCDate := True;
  FPrettyPrint := False;
  FStrictTypes := True;
  FRaiseExceptions := False;
  FEnumAsInt := False;
  FAutoCreate := False;
  FMemberSort := TNeonSort.Rtti;
  FMemberCustomCase := nil;
end;

destructor TNeonSettings.Destroy;
begin
  FreeTypeSettings;
  FTypeSettings.Free;
  FFactoryList.Free;
  FSerializers.Free;
  inherited;
end;

class function TNeonSettings.Default: TNeonSettings;
begin
  Result := TNeonSettings.Create;
end;

procedure TNeonSettings.Assign(ASource: TNeonSettingsType);
var
  LSettings: TNeonSettings;
begin
  inherited Assign(ASource);

  if ASource is TNeonSettings then
  begin
    LSettings := ASource as TNeonSettings;

    FUseUTCDate := LSettings.UseUTCDate;
    FRaiseExceptions := LSettings.RaiseExceptions;
    FEnumAsInt := LSettings.EnumAsInt;
    FAutoCreate := LSettings.AutoCreate;
    FStrictTypes := LSettings.StrictTypes;
    FPrettyPrint := LSettings.PrettyPrint;

    FSerializers.Assign(LSettings.Serializers);
    FFactoryList.Assign(LSettings.FactoryList);
    FTypeSettings.Assign(LSettings.TypeSettings);
  end;

end;

class function TNeonSettings.Camel: TNeonSettings;
begin
  Result := TNeonSettings.Default;
  Result.MemberCase := TNeonCase.CamelCase;
end;

class function TNeonSettings.Kebab: TNeonSettings;
begin
  Result := TNeonSettings.Default;
  Result.MemberCase := TNeonCase.KebabCase;
end;

class function TNeonSettings.Pretty: TNeonSettings;
begin
  Result := TNeonSettings.Default;
  Result.MemberCase := TNeonCase.PascalCase;
  Result.PrettyPrint := True;
end;

class function TNeonSettings.ScreamingSnake: TNeonSettings;
begin
  Result := TNeonSettings.Default;
  Result.MemberCase := TNeonCase.ScreamingSnakeCase;
end;

class function TNeonSettings.Snake: TNeonSettings;
begin
  Result := TNeonSettings.Default;
  Result.MemberCase := TNeonCase.SnakeCase;
end;

procedure TNeonSettings.FreeTypeSettings;
var
  LPair: TSettingsTypePair;
begin
  for LPair in FTypeSettings do
    LPair.Value.Free;
end;

function TNeonSettings.GetCreateSettingsByType(AType: TRttiType): TNeonSettingsType;
var
  LPair: TSettingsTypePair;
begin
  for LPair in FTypeSettings do
    if LPair.Key.QualifiedName = AType.QualifiedName then
      Exit(LPair.Value);

  Result := TNeonSettingsType.Create;
  FTypeSettings.Add(TSettingsTypePair.Create(AType, Result));
end;

function TNeonSettings.GetSettingsByType(AType: TRttiType): TNeonSettingsType;
var
  LPair: TSettingsTypePair;
begin
  if FTypeSettings.Count = 0 then
    Exit(nil);

  if AType.IsInstance then
    for LPair in FTypeSettings do
      if LPair.Key.IsInstance then
        if AType.AsInstance.MetaclassType.InheritsFrom(LPair.Key.AsInstance.MetaclassType) then
          Exit(LPair.Value);

  if AType.IsRecord then
    for LPair in FTypeSettings do
      if AType.QualifiedName = LPair.Key.QualifiedName then
        Exit(LPair.Value);

  Result := nil;
end;

function TNeonSettings.IgnoreMember(AType: TRttiType; const AMember: string): Boolean;
var
  LMember: string;
begin
  // First find a correspondence in the global ignore list
  for LMember in FIgnoreMembers do
    if SameText(AMember, LMember) then
      Exit(True);

  if AType.IsRecord then
    Exit(FTypeSettings.IgnoreRecord(AType.AsRecord, AMember));

  if AType.IsInstance then
    Exit(FTypeSettings.IgnoreClass(AType.AsInstance, AMember));

  Result := False;
end;

procedure TSettingsTypeList.Assign(ASource: TSettingsTypeList);
var
  LPair, LNewPair: TSettingsTypePair;
  LSettings: TNeonSettingsType;
begin
  for LPair in ASource do
  begin
    LSettings := LPair.Value.Clone;
    LNewPair := TSettingsTypePair.Create(LPair.Key, LSettings);
    Self.Add(LNewPair);
  end;
end;

function TSettingsTypeList.IgnoreClass(AType: TRttiInstanceType; const AMember: string): Boolean;
var
  LSettings: TSettingsTypePair;
begin
  for LSettings in Self do
    if LSettings.Key.IsInstance then
      if AType.MetaclassType.InheritsFrom(LSettings.Key.AsInstance.MetaclassType) then
        if LSettings.Value.IgnoreMember(AMember) then
          Exit(True);

  Result := False;
end;

function TSettingsTypeList.IgnoreRecord(AType: TRttiRecordType; const AMember: string): Boolean;
var
  LSettings: TSettingsTypePair;
begin
  for LSettings in Self do
    if AType.QualifiedName = LSettings.Key.QualifiedName then
      if LSettings.Value.IgnoreMember(AMember) then
        Exit(True);

  Result := False;
end;

procedure TNeonSettingsType.Assign(ASource: TNeonSettingsType);
begin
  FMembers := ASource.Members;
  FMemberSort := ASource.MemberSort;
  FMemberCase := ASource.MemberCase;
  FMemberCustomCase := ASource.MemberCustomCase;
  FVisibility := ASource.Visibility;
  FIgnoreFieldPrefix := ASource.IgnoreFieldPrefix;
  FIgnoreMembers := ASource.IgnoreMembers;
end;

function TNeonSettingsType.Clone: TNeonSettingsType;
begin
  Result := TNeonSettingsType.Create;
  Result.Assign(Self);
end;

function TNeonSettingsType.IgnoreMember(const AMember: string): Boolean;
var
  LMember: string;
begin
  for LMember in FIgnoreMembers do
    if SameText(AMember, LMember) then
      Exit(True);

  Result := False;
end;

{ TNeonBase.TError }

function TNeonBase.TError.ToString: string;
begin
  Result := Format('%s: %s', [Info, Message]);
end;

{ TNeonRttiADT.TMembersCache }

function TNeonRttiADT.TMembersCache.Cached: Boolean;
begin
  Result := Cacheable and (Length(Cache) > 0);
end;

{ TNeonBase.TErrors }

procedure TNeonBase.TErrors.AddError(const AInfo, AMessage: string);
var
  LErr: TError;
begin
  LErr.Info := AInfo;
  LErr.Message := AMessage;
  Self.Add(LErr);
end;

function TNeonBase.TErrors.ToStrings: TArray<string>;
var
  LError: TError;
begin
  Result := [];
  for LError in Self do
    Result := Result + [LError.ToString];
end;

{ TNeonSettingsProxy }

constructor TNeonSettingsProxy.Create(ASettings: TNeonSettings; AType: TRttiType);
begin
  FGlobal := ASettings;
  FType := AType;

  LoadValues;
end;

procedure TNeonSettingsProxy.DefaultSettings;
begin
  FMembers := [TNeonMembers.Standard];
  FMemberSort := TNeonSort.Rtti;
  FMemberCase := TNeonCase.Unchanged;
  FMemberCustomCase := nil;
  FVisibility := [mvPublic, mvPublished];
  FIgnoreFieldPrefix := False;
  FIgnoreMembers := [];

  FUseUTCDate := False;
  FRaiseExceptions := False;
  FEnumAsInt := False;
  FAutoCreate := False;
  FStrictTypes := False;
  FPrettyPrint := False;
end;

procedure TNeonSettingsProxy.LoadFromSettings(ACustom: TNeonSettingsType);
begin
  DefaultSettings;

  if ACustom.Members.HasValue then
    FMembers := ACustom.Members.Value
  else if FGlobal.Members.HasValue then
    FMembers := FGlobal.Members.Value;

  if ACustom.MemberSort.HasValue then
    FMemberSort := ACustom.MemberSort.Value
  else if FGlobal.MemberSort.HasValue then
    FMemberSort := FGlobal.MemberSort.Value;

  if ACustom.MemberCase.HasValue then
    FMemberCase := ACustom.MemberCase.Value
  else if FGlobal.MemberCase.HasValue then
    FMemberCase := FGlobal.MemberCase.Value;

  if Assigned(ACustom.MemberCustomCase) then
    FMemberCustomCase := ACustom.MemberCustomCase
  else
    FMemberCustomCase := FGlobal.MemberCustomCase;

  if ACustom.Visibility.HasValue then
    FVisibility := ACustom.Visibility.Value
  else if FGlobal.Visibility.HasValue then
    FVisibility := FGlobal.Visibility.Value;

  if ACustom.IgnoreFieldPrefix.HasValue then
    FIgnoreFieldPrefix := ACustom.IgnoreFieldPrefix.Value
  else if FGlobal.IgnoreFieldPrefix.HasValue then
    FIgnoreFieldPrefix := FGlobal.IgnoreFieldPrefix.Value;

  // Ignore Members (merge)
  FIgnoreMembers := ACustom.IgnoreMembers + FGlobal.IgnoreMembers;

  // Global Settings

  if FGlobal.UseUTCDate.HasValue then
    FUseUTCDate := FGlobal.UseUTCDate.Value;

  if FGlobal.RaiseExceptions.HasValue then
    FRaiseExceptions := FGlobal.RaiseExceptions.Value;

  if FGlobal.EnumAsInt.HasValue then
    FEnumAsInt := FGlobal.EnumAsInt.Value;

  if FGlobal.AutoCreate.HasValue then
    FAutoCreate := FGlobal.AutoCreate.Value;

  if FGlobal.StrictTypes.HasValue then
    FStrictTypes := FGlobal.StrictTypes.Value;

  if FGlobal.PrettyPrint.HasValue then
    FPrettyPrint := FGlobal.PrettyPrint.Value;
end;

procedure TNeonSettingsProxy.LoadValues;
var
  LSettings, LDummy: TNeonSettingsType;
begin
  if FLoaded then
    Exit;

  LSettings := FGlobal.GetSettingsByType(FType);
  if not Assigned(LSettings) then
  begin
    LDummy := TNeonSettingsType.Create;
    try
      LoadFromSettings(LDummy);
    finally
      LDummy.Free;
    end;
  end
  else
    LoadFromSettings(LSettings);

  FLoaded := True;
end;

{ TNeonFactoryRegistry }

procedure TNeonFactoryRegistry.Assign(ASource: TNeonFactoryRegistry);
var
  LFact: TCustomFactoryClass;
begin
  for LFact in ASource do
    Add(LFact);
end;

end.
