{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.JsonSchema;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo, System.Rtti, System.JSON, System.Generics.Collections,
  Data.DB,
  DUnitX.TestFramework,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Nullables,
  Neon.Core.Utils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema,
  Neon.Core.Serializers.RTL;

type
  TSchemaPerson = class
  private
    FName: string;
    FAge: Integer;
    FEmail: string;
    FNickname: string;
  public
    [JsonSchema('description=The person''s full name,required')]
    property Name: string read FName write FName;

    [JsonSchema('readOnly')]
    property Age: Integer read FAge write FAge;

    property Email: string read FEmail write FEmail;

    // Description value contains the tag separator (comma) and must be quoted
    [JsonSchema('description="A name, informally"')]
    property Nickname: string read FNickname write FNickname;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaAttribute = class(TObject)
  public
    [Test]
    procedure TestParseTagsExposesTags;

    [Test]
    procedure TestParseTagsIsIdempotent;

    [Test]
    procedure TestParseTagsOnEmptyStringIsIdempotent;
  end;

  TSchemaConstraintPerson = class
  private
    FName: string;
    FAge: Integer;
    FScore: Double;
    FTags: TArray<string>;
    FNickname: Nullable<string>;
  public
    [JsonSchema('minLength=2,maxLength=50,pattern="^[A-Z].*$"')]
    property Name: string read FName write FName;

    [JsonSchema('minimum=0,maximum=120,multipleOf=1')]
    property Age: Integer read FAge write FAge;

    [JsonSchema('exclusiveMinimum=0.0,exclusiveMaximum=100.0')]
    property Score: Double read FScore write FScore;

    [JsonSchema('minItems=1,maxItems=5,uniqueItems')]
    property Tags: TArray<string> read FTags write FTags;

    property Nickname: Nullable<string> read FNickname write FNickname;
  end;

  [JsonSchema('minProperties=1,maxProperties=10,title=A person,deprecated,default=hello')]
  TSchemaMetaPerson = class
  private
    FName: string;
    FKind: string;
  public
    property Name: string read FName write FName;

    // "const" dates from Draft-06, so it survives into a Draft-07 document
    [JsonSchema('const=person')]
    property Kind: string read FKind write FKind;
  end;

  TSchemaTreeNode = class
  private
    FChildren: TObjectList<TSchemaTreeNode>;
  public
    constructor Create;
    destructor Destroy; override;
    property Children: TObjectList<TSchemaTreeNode> read FChildren write FChildren;
  end;

  TSchemaBook = class;

  // Mutual recursion: neither type refers to itself, but the pair forms a cycle
  TSchemaAuthor = class
  private
    FName: string;
    FBooks: TObjectList<TSchemaBook>;
  public
    property Name: string read FName write FName;
    property Books: TObjectList<TSchemaBook> read FBooks write FBooks;
  end;

  TSchemaBook = class
  private
    FTitle: string;
    FAuthor: TSchemaAuthor;
  public
    property Title: string read FTitle write FTitle;
    property Author: TSchemaAuthor read FAuthor write FAuthor;
  end;

  // Reaches the recursive pair from a member rather than from the root
  TSchemaLibrary = class
  private
    FOwner: string;
    FTop: TSchemaAuthor;
  public
    property Owner: string read FOwner write FOwner;
    property Top: TSchemaAuthor read FTop write FTop;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaGenerator = class(TObject)
  private
    FSchema: TJSONObject;
    function Properties: TJSONObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestObjectType;

    [Test]
    procedure TestDescriptionIsApplied;

    [Test]
    procedure TestDescriptionWithQuotedCommaIsApplied;

    [Test]
    procedure TestRequiredMemberIsMovedToTopLevelArray;

    [Test]
    procedure TestRequiredKeyIsRemovedFromMemberSchema;

    [Test]
    procedure TestReadOnlyIsApplied;

    [Test]
    procedure TestMemberWithoutAttributeHasNoExtraKeys;
  end;

  TSchemaAddress = class
  private
    FCity: string;
    FZip: string;
  public
    [JsonSchema('required')]
    property City: string read FCity write FCity;

    property Zip: string read FZip write FZip;
  end;

  TSchemaOrder = class
  private
    FCode: string;
    FAddress: TSchemaAddress;
  public
    property Code: string read FCode write FCode;

    // Required *and* an object with a required member of its own: the member
    // flag must not collide with the nested "required" array
    [JsonSchema('required')]
    property Address: TSchemaAddress read FAddress write FAddress;
  end;

  ISchemaService = interface(IInvokable)
    ['{0B0D6E5A-2C2E-4E9E-9C1C-6A0B2D9E1F31}']
  end;

  TSchemaService = class(TInterfacedObject, ISchemaService)
  private
    FEndpoint: string;
  public
    property Endpoint: string read FEndpoint write FEndpoint;
  end;

  TSchemaClient = class
  private
    FName: string;
    FService: ISchemaService;
  public
    property Name: string read FName write FName;

    // Serialized as the implementing object, so the schema must describe an
    // object rather than omitting the member
    property Service: ISchemaService read FService write FService;
  end;

  TSchemaWithEvent = class
  private
    FName: string;
    FOnChange: TNotifyEvent;
  public
    property Name: string read FName write FName;

    // A method pointer has no writer at all: the member is skipped, and the
    // attribute on it must not be applied to the nil schema
    [JsonSchema('description=ignored')]
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TSchemaColor = (Red, Green, Blue);
  TSchemaColors = set of TSchemaColor;

  TSchemaPalette = class
  private
    FMain: TSchemaColor;
    FColors: TSchemaColors;
    FTint: Nullable<TSchemaColor>;
    FCode: Nullable<string>;
  public
    property Main: TSchemaColor read FMain write FMain;
    property Colors: TSchemaColors read FColors write FColors;

    // Nullable over an enum: the "enum" has to admit null as well, or it
    // contradicts the ["string","null"] union
    property Tint: Nullable<TSchemaColor> read FTint write FTint;

    // Nullable with a const: same contradiction, applied after WriteNullable
    [JsonSchema('const=abc')]
    property Code: Nullable<string> read FCode write FCode;
  end;

  // Structurally streamable: LoadFromStream + SaveToStream is all the engine
  // looks for, and both sides Base64-encode the result
  TSchemaBlob = class
  public
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
  end;

  TSchemaAttachment = class
  private
    FData: TMemoryStream;
    FBlob: TSchemaBlob;
  public
    property Data: TMemoryStream read FData write FData;
    property Blob: TSchemaBlob read FBlob write FBlob;
  end;

  // A const on the base type, which WriteNullable sees, as opposed to one on the
  // member, which is applied to the union afterwards
  [JsonSchema('const=fixed')]
  TSchemaTag = record
    Value: string;
  end;

  TSchemaVariantHolder = class
  private
    FName: string;
    FData: Variant;
    FMixed: TArray<Variant>;
    FTag: Nullable<TSchemaTag>;
  public
    property Name: string read FName write FName;

    // Serialized as whatever the variant happens to hold, so the schema has to
    // admit every JSON type the serializer can produce for it
    property Data: Variant read FData write FData;

    // Element schemas that came back nil used to be dropped silently by AddPair,
    // leaving an array with no "items" at all
    property Mixed: TArray<Variant> read FMixed write FMixed;

    property Tag: Nullable<TSchemaTag> read FTag write FTag;
  end;

  // Under IncludeIf.NotNull a null variant is dropped by the serializer, so the
  // schema must not admit null either
  TSchemaVariantNotNull = class
  private
    FData: Variant;
  public
    [NeonInclude(IncludeIf.NotNull)]
    property Data: Variant read FData write FData;
  end;

  TSchemaCoords = class
  private
    FLat: Double;
    FLng: Double;
  public
    [JsonSchema('required')]
    property Lat: Double read FLat write FLat;

    property Lng: Double read FLng write FLng;
  end;

  TSchemaPlace = class
  private
    FName: string;
    FCoords: TSchemaCoords;
  public
    property Name: string read FName write FName;

    // Serialized flat: Lat/Lng sit next to Name, with no "Coords" property
    [NeonUnwrapped]
    property Coords: TSchemaCoords read FCoords write FCoords;
  end;

  // [NeonUnwrapped] on an interface member: the serializer flattens whatever
  // object the implementing instance produced, so the schema must not nest a
  // "Service" property (a required one would reject the flat JSON Neon writes)
  ISchemaUnwrappedService = interface(IInvokable)
    ['{3A7B4C5D-6E7F-4A8B-9C0D-1E2F3A4B5C6D}']
  end;

  TSchemaUnwrappedService = class(TInterfacedObject, ISchemaUnwrappedService)
  private
    FEndpoint: string;
  public
    property Endpoint: string read FEndpoint write FEndpoint;
  end;

  TSchemaUnwrappedClient = class
  private
    FName: string;
    FService: ISchemaUnwrappedService;
  public
    property Name: string read FName write FName;

    [NeonUnwrapped]
    property Service: ISchemaUnwrappedService read FService write FService;
  end;

  // [NeonUnwrapped] on a map member: the serializer flattens the map's
  // key/value pairs into the parent, so the schema must widen the parent's
  // "additionalProperties" instead of nesting an "Attrs" property
  TSchemaUnwrappedBag = class
  private
    FTitle: string;
    FAttrs: TDictionary<string, Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    property Title: string read FTitle write FTitle;

    [NeonUnwrapped]
    property Attrs: TDictionary<string, Integer> read FAttrs write FAttrs;
  end;

  // [NeonUnwrapped] on a member whose type is hoisted into the definitions (it
  // closes a recursion cycle): the member schema is a bare $ref, so the parent
  // must satisfy the referenced schema via allOf
  TSchemaUnwrappedNode = class
  private
    FValue: string;
    FChild: TSchemaUnwrappedNode;
  public
    property Value: string read FValue write FValue;

    [NeonUnwrapped]
    property Child: TSchemaUnwrappedNode read FChild write FChild;
  end;

  // TTime serializes as a time-only ISO string, so its schema says format
  // "time" rather than the "date-time" a full TDateTime gets
  TSchemaSchedule = class
  private
    FStart: TTime;
    FWhen: TDateTime;
  public
    property Start: TTime read FStart write FStart;
    property When: TDateTime read FWhen write FWhen;
  end;

  // An array whose element type has no writer at all (a method pointer) must
  // keep its "items" keyword rather than silently dropping it
  TSchemaEventList = class
  private
    FName: string;
    FHandlers: TArray<TNotifyEvent>;
  public
    property Name: string read FName write FName;
    property Handlers: TArray<TNotifyEvent> read FHandlers write FHandlers;
  end;

  // Boolean-valued tags honour their value: a bare "readOnly" means True,
  // "readOnly=false" means False, and so on
  [JsonSchema('deprecated=false')]
  TSchemaBoolTags = class
  private
    FName: string;
    FCode: string;
    FTags: TArray<string>;
  public
    [JsonSchema('readOnly=false')]
    property Name: string read FName write FName;

    [JsonSchema('readOnly')]
    property Code: string read FCode write FCode;

    [JsonSchema('uniqueItems=false')]
    property Tags: TArray<string> read FTags write FTags;
  end;

  // Tag values on a schema with no "type" (a NeonRawValue or TJSONValue
  // member) are interpreted as JSON when they parse: const=123 is the number
  // 123, default=true a boolean, and a non-JSON value stays a string
  TSchemaRawConst = class
  private
    FText: string;
    FData: TJSONValue;
    FName: string;
  public
    [NeonRawValue]
    [JsonSchema('const=123')]
    property Text: string read FText write FText;

    [JsonSchema('default=true')]
    property Data: TJSONValue read FData write FData;

    [JsonSchema('const=hello')]
    property Name: string read FName write FName;
  end;

  // A record whose serialized shape is decided by a custom serializer; the
  // generator must use the serializer's SerializeSchema when one is registered
  TSchemaPoint = record
    X: Integer;
    Y: Integer;
  end;

  TSchemaPointSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
  end;

  // Same record, but a serializer WITHOUT the schema hook: the generator must
  // fall back to its structural inference (compatibility)
  TSchemaPointNoSchema = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TSchemaShapeHolder = class
  private
    FPoint: TSchemaPoint;
    FId: TGUID;
  public
    [JsonSchema('description=A point')]
    property Point: TSchemaPoint read FPoint write FPoint;
    property Id: TGUID read FId write FId;
  end;

  // Members whose shape only the bundled serializers know: TBytes (Base64
  // string), TCollection (array of items) and TValue (whatever it holds)
  TSchemaBytesHolder = class
  private
    FData: TBytes;
  public
    property Data: TBytes read FData write FData;
  end;

  TSchemaCollItem = class(TCollectionItem)
  end;

  TSchemaColl = class(TCollection)
  public
    constructor Create;
  end;

  TSchemaCollectionHolder = class
  private
    FItems: TSchemaColl;
  public
    constructor Create;
    destructor Destroy; override;
    property Items: TSchemaColl read FItems write FItems;
  end;

  TSchemaTValueHolder = class
  private
    FValue: TValue;
  public
    property Value: TValue read FValue write FValue;
  end;

  // A static array has a fixed length, which the schema states exactly via
  // minItems/maxItems
  TSchemaGridData = array[0..2] of Integer;

  TSchemaGrid = class
  private
    FData: TSchemaGridData;
  public
    property Data: TSchemaGridData read FData write FData;
  end;

  // A generic self-referencing type: the definition name ("TSchemaBox<...>")
  // must be percent-encoded in the $ref because "<"/">" are not valid in a
  // URI fragment, and the validator must decode it back
  TSchemaBox<T> = class
  private
    FValue: string;
    FNext: TSchemaBox<T>;
  public
    property Value: string read FValue write FValue;
    property Next: TSchemaBox<T> read FNext write FNext;
  end;

  // A TJSONValue descendant must be described like the class it derives from,
  // not dropped for failing an exact class match. TJSONString is one of the two
  // non-sealed ones, and it doubles as a check that the TJSONNumber/TJSONString
  // inheritance order is respected
  TSchemaJSONText = class(TJSONString)
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaEdgeCases = class(TObject)
  private
    FSchema: TJSONObject;
    function PaletteAccepts(const AInstanceJSON: string): Boolean;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRequiredObjectMemberKeepsItsOwnRequiredArray;

    [Test]
    procedure TestRequiredObjectMemberIsListedInParentRequired;

    [Test]
    procedure TestAttributeOnMemberWithoutSchemaIsIgnored;

    [Test]
    procedure TestInterfaceMemberIsDescribed;

    [Test]
    procedure TestSerializedInterfaceValidatesAgainstTheSchema;

    [Test]
    procedure TestSetIsArrayOfEnumNames;

    [Test]
    procedure TestEnumAsIntProducesIntegerSchema;

    [Test]
    procedure TestDataSetIsArrayOfRows;

    [Test]
    procedure TestJSONValueDescendantIsDescribed;

    [Test]
    procedure TestUnwrappedMemberIsFlattenedIntoParent;

    [Test]
    procedure TestUnwrappedMemberCarriesItsRequiredNames;

    [Test]
    procedure TestUnwrappedInterfaceIsNotNested;

    [Test]
    procedure TestUnwrappedInterfaceValidatesFlattenedJSON;

    [Test]
    procedure TestUnwrappedMapWidensAdditionalProperties;

    [Test]
    procedure TestUnwrappedMapValidatesFlattenedJSON;

    [Test]
    procedure TestUnwrappedRecursiveMemberIsAllOfRef;

    [Test]
    procedure TestUnwrappedRecursiveMemberValidatesFlattenedJSON;

    [Test]
    procedure TestTimeMemberUsesTimeFormat;

    [Test]
    procedure TestArrayOfMethodPointersKeepsItems;

    [Test]
    procedure TestBooleanTagsHonourTheirValue;

    [Test]
    procedure TestBareBooleanTagStillTrue;

    [Test]
    procedure TestTypelessTagValuesAreJSONParsed;

    [Test]
    procedure TestCustomSerializerContributesSchema;

    [Test]
    procedure TestCustomSerializerWithoutSchemaFallsBack;

    [Test]
    procedure TestGUIDMemberUsesSerializerSchema;

    [Test]
    procedure TestBytesMemberUsesSerializerSchema;

    [Test]
    procedure TestCollectionMemberUsesSerializerSchema;

    [Test]
    procedure TestValueMemberUsesSerializerSchema;

    [Test]
    [TestCase('null is allowed', '{"Tint":null}|True', '|')]
    [TestCase('a member of the enum is allowed', '{"Tint":"Green"}|True', '|')]
    [TestCase('anything else is not', '{"Tint":"Mauve"}|False', '|')]
    procedure TestNullableEnumAcceptsNull(const AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('null is allowed', '{"Code":null}|True', '|')]
    [TestCase('the const value is allowed', '{"Code":"abc"}|True', '|')]
    [TestCase('anything else is not', '{"Code":"xyz"}|False', '|')]
    procedure TestNullableConstAcceptsNull(const AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    procedure TestVariantMemberIsDescribed;

    [Test]
    procedure TestVariantNotNullOmitsNullFromUnion;

    [Test]
    procedure TestArrayOfVariantKeepsItsItems;

    [Test]
    procedure TestConstOnTheNullableBaseTypeAcceptsNull;

    [Test]
    procedure TestSerializedVariantsValidateAgainstTheSchema;

    [Test]
    procedure TestStreamUsesContentEncoding;

    [Test]
    procedure TestStreamableUsesContentEncoding;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaConstraints = class(TObject)
  private
    FSchema: TJSONObject;
    function Properties: TJSONObject;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDefaultVersionOmitsSchemaHeader;

    [Test]
    procedure TestV202012SchemaHeader;

    [Test]
    procedure TestDraft07SchemaHeader;

    [Test]
    procedure TestStringConstraints;

    [Test]
    procedure TestIntegerNumericConstraints;

    [Test]
    procedure TestFloatNumericConstraints;

    [Test]
    procedure TestArrayConstraints;

    [Test]
    procedure TestNullableTypeUnion;

    [Test]
    procedure TestObjectConstraintsAndMetadata;

    [Test]
    procedure TestDraft07OmitsDeprecated;

    [Test]
    procedure TestDraft07KeepsConst;

    [Test]
    procedure TestV202012KeepsDeprecated;

    [Test]
    procedure TestRecursiveTypeGoesIntoDefs;

    [Test]
    procedure TestRecursiveTypeReferencesItself;

    [Test]
    procedure TestRecursiveInstanceValidatesAgainstItsSchema;

    [Test]
    procedure TestDraft07UsesDefinitionsInsteadOfDefs;

    [Test]
    procedure TestNonRecursiveTypeHasNoDefs;

    [Test]
    procedure TestStaticArrayHasExactBounds;

    [Test]
    procedure TestClosedSchemaOption;

    [Test]
    procedure TestGenericDefNameIsPercentEncoded;

    [Test]
    procedure TestGenericDefRefResolvesAndValidates;

    [Test]
    procedure TestMutuallyRecursiveTypesValidate;

    [Test]
    procedure TestRecursionReachedFromAMemberHoistsDefsToTheRoot;
  end;

implementation

{ TSchemaTreeNode }

constructor TSchemaTreeNode.Create;
begin
  FChildren := TObjectList<TSchemaTreeNode>.Create;
end;

destructor TSchemaTreeNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

{ TTestJsonSchemaAttribute }

procedure TTestJsonSchemaAttribute.TestParseTagsExposesTags;
var
  LAttribute: JsonSchemaAttribute;
begin
  LAttribute := JsonSchemaAttribute.Create('description=Foo,required');
  try
    LAttribute.ParseTags;
    Assert.IsTrue(LAttribute.Tags.Exists('description'));
    Assert.AreEqual('Foo', LAttribute.Tags.GetValueAs<string>('description'));
    Assert.IsTrue(LAttribute.Tags.Exists('required'));
  finally
    LAttribute.Free;
  end;
end;

procedure TTestJsonSchemaAttribute.TestParseTagsIsIdempotent;
var
  LAttribute: JsonSchemaAttribute;
begin
  LAttribute := JsonSchemaAttribute.Create('description=Foo,required');
  try
    LAttribute.ParseTags;
    LAttribute.ParseTags;
    Assert.AreEqual(2, LAttribute.Tags.Count);
  finally
    LAttribute.Free;
  end;
end;

procedure TTestJsonSchemaAttribute.TestParseTagsOnEmptyStringIsIdempotent;
var
  LAttribute: JsonSchemaAttribute;
begin
  // An empty tag string parses to zero entries; without an explicit parsed
  // flag every call would re-parse it
  LAttribute := JsonSchemaAttribute.Create('');
  try
    LAttribute.ParseTags;
    LAttribute.ParseTags;
    Assert.AreEqual(0, LAttribute.Tags.Count);
  finally
    LAttribute.Free;
  end;
end;

{ TTestJsonSchemaGenerator }

function TTestJsonSchemaGenerator.Properties: TJSONObject;
begin
  Result := FSchema.GetValue('properties') as TJSONObject;
end;

procedure TTestJsonSchemaGenerator.Setup;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPerson);
end;

procedure TTestJsonSchemaGenerator.TearDown;
begin
  FSchema.Free;
end;

procedure TTestJsonSchemaGenerator.TestObjectType;
begin
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  Assert.IsNotNull(Properties);
end;

procedure TTestJsonSchemaGenerator.TestDescriptionIsApplied;
var
  LName: TJSONObject;
begin
  LName := Properties.GetValue('Name') as TJSONObject;
  Assert.IsNotNull(LName);
  Assert.AreEqual('The person''s full name', LName.GetValue('description').Value);
end;

procedure TTestJsonSchemaGenerator.TestDescriptionWithQuotedCommaIsApplied;
var
  LNickname: TJSONObject;
begin
  LNickname := Properties.GetValue('Nickname') as TJSONObject;
  Assert.IsNotNull(LNickname);
  Assert.AreEqual('A name, informally', LNickname.GetValue('description').Value);
end;

procedure TTestJsonSchemaGenerator.TestRequiredMemberIsMovedToTopLevelArray;
var
  LRequired: TJSONArray;
begin
  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(1, LRequired.Count);
  Assert.AreEqual('Name', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaGenerator.TestRequiredKeyIsRemovedFromMemberSchema;
var
  LName: TJSONObject;
begin
  LName := Properties.GetValue('Name') as TJSONObject;
  Assert.IsNull(LName.GetValue('required'));
end;

procedure TTestJsonSchemaGenerator.TestReadOnlyIsApplied;
var
  LAge: TJSONObject;
begin
  LAge := Properties.GetValue('Age') as TJSONObject;
  Assert.IsNotNull(LAge);
  Assert.IsTrue((LAge.GetValue('readOnly') as TJSONBool).AsBoolean);
end;

procedure TTestJsonSchemaGenerator.TestMemberWithoutAttributeHasNoExtraKeys;
var
  LEmail: TJSONObject;
begin
  LEmail := Properties.GetValue('Email') as TJSONObject;
  Assert.IsNotNull(LEmail);
  Assert.IsNull(LEmail.GetValue('description'));
  Assert.IsNull(LEmail.GetValue('required'));
  Assert.IsNull(LEmail.GetValue('readOnly'));
end;

{ TSchemaBlob }

procedure TSchemaBlob.LoadFromStream(AStream: TStream);
begin
  // Only its presence matters: the engine detects streamables by their methods
end;

procedure TSchemaBlob.SaveToStream(AStream: TStream);
begin
end;

{ TSchemaUnwrappedBag }

constructor TSchemaUnwrappedBag.Create;
begin
  inherited;
  FAttrs := TDictionary<string, Integer>.Create;
end;

destructor TSchemaUnwrappedBag.Destroy;
begin
  FAttrs.Free;
  inherited;
end;

{ TSchemaColl }

constructor TSchemaColl.Create;
begin
  inherited Create(TSchemaCollItem);
end;

{ TSchemaCollectionHolder }

constructor TSchemaCollectionHolder.Create;
begin
  inherited;
  FItems := TSchemaColl.Create;
end;

destructor TSchemaCollectionHolder.Destroy;
begin
  FItems.Free;
  inherited;
end;

{ TTestJsonSchemaEdgeCases }

procedure TTestJsonSchemaEdgeCases.TearDown;
begin
  FreeAndNil(FSchema);
end;

{ TSchemaPointSerializer }

class function TSchemaPointSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TSchemaPoint);
end;

class function TSchemaPointSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = GetTargetInfo;
end;

function TSchemaPointSerializer.Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
begin
  Result := TJSONObject.Create;
end;

function TSchemaPointSerializer.Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := AData;
end;

function TSchemaPointSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  // Deliberately a string with a marker title, so the test can tell the custom
  // schema apart from the structural record inference (an object of X/Y fields)
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('title', 'point');
end;

{ TSchemaPointNoSchema }

class function TSchemaPointNoSchema.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TSchemaPoint);
end;

