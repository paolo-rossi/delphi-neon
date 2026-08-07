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
  System.SysUtils, System.Classes, System.TypInfo, System.JSON, System.Generics.Collections,
  Data.DB,
  DUnitX.TestFramework,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Nullables,
  Neon.Core.Utils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema;

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

  TSchemaVariantHolder = class
  private
    FName: string;
    FData: Variant;
  public
    property Name: string read FName write FName;

    // Serialized as whatever the variant happens to hold, so the schema has to
    // admit every JSON type the serializer can produce for it
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
    procedure TestRecursionGuardRaises;
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

{ TTestJsonSchemaEdgeCases }

procedure TTestJsonSchemaEdgeCases.TearDown;
begin
  FreeAndNil(FSchema);
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

  Assert.AreEqual('string number boolean null ', LNames);
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

procedure TTestJsonSchemaConstraints.TestRecursionGuardRaises;
begin
  Assert.WillRaise(
    procedure begin TNeonSchemaGenerator.ClassToJSONSchema(TSchemaTreeNode) end,
    ENeonException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJsonSchemaAttribute);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaGenerator);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaEdgeCases);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaConstraints);

end.
