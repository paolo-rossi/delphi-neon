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
  System.SysUtils, System.TypInfo, System.JSON, System.Generics.Collections,
  Data.DB,
  DUnitX.TestFramework,
  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Utils,
  Neon.Core.Persistence,
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
  public
    property Name: string read FName write FName;
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

  // Interfaces have no writer, so no schema is produced at all and the
  // attribute must simply be ignored rather than dereferenced
  // IInvokable, so that the interface carries type info (and its attribute)
  [JsonSchema('description=Some service')]
  ISchemaService = interface(IInvokable)
    ['{0B0D6E5A-2C2E-4E9E-9C1C-6A0B2D9E1F31}']
  end;

  TSchemaColor = (Red, Green, Blue);
  TSchemaColors = set of TSchemaColor;

  TSchemaPalette = class
  private
    FMain: TSchemaColor;
    FColors: TSchemaColors;
  public
    property Main: TSchemaColor read FMain write FMain;
    property Colors: TSchemaColors read FColors write FColors;
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
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRequiredObjectMemberKeepsItsOwnRequiredArray;

    [Test]
    procedure TestRequiredObjectMemberIsListedInParentRequired;

    [Test]
    procedure TestAttributeOnTypeWithoutSchemaIsIgnored;

    [Test]
    procedure TestSetIsArrayOfEnumNames;

    [Test]
    procedure TestEnumAsIntProducesIntegerSchema;

    [Test]
    procedure TestDataSetIsArrayOfRows;

    [Test]
    procedure TestJSONValueDescendantIsDescribed;
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

procedure TTestJsonSchemaEdgeCases.TestAttributeOnTypeWithoutSchemaIsIgnored;
begin
  // Must return nil rather than raising: there is no schema object to annotate
  FSchema := TNeonSchemaGenerator.TypeToJSONSchema(
    TRttiUtils.Context.GetType(TypeInfo(ISchemaService)));
  Assert.IsNull(FSchema);
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