class function TSchemaPointNoSchema.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = GetTargetInfo;
end;

function TSchemaPointNoSchema.Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
begin
  Result := TJSONObject.Create;
end;

function TSchemaPointNoSchema.Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := AData;
end;

procedure TTestJsonSchemaEdgeCases.TestRequiredObjectMemberKeepsItsOwnRequiredArray;
var
  LAddress: TJSONObject;
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaOrder);

  LAddress := (FSchema.GetValue('properties') as TJSONObject).GetValue('Address') as TJSONObject;
  Assert.IsNotNull(LAddress, 'the required object member must not be dropped');

  LRequired := LAddress.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired, 'the nested "required" must survive as an array');
  Assert.AreEqual(1, LRequired.Count);
  Assert.AreEqual('City', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaEdgeCases.TestRequiredObjectMemberIsListedInParentRequired;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaOrder);

  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(1, LRequired.Count);
  Assert.AreEqual('Address', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaEdgeCases.TestAttributeOnMemberWithoutSchemaIsIgnored;
var
  LProperties: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaWithEvent);
  LProperties := FSchema.GetValue('properties') as TJSONObject;

  Assert.IsNull(LProperties.GetValue('OnChange'), 'a member with no writer is skipped');
  Assert.IsNotNull(LProperties.GetValue('Name'), 'and its siblings are unaffected');
end;

procedure TTestJsonSchemaEdgeCases.TestInterfaceMemberIsDescribed;
var
  LService: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaClient);

  LService := (FSchema.GetValue('properties') as TJSONObject).GetValue('Service') as TJSONObject;
  Assert.IsNotNull(LService, 'an interface member is serialized, so it must be in the schema');
  Assert.AreEqual('object', LService.GetValue('type').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestSerializedInterfaceValidatesAgainstTheSchema;
var
  LClient: TSchemaClient;
  LJSON: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaClient);

  LClient := TSchemaClient.Create;
  try
    LClient.Name := 'probe';
    LClient.Service := TSchemaService.Create;

    LJSON := TNeon.ObjectToJSON(LClient);
    try
      // The implementing object carries members the interface never declared,
      // which an unconstrained object schema still accepts
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid,
        'the schema rejects what the serializer wrote: ' + LJSON.ToJSON);
    finally
      LJSON.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestSetIsArrayOfEnumNames;
var
  LColors, LItems: TJSONObject;
  LEnum: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPalette);

  LColors := (FSchema.GetValue('properties') as TJSONObject).GetValue('Colors') as TJSONObject;
  Assert.IsNotNull(LColors);
  // The serializer writes a set as an array of its members, not as a string
  Assert.AreEqual('array', LColors.GetValue('type').Value);

  LItems := LColors.GetValue('items') as TJSONObject;
  Assert.IsNotNull(LItems);
  Assert.AreEqual('string', LItems.GetValue('type').Value);

  LEnum := LItems.GetValue('enum') as TJSONArray;
  Assert.IsNotNull(LEnum);
  Assert.AreEqual(3, LEnum.Count);
  Assert.AreEqual('Red', LEnum.Items[0].Value);

  // A set is an array of distinct members by construction
  Assert.IsTrue((LColors.GetValue('uniqueItems') as TJSONBool).AsBoolean,
    'a set serializes to a unique array');
end;

procedure TTestJsonSchemaEdgeCases.TestEnumAsIntProducesIntegerSchema;
var
  LMain: TJSONObject;
  LEnum: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPalette,
    TNeonConfiguration.Default.SetEnumAsInt(True));

  LMain := (FSchema.GetValue('properties') as TJSONObject).GetValue('Main') as TJSONObject;
  Assert.IsNotNull(LMain);
  Assert.AreEqual('integer', LMain.GetValue('type').Value);

  LEnum := LMain.GetValue('enum') as TJSONArray;
  Assert.IsNotNull(LEnum);
  Assert.AreEqual(3, LEnum.Count);
  Assert.AreEqual(2, (LEnum.Items[2] as TJSONNumber).AsInt);
end;

procedure TTestJsonSchemaEdgeCases.TestDataSetIsArrayOfRows;
var
  LItems: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TDataSet);

  // A dataset serializes to an array of row objects, not to a single object
  Assert.AreEqual('array', FSchema.GetValue('type').Value);

  LItems := FSchema.GetValue('items') as TJSONObject;
  Assert.IsNotNull(LItems);
  Assert.AreEqual('object', LItems.GetValue('type').Value);
end;

function TTestJsonSchemaEdgeCases.PaletteAccepts(const AInstanceJSON: string): Boolean;
var
  LInstance: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPalette);

  LInstance := TJSONObject.ParseJSONValue(AInstanceJSON);
  try
    // Validated with Neon's own validator: the point is that the generated
    // schema must accept what the serializer can actually produce
    Result := TNeon.ValidateJSON(LInstance, FSchema).IsValid;
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestNullableEnumAcceptsNull(const AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, PaletteAccepts(AInstanceJSON));
end;

procedure TTestJsonSchemaEdgeCases.TestNullableConstAcceptsNull(const AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, PaletteAccepts(AInstanceJSON));
end;

procedure TTestJsonSchemaEdgeCases.TestVariantMemberIsDescribed;
var
  LData: TJSONObject;
  LTypes: TJSONArray;
  LNames: string;
  LItem: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaVariantHolder);

  LData := (FSchema.GetValue('properties') as TJSONObject).GetValue('Data') as TJSONObject;
  Assert.IsNotNull(LData, 'a Variant member is serialized, so it must be in the schema');

  LTypes := LData.GetValue('type') as TJSONArray;
  Assert.IsNotNull(LTypes);

  for LItem in LTypes do
    LNames := LNames + LItem.Value + ' ';

  // The default include policy is IncludeIf.NotNull, under which the serializer
  // drops a null variant instead of writing it, so "null" must not be admitted
  Assert.AreEqual('string number boolean ', LNames);
end;

procedure TTestJsonSchemaEdgeCases.TestVariantNotNullOmitsNullFromUnion;
var
  LData: TJSONObject;
  LTypes: TJSONArray;
  LNames: string;
  LItem: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaVariantNotNull);

  LData := (FSchema.GetValue('properties') as TJSONObject).GetValue('Data') as TJSONObject;
  LTypes := LData.GetValue('type') as TJSONArray;
  LNames := '';
  for LItem in LTypes do
    LNames := LNames + LItem.Value + ' ';

  Assert.AreEqual('string number boolean ', LNames,
    'with IncludeIf.NotNull a null variant is dropped, so "null" must not be admitted');
end;

procedure TTestJsonSchemaEdgeCases.TestArrayOfVariantKeepsItsItems;
var
  LMixed, LItems: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaVariantHolder);

  LMixed := (FSchema.GetValue('properties') as TJSONObject).GetValue('Mixed') as TJSONObject;
  Assert.AreEqual('array', LMixed.GetValue('type').Value);

  LItems := LMixed.GetValue('items') as TJSONObject;
  Assert.IsNotNull(LItems, 'an element schema must not go missing');
  Assert.IsNotNull(LItems.GetValue('type'));
end;

procedure TTestJsonSchemaEdgeCases.TestConstOnTheNullableBaseTypeAcceptsNull;
var
  LTag: TJSONObject;
  LEnum: TJSONArray;
  LInstance: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaVariantHolder);

  // The const came from the base type, not the member, so WriteNullable is what
  // has to turn it into an enum that admits null
  LTag := (FSchema.GetValue('properties') as TJSONObject).GetValue('Tag') as TJSONObject;
  Assert.IsNull(LTag.GetValue('const'), 'a bare const would contradict the null in the union');

  LEnum := LTag.GetValue('enum') as TJSONArray;
  Assert.IsNotNull(LEnum);
  Assert.AreEqual(2, LEnum.Count);
  Assert.AreEqual('fixed', LEnum.Items[0].Value);

  LInstance := TJSONObject.ParseJSONValue('{"Tag":null}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid);
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestSerializedVariantsValidateAgainstTheSchema;
var
  LHolder: TSchemaVariantHolder;

  procedure CheckAccepts(const AValue: Variant; const AWhat: string);
  var
    LJSON: TJSONValue;
  begin
    LHolder.Data := AValue;
    LJSON := TNeon.ObjectToJSON(LHolder);
    try
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid,
        Format('a Variant holding %s serializes to %s, which the schema rejects',
          [AWhat, LJSON.ToJSON]));
    finally
      LJSON.Free;
    end;
  end;

begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaVariantHolder);

  LHolder := TSchemaVariantHolder.Create;
  try
    LHolder.Name := 'probe';

    CheckAccepts(42, 'an integer');
    CheckAccepts(3.5, 'a float');
    CheckAccepts('text', 'a string');
    CheckAccepts(True, 'a boolean');
  finally
    LHolder.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestStreamUsesContentEncoding;
var
  LData: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaAttachment);
  LData := (FSchema.GetValue('properties') as TJSONObject).GetValue('Data') as TJSONObject;

  Assert.IsNotNull(LData);
  Assert.AreEqual('string', LData.GetValue('type').Value);
  Assert.IsNotNull(LData.GetValue('contentEncoding'), 'contentEncoding is missing');
  Assert.AreEqual('base64', LData.GetValue('contentEncoding').Value);
  Assert.IsNull(LData.GetValue('format'), 'the OpenAPI "byte" format must be gone');
end;

procedure TTestJsonSchemaEdgeCases.TestStreamableUsesContentEncoding;
var
  LBlob: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaAttachment);
  LBlob := (FSchema.GetValue('properties') as TJSONObject).GetValue('Blob') as TJSONObject;

  Assert.IsNotNull(LBlob);
  Assert.AreEqual('string', LBlob.GetValue('type').Value);
  Assert.IsNotNull(LBlob.GetValue('contentEncoding'), 'contentEncoding is missing');
  Assert.AreEqual('base64', LBlob.GetValue('contentEncoding').Value);
  Assert.IsNull(LBlob.GetValue('format'), 'the OpenAPI "byte" format must be gone');
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedMemberIsFlattenedIntoParent;
var
  LProperties: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPlace);
  LProperties := FSchema.GetValue('properties') as TJSONObject;

  Assert.IsNull(LProperties.GetValue('Coords'), 'the unwrapped member must not appear as a property');

  Assert.IsNotNull(LProperties.GetValue('Name'));
  Assert.IsNotNull(LProperties.GetValue('Lat'), 'the unwrapped member''s own members are hoisted');
  Assert.IsNotNull(LProperties.GetValue('Lng'));
  Assert.AreEqual('number', (LProperties.GetValue('Lat') as TJSONObject).GetValue('type').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedMemberCarriesItsRequiredNames;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPlace);

  // Lat is required inside TSchemaCoords, so once flattened it is required here
  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(1, LRequired.Count);
  Assert.AreEqual('Lat', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedInterfaceIsNotNested;
var
  LProperties: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedClient);
  LProperties := FSchema.GetValue('properties') as TJSONObject;

  // The serializer flattens the implementing object's members, so the schema
  // must not expect a "Service" property (a required one would reject the JSON
  // the serializer actually produces)
  Assert.IsNull(LProperties.GetValue('Service'));
  Assert.IsNotNull(LProperties.GetValue('Name'));
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedInterfaceValidatesFlattenedJSON;
var
  LClient: TSchemaUnwrappedClient;
  LService: TSchemaUnwrappedService;
  LJSON: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedClient);

  LClient := TSchemaUnwrappedClient.Create;
  try
    LService := TSchemaUnwrappedService.Create;
    LService.Endpoint := 'https://example.test/api';
    LClient.Service := LService; // the interface reference owns the instance

    LJSON := TNeon.ObjectToJSON(LClient);
    try
      Assert.IsNotNull(LJSON.GetValue<TJSONValue>('Endpoint'),
        'the interface''s members must be flattened into the parent object');
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid,
        'the schema rejects what the serializer wrote: ' + LJSON.ToJSON);
    finally
      LJSON.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedMapWidensAdditionalProperties;
var
  LAdditional: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedBag);

  // The map's key/value pairs are flattened into the parent, so there must be
  // no "Attrs" property and the parent must admit the map's value schema for
  // properties beyond its own
  Assert.IsNull((FSchema.GetValue('properties') as TJSONObject).GetValue('Attrs'));

  LAdditional := FSchema.GetValue('additionalProperties') as TJSONObject;
  Assert.IsNotNull(LAdditional,
    'the parent must widen additionalProperties to the map''s value schema');
  Assert.AreEqual('integer', LAdditional.GetValue('type').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedMapValidatesFlattenedJSON;
var
  LBag: TSchemaUnwrappedBag;
  LJSON: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedBag);

  LBag := TSchemaUnwrappedBag.Create;
  try
    LBag.Title := 'probe';
    LBag.Attrs.Add('k', 1);

    LJSON := TNeon.ObjectToJSON(LBag);
    try
      Assert.IsNotNull(LJSON.GetValue<TJSONValue>('k'),
        'the map pairs must be flattened into the parent');
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid,
        'the schema rejects what the serializer wrote: ' + LJSON.ToJSON);
    finally
      LJSON.Free;
    end;
  finally
    LBag.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedRecursiveMemberIsAllOfRef;
var
  LDefs, LNode, LAllOf: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedNode);

  // The type closes a recursion cycle through the unwrapped member, so it is
  // hoisted to the definitions and the parent must satisfy it via allOf
  Assert.AreEqual('#/$defs/TSchemaUnwrappedNode', FSchema.GetValue('$ref').Value);

  LDefs := FSchema.GetValue('$defs') as TJSONObject;
  LNode := LDefs.GetValue('TSchemaUnwrappedNode') as TJSONObject;

  Assert.IsNull((LNode.GetValue('properties') as TJSONObject).GetValue('Child'),
    'the unwrapped recursive member must not appear as a property');

  LAllOf := (LNode.GetValue('allOf') as TJSONArray).Items[0] as TJSONObject;
  Assert.IsNotNull(LAllOf);
  Assert.AreEqual('#/$defs/TSchemaUnwrappedNode', LAllOf.GetValue('$ref').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestUnwrappedRecursiveMemberValidatesFlattenedJSON;
var
  LNode: TSchemaUnwrappedNode;
  LJSON: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaUnwrappedNode);

  LNode := TSchemaUnwrappedNode.Create;
  LNode.Value := 'a';
  LNode.Child := TSchemaUnwrappedNode.Create;
  LNode.Child.Value := 'b';
  try
    LJSON := TNeon.ObjectToJSON(LNode);
    try
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid,
        'the schema rejects what the serializer wrote: ' + LJSON.ToJSON);
    finally
      LJSON.Free;
    end;
  finally
    LNode.Child.Free;
    LNode.Free;
  end;
end;

procedure TTestJsonSchemaEdgeCases.TestTimeMemberUsesTimeFormat;
var
  LStart, LWhen: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaSchedule);

  LStart := (FSchema.GetValue('properties') as TJSONObject).GetValue('Start') as TJSONObject;
  Assert.AreEqual('string', LStart.GetValue('type').Value);
  Assert.AreEqual('time', LStart.GetValue('format').Value,
    'a TTime serializes as a time-only string, not date-time');

  LWhen := (FSchema.GetValue('properties') as TJSONObject).GetValue('When') as TJSONObject;
  Assert.AreEqual('date-time', LWhen.GetValue('format').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestArrayOfMethodPointersKeepsItems;
var
  LHandlers, LItems: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaEventList);

  LHandlers := (FSchema.GetValue('properties') as TJSONObject).GetValue('Handlers') as TJSONObject;
  Assert.AreEqual('array', LHandlers.GetValue('type').Value);

  LItems := LHandlers.GetValue('items') as TJSONObject;
  Assert.IsNotNull(LItems, 'a nil element schema must not silently drop "items"');
end;

procedure TTestJsonSchemaEdgeCases.TestBooleanTagsHonourTheirValue;
var
  LName, LTags: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaBoolTags, TNeonJSchemaVersion.v202012);

  LName := (FSchema.GetValue('properties') as TJSONObject).GetValue('Name') as TJSONObject;
  Assert.IsNotNull(LName.GetValue('readOnly'));
  Assert.IsFalse((LName.GetValue('readOnly') as TJSONBool).AsBoolean,
    'readOnly=false must not emit true');

  LTags := (FSchema.GetValue('properties') as TJSONObject).GetValue('Tags') as TJSONObject;
  Assert.IsNotNull(LTags.GetValue('uniqueItems'));
  Assert.IsFalse((LTags.GetValue('uniqueItems') as TJSONBool).AsBoolean,
    'uniqueItems=false must not emit true');

  Assert.IsFalse((FSchema.GetValue('deprecated') as TJSONBool).AsBoolean,
    'deprecated=false must not emit true');
end;

procedure TTestJsonSchemaEdgeCases.TestBareBooleanTagStillTrue;
var
  LCode: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaBoolTags);

  LCode := (FSchema.GetValue('properties') as TJSONObject).GetValue('Code') as TJSONObject;
  Assert.IsTrue((LCode.GetValue('readOnly') as TJSONBool).AsBoolean,
    'a bare readOnly flag must stay true');
end;

procedure TTestJsonSchemaEdgeCases.TestTypelessTagValuesAreJSONParsed;
var
  LProps: TJSONObject;
  LText, LData, LName: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaRawConst);
  LProps := FSchema.GetValue('properties') as TJSONObject;

  // No "type" in the schema (a NeonRawValue or TJSONValue member): the tag
  // value is interpreted as JSON when it parses
  LText := LProps.GetValue('Text') as TJSONObject;
  Assert.IsTrue(LText.GetValue('const') is TJSONNumber,
    'const=123 must become the number 123, not the string "123"');
  Assert.AreEqual(123, (LText.GetValue('const') as TJSONNumber).AsInt);

  LData := LProps.GetValue('Data') as TJSONObject;
  Assert.IsTrue(LData.GetValue('default') is TJSONBool,
    'default=true must become a boolean');

  LName := LProps.GetValue('Name') as TJSONObject;
  Assert.IsTrue(LName.GetValue('const') is TJSONString,
    'a non-JSON tag value stays a string');
  Assert.AreEqual('hello', LName.GetValue('const').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestCustomSerializerContributesSchema;
var
  LPoint: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaShapeHolder,
    TNeonConfiguration.Default.RegisterSerializer(TSchemaPointSerializer));

  LPoint := (FSchema.GetValue('properties') as TJSONObject).GetValue('Point') as TJSONObject;
  Assert.AreEqual('string', LPoint.GetValue('type').Value,
    'a registered serializer with SerializeSchema wins over the structural inference');
  Assert.AreEqual('point', LPoint.GetValue('title').Value);
  Assert.AreEqual('A point', LPoint.GetValue('description').Value,
    'member JsonSchema tags still apply to the custom schema');
end;

procedure TTestJsonSchemaEdgeCases.TestCustomSerializerWithoutSchemaFallsBack;
var
  LPoint: TJSONObject;
begin
  // A registered serializer that does not override SerializeSchema must not
  // change anything: the structural inference applies
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaShapeHolder,
    TNeonConfiguration.Default.RegisterSerializer(TSchemaPointNoSchema));

  LPoint := (FSchema.GetValue('properties') as TJSONObject).GetValue('Point') as TJSONObject;
  Assert.AreEqual('object', LPoint.GetValue('type').Value,
    'a serializer without a schema falls back to structural inference');
end;

procedure TTestJsonSchemaEdgeCases.TestGUIDMemberUsesSerializerSchema;
var
  LId: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaShapeHolder,
    TNeonConfiguration.Default.RegisterSerializer(TGUIDSerializer));

  LId := (FSchema.GetValue('properties') as TJSONObject).GetValue('Id') as TJSONObject;
  Assert.AreEqual('string', LId.GetValue('type').Value,
    'a GUID serializes as a string, so its schema must not be an object of fields');
  Assert.AreEqual('uuid', LId.GetValue('format').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestBytesMemberUsesSerializerSchema;
var
  LData: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaBytesHolder,
    TNeonConfiguration.Default.RegisterSerializer(TBytesSerializer));

  LData := (FSchema.GetValue('properties') as TJSONObject).GetValue('Data') as TJSONObject;
  Assert.AreEqual('string', LData.GetValue('type').Value,
    'TBytes serializes as a Base64 string, not as an array of integers');
  Assert.AreEqual('base64', LData.GetValue('contentEncoding').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestCollectionMemberUsesSerializerSchema;
var
  LItems: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaCollectionHolder,
    TNeonConfiguration.Default.RegisterSerializer(TCollectionSerializer));

  LItems := (FSchema.GetValue('properties') as TJSONObject).GetValue('Items') as TJSONObject;
  Assert.AreEqual('array', LItems.GetValue('type').Value,
    'a TCollection serializes as an array of items, not as an object');
  Assert.AreEqual('object',
    (LItems.GetValue('items') as TJSONObject).GetValue('type').Value);
end;

procedure TTestJsonSchemaEdgeCases.TestValueMemberUsesSerializerSchema;
var
  LValue: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTValueHolder,
    TNeonConfiguration.Default.RegisterSerializer(TTValueSerializer));

  LValue := (FSchema.GetValue('properties') as TJSONObject).GetValue('Value') as TJSONObject;
  Assert.IsNull(LValue.GetValue('type'),
    'a TValue can hold anything, so its schema must be unconstrained');
end;

procedure TTestJsonSchemaEdgeCases.TestJSONValueDescendantIsDescribed;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaJSONText);

  Assert.IsNotNull(FSchema, 'a TJSONString descendant must not be dropped');
  Assert.AreEqual('string', FSchema.GetValue('type').Value);
end;

{ TTestJsonSchemaConstraints }

function TTestJsonSchemaConstraints.Properties: TJSONObject;
begin
  Result := FSchema.GetValue('properties') as TJSONObject;
end;

procedure TTestJsonSchemaConstraints.TearDown;
begin
  FSchema.Free;
  FSchema := nil;
end;

procedure TTestJsonSchemaConstraints.TestDefaultVersionOmitsSchemaHeader;
begin
  // Default (None) is backward-compatible with pre-existing callers and lets the
  // result be embedded as a schema fragment (e.g. under $defs) without its own $schema
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  Assert.IsNull(FSchema.GetValue('$schema'));
end;

procedure TTestJsonSchemaConstraints.TestV202012SchemaHeader;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson, TNeonJSchemaVersion.v202012);
  Assert.AreEqual('https://json-schema.org/draft/2020-12/schema', FSchema.GetValue('$schema').Value);
end;

procedure TTestJsonSchemaConstraints.TestDraft07SchemaHeader;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson, TNeonJSchemaVersion.Draft07);
  Assert.AreEqual('http://json-schema.org/draft-07/schema#', FSchema.GetValue('$schema').Value);
end;

procedure TTestJsonSchemaConstraints.TestStringConstraints;
var
  LName: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  LName := Properties.GetValue('Name') as TJSONObject;
  Assert.AreEqual(2, (LName.GetValue('minLength') as TJSONNumber).AsInt);
  Assert.AreEqual(50, (LName.GetValue('maxLength') as TJSONNumber).AsInt);
  Assert.AreEqual('^[A-Z].*$', LName.GetValue('pattern').Value);
end;

procedure TTestJsonSchemaConstraints.TestIntegerNumericConstraints;
var
  LAge: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  LAge := Properties.GetValue('Age') as TJSONObject;
  Assert.AreEqual(Double(0), (LAge.GetValue('minimum') as TJSONNumber).AsDouble, 0.0001);
  Assert.AreEqual(Double(120), (LAge.GetValue('maximum') as TJSONNumber).AsDouble, 0.0001);
  Assert.AreEqual(Double(1), (LAge.GetValue('multipleOf') as TJSONNumber).AsDouble, 0.0001);
end;

procedure TTestJsonSchemaConstraints.TestFloatNumericConstraints;
var
  LScore: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  LScore := Properties.GetValue('Score') as TJSONObject;
  Assert.AreEqual(Double(0), (LScore.GetValue('exclusiveMinimum') as TJSONNumber).AsDouble, 0.0001);
  Assert.AreEqual(Double(100), (LScore.GetValue('exclusiveMaximum') as TJSONNumber).AsDouble, 0.0001);
end;

procedure TTestJsonSchemaConstraints.TestArrayConstraints;
var
  LTags: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  LTags := Properties.GetValue('Tags') as TJSONObject;
  Assert.AreEqual(1, (LTags.GetValue('minItems') as TJSONNumber).AsInt);
  Assert.AreEqual(5, (LTags.GetValue('maxItems') as TJSONNumber).AsInt);
  Assert.IsTrue((LTags.GetValue('uniqueItems') as TJSONBool).AsBoolean);
end;

procedure TTestJsonSchemaConstraints.TestNullableTypeUnion;
var
  LNickname: TJSONObject;
  LType: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);
  LNickname := Properties.GetValue('Nickname') as TJSONObject;
  LType := LNickname.GetValue('type') as TJSONArray;
  Assert.IsNotNull(LType);
  Assert.AreEqual(2, LType.Count);
  Assert.AreEqual('string', LType.Items[0].Value);
  Assert.AreEqual('null', LType.Items[1].Value);
end;

procedure TTestJsonSchemaConstraints.TestObjectConstraintsAndMetadata;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaMetaPerson);
  Assert.AreEqual(1, (FSchema.GetValue('minProperties') as TJSONNumber).AsInt);
  Assert.AreEqual(10, (FSchema.GetValue('maxProperties') as TJSONNumber).AsInt);
  Assert.AreEqual('A person', FSchema.GetValue('title').Value);
  Assert.IsTrue((FSchema.GetValue('deprecated') as TJSONBool).AsBoolean);
  Assert.AreEqual('hello', FSchema.GetValue('default').Value);
end;

procedure TTestJsonSchemaConstraints.TestDraft07OmitsDeprecated;
begin
  // "deprecated" arrived in 2019-09 and has no meaning in a Draft-07 document
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaMetaPerson,
    TNeonJSchemaVersion.Draft07);

  Assert.IsNull(FSchema.GetValue('deprecated'));

  // the rest of the metadata is Draft-07 vocabulary and must survive
  Assert.AreEqual('A person', FSchema.GetValue('title').Value);
  Assert.AreEqual('hello', FSchema.GetValue('default').Value);
  Assert.AreEqual(1, (FSchema.GetValue('minProperties') as TJSONNumber).AsInt);
end;

procedure TTestJsonSchemaConstraints.TestDraft07KeepsConst;
var
  LKind: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaMetaPerson,
    TNeonJSchemaVersion.Draft07);

  // "const" is Draft-06 vocabulary, so Draft-07 has it
  LKind := Properties.GetValue('Kind') as TJSONObject;
  Assert.IsNotNull(LKind);
  Assert.AreEqual('person', LKind.GetValue('const').Value);
end;

procedure TTestJsonSchemaConstraints.TestV202012KeepsDeprecated;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaMetaPerson,
    TNeonJSchemaVersion.v202012);

  Assert.IsNotNull(FSchema.GetValue('deprecated'));
  Assert.IsTrue((FSchema.GetValue('deprecated') as TJSONBool).AsBoolean);
end;

procedure TTestJsonSchemaConstraints.TestRecursiveTypeGoesIntoDefs;
var
  LDefs, LNode: TJSONObject;
begin
  // A self-referencing type can only be described through a reference, so the
  // schema for it is hoisted into $defs and the root points at it
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTreeNode);

  Assert.AreEqual('#/$defs/TSchemaTreeNode', FSchema.GetValue('$ref').Value);

  LDefs := FSchema.GetValue('$defs') as TJSONObject;
  Assert.IsNotNull(LDefs);

  LNode := LDefs.GetValue('TSchemaTreeNode') as TJSONObject;
  Assert.IsNotNull(LNode);
  Assert.AreEqual('object', LNode.GetValue('type').Value);
end;

procedure TTestJsonSchemaConstraints.TestRecursiveTypeReferencesItself;
var
  LNode, LChildren: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTreeNode);

  LNode := (FSchema.GetValue('$defs') as TJSONObject).GetValue('TSchemaTreeNode') as TJSONObject;
  LChildren := (LNode.GetValue('properties') as TJSONObject).GetValue('Children') as TJSONObject;

  Assert.AreEqual('array', LChildren.GetValue('type').Value);
  Assert.AreEqual('#/$defs/TSchemaTreeNode',
    (LChildren.GetValue('items') as TJSONObject).GetValue('$ref').Value);
end;

procedure TTestJsonSchemaConstraints.TestRecursiveInstanceValidatesAgainstItsSchema;
var
  LInstance: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTreeNode);

  // Nested three deep: the $ref has to resolve and keep resolving
  LInstance := TJSONObject.ParseJSONValue(
    '{"Children":[{"Children":[{"Children":[]}]}]}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid);
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaConstraints.TestDraft07UsesDefinitionsInsteadOfDefs;
begin
  // Draft-07 spells the container "definitions"; $defs arrived in 2019-09
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTreeNode,
    TNeonJSchemaVersion.Draft07);

  Assert.IsNotNull(FSchema.GetValue('definitions'));
  Assert.IsNull(FSchema.GetValue('$defs'));

  // Draft-07 "$ref" replaces its sibling keywords, so the reference is wrapped
  // in "allOf" to keep the definitions visible to a strict validator
  Assert.IsNull(FSchema.GetValue('$ref'), 'the root must not carry a bare $ref');
  Assert.AreEqual('#/definitions/TSchemaTreeNode',
    ((FSchema.GetValue('allOf') as TJSONArray).Items[0] as TJSONObject).GetValue('$ref').Value);
end;

procedure TTestJsonSchemaConstraints.TestMutuallyRecursiveTypesValidate;
var
  LInstance: TJSONValue;
begin
  // TSchemaAuthor -> TSchemaBook -> TSchemaAuthor. Only the type the cycle closes
  // back onto needs hoisting; the other stays inline inside it
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaAuthor);

  Assert.AreEqual('#/$defs/TSchemaAuthor', FSchema.GetValue('$ref').Value);
  Assert.IsNotNull((FSchema.GetValue('$defs') as TJSONObject).GetValue('TSchemaAuthor'));
  Assert.IsNull((FSchema.GetValue('$defs') as TJSONObject).GetValue('TSchemaBook'));

  LInstance := TJSONObject.ParseJSONValue(
    '{"Name":"a","Books":[{"Title":"t","Author":{"Name":"b","Books":[]}}]}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid);
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaConstraints.TestRecursionReachedFromAMemberHoistsDefsToTheRoot;
var
  LInstance: TJSONValue;
begin
  // The reference is made two levels down, but the definitions belong at the root
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaLibrary);

  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  Assert.IsNotNull((FSchema.GetValue('$defs') as TJSONObject).GetValue('TSchemaAuthor'));
  Assert.AreEqual('#/$defs/TSchemaAuthor',
    ((FSchema.GetValue('properties') as TJSONObject).GetValue('Top') as TJSONObject).GetValue('$ref').Value);

  LInstance := TJSONObject.ParseJSONValue(
    '{"Owner":"o","Top":{"Name":"a","Books":[{"Title":"t","Author":{"Name":"b","Books":[]}}]}}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid);
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaConstraints.TestNonRecursiveTypeHasNoDefs;
begin
  // Only a type that actually needs referencing is hoisted; everything else is
  // still written inline exactly as before
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaConstraintPerson);

  Assert.IsNull(FSchema.GetValue('$defs'));
  Assert.IsNull(FSchema.GetValue('$ref'));
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
end;

procedure TTestJsonSchemaConstraints.TestStaticArrayHasExactBounds;
var
  LData: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaGrid);

  LData := (FSchema.GetValue('properties') as TJSONObject).GetValue('Data') as TJSONObject;
  Assert.AreEqual(3, (LData.GetValue('minItems') as TJSONNumber).AsInt);
  Assert.AreEqual(3, (LData.GetValue('maxItems') as TJSONNumber).AsInt);
end;

procedure TTestJsonSchemaConstraints.TestClosedSchemaOption;
begin
  // Default: open, matching the deserializer which ignores unknown properties
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaGrid);
  Assert.IsNull(FSchema.GetValue('additionalProperties'));

  FSchema.Free;
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaGrid,
    TNeonConfiguration.Default.SetClosedSchema(True));
  Assert.IsFalse((FSchema.GetValue('additionalProperties') as TJSONBool).AsBoolean,
    'SetClosedSchema(True) must emit additionalProperties: false');
end;

procedure TTestJsonSchemaConstraints.TestGenericDefNameIsPercentEncoded;
var
  LRef: string;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaBox<string>);

  LRef := FSchema.GetValue('$ref').Value;
  Assert.IsTrue(Pos('<', LRef) = 0, 'generic def names must be percent-encoded in the ref');
  Assert.IsTrue(Pos('%3C', LRef) > 0, 'the "<" must appear as %3C');
end;

procedure TTestJsonSchemaConstraints.TestGenericDefRefResolvesAndValidates;
var
  LInstance: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaBox<string>);

  LInstance := TJSONObject.ParseJSONValue('{"Value":"a","Next":{"Value":"b"}}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid,
      'the validator must decode the percent-encoded $ref and accept the recursive instance');
  finally
    LInstance.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJsonSchemaAttribute);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaGenerator);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaEdgeCases);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaConstraints);

end.
