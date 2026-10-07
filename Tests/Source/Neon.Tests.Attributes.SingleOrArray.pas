{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Attributes.SingleOrArray;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Types;

type
  TSoaItem = class
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  /// <summary>
  ///   The attribute on the list type covers every member declared with it
  /// </summary>
  [NeonSingleOrArray]
  TSoaItemList = class(TObjectList<TSoaItem>);

  TSoaTriple = array[0..2] of Integer;

  TSoaEntity = class
  private
    FList: TObjectList<TSoaItem>;
    FTypedList: TSoaItemList;
    FItems: TArray<TSoaItem>;
    FNumbers: TArray<Integer>;
    FTriple: TSoaTriple;
    FPlain: TArray<Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    [NeonSingleOrArray]
    property List: TObjectList<TSoaItem> read FList write FList;

    property TypedList: TSoaItemList read FTypedList write FTypedList;

    [NeonSingleOrArray]
    property Items: TArray<TSoaItem> read FItems write FItems;

    [NeonSingleOrArray]
    property Numbers: TArray<Integer> read FNumbers write FNumbers;

    [NeonSingleOrArray]
    property Triple: TSoaTriple read FTriple write FTriple;

    // No attribute: a single value is still an error here
    property Plain: TArray<Integer> read FPlain write FPlain;
  end;

  /// <summary>
  ///   [NeonSingleOrArray] lets a list or array member be read from a single
  ///   JSON value as well as from an array. Writing is not affected.
  /// </summary>
  [TestFixture]
  [Category('attrsingleorarray')]
  TTestAttributesSingleOrArray = class(TObject)
  private
    FEntity: TSoaEntity;
    procedure Read(const AJSON: string; AConfig: INeonConfiguration = nil);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSingleObjectIntoObjectList;

    [Test]
    procedure TestArrayIntoObjectList;

    [Test]
    procedure TestSingleObjectIntoTypeWithAttribute;

    [Test]
    procedure TestSingleObjectIntoDynArray;

    [Test]
    procedure TestSingleScalarIntoDynArray;

    [Test]
    procedure TestSingleScalarIntoStaticArray;

    [Test]
    procedure TestNullIsNotAnItem;

    [Test]
    procedure TestWithoutAttributeRaises;

    [Test]
    procedure TestWritesArray;
  end;

  /// <summary>
  ///   The schema of a [NeonSingleOrArray] member admits what the reader
  ///   accepts: one item, or an array of items
  /// </summary>
  [TestFixture]
  [Category('attrsingleorarray')]
  TTestSchemaSingleOrArray = class(TObject)
  private
    FSchema: TJSONObject;
    function PropertySchema(const AName: string): TJSONObject;
    function Accepts(const AInstanceJSON: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestListIsAnyOfItemOrArray;

    [Test]
    procedure TestAttributeOnListType;

    [Test]
    procedure TestMemberWithoutAttributeIsArray;

    [Test]
    procedure TestSchemaAcceptsSingleValues;

    [Test]
    procedure TestSchemaAcceptsArrays;

    [Test]
    procedure TestSchemaRejectsWrongItem;

    [Test]
    procedure TestSchemaAcceptsWhatIsWritten;
  end;

implementation

uses
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema;

{ TSoaEntity }

constructor TSoaEntity.Create;
begin
  FList := TObjectList<TSoaItem>.Create;
  FTypedList := TSoaItemList.Create;
end;

destructor TSoaEntity.Destroy;
var
  LItem: TSoaItem;
begin
  for LItem in FItems do
    LItem.Free;
  FTypedList.Free;
  FList.Free;
  inherited;
end;

{ TTestAttributesSingleOrArray }

procedure TTestAttributesSingleOrArray.Read(const AJSON: string; AConfig: INeonConfiguration);
begin
  if not Assigned(AConfig) then
    AConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);
  TNeon.JSONToObject(FEntity, AJSON, AConfig);
end;

procedure TTestAttributesSingleOrArray.Setup;
begin
  FEntity := TSoaEntity.Create;
end;

procedure TTestAttributesSingleOrArray.TearDown;
begin
  FreeAndNil(FEntity);
end;

procedure TTestAttributesSingleOrArray.TestSingleObjectIntoObjectList;
begin
  Read('{"List":{"Name":"one"}}');

  Assert.AreEqual(1, FEntity.List.Count);
  Assert.AreEqual('one', FEntity.List[0].Name);
end;

procedure TTestAttributesSingleOrArray.TestArrayIntoObjectList;
begin
  Read('{"List":[{"Name":"one"},{"Name":"two"}]}');

  Assert.AreEqual(2, FEntity.List.Count);
  Assert.AreEqual('one', FEntity.List[0].Name);
  Assert.AreEqual('two', FEntity.List[1].Name);
end;

procedure TTestAttributesSingleOrArray.TestSingleObjectIntoTypeWithAttribute;
begin
  Read('{"TypedList":{"Name":"one"}}');

  Assert.AreEqual(1, FEntity.TypedList.Count);
  Assert.AreEqual('one', FEntity.TypedList[0].Name);
end;

procedure TTestAttributesSingleOrArray.TestSingleObjectIntoDynArray;
begin
  Read('{"Items":{"Name":"one"}}');

  Assert.AreEqual(1, Integer(Length(FEntity.Items)));
  Assert.AreEqual('one', FEntity.Items[0].Name);
end;

procedure TTestAttributesSingleOrArray.TestSingleScalarIntoDynArray;
begin
  Read('{"Numbers":42}');

  Assert.AreEqual(1, Integer(Length(FEntity.Numbers)));
  Assert.AreEqual(42, FEntity.Numbers[0]);
end;

procedure TTestAttributesSingleOrArray.TestSingleScalarIntoStaticArray;
begin
  Read('{"Triple":7}');

  Assert.AreEqual(7, FEntity.Triple[0]);
  Assert.AreEqual(0, FEntity.Triple[1]);
end;

procedure TTestAttributesSingleOrArray.TestNullIsNotAnItem;
begin
  FEntity.Numbers := [1, 2];
  Read('{"Numbers":null}');

  Assert.AreEqual(0, Integer(Length(FEntity.Numbers)));
end;

procedure TTestAttributesSingleOrArray.TestWithoutAttributeRaises;
begin
  Assert.WillRaiseAny(
    procedure begin Read('{"Plain":42}') end
  );
end;

procedure TTestAttributesSingleOrArray.TestWritesArray;
var
  LItem: TSoaItem;
begin
  LItem := TSoaItem.Create;
  LItem.Name := 'one';
  FEntity.List.Add(LItem);
  FEntity.Numbers := [42];

  Assert.AreEqual(
    '{"List":[{"Name":"one"}],"TypedList":[],"Items":[],"Numbers":[42],"Triple":[0,0,0],"Plain":[]}',
    TNeon.ObjectToJSONString(FEntity));
end;

{ TTestSchemaSingleOrArray }

procedure TTestSchemaSingleOrArray.Setup;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSoaEntity);
end;

procedure TTestSchemaSingleOrArray.TearDown;
begin
  FreeAndNil(FSchema);
end;

function TTestSchemaSingleOrArray.PropertySchema(const AName: string): TJSONObject;
begin
  Result := (FSchema.GetValue('properties') as TJSONObject).GetValue(AName) as TJSONObject;
end;

function TTestSchemaSingleOrArray.Accepts(const AInstanceJSON: string): Boolean;
var
  LInstance: TJSONValue;
begin
  LInstance := TJSONObject.ParseJSONValue(AInstanceJSON);
  try
    Result := TNeon.ValidateJSON(LInstance, FSchema).IsValid;
  finally
    LInstance.Free;
  end;
end;

procedure TTestSchemaSingleOrArray.TestListIsAnyOfItemOrArray;
var
  LAnyOf: TJSONArray;
begin
  LAnyOf := PropertySchema('List').GetValue('anyOf') as TJSONArray;

  Assert.IsNotNull(LAnyOf);
  Assert.AreEqual(2, LAnyOf.Count);
  Assert.AreEqual('object', (LAnyOf.Items[0] as TJSONObject).GetValue('type').Value);
  Assert.AreEqual('array', (LAnyOf.Items[1] as TJSONObject).GetValue('type').Value);
  Assert.IsNull(PropertySchema('List').GetValue('type'));
end;

procedure TTestSchemaSingleOrArray.TestAttributeOnListType;
begin
  Assert.IsNotNull(PropertySchema('TypedList').GetValue('anyOf'));
end;

procedure TTestSchemaSingleOrArray.TestMemberWithoutAttributeIsArray;
begin
  Assert.AreEqual('array', PropertySchema('Plain').GetValue('type').Value);
  Assert.IsNull(PropertySchema('Plain').GetValue('anyOf'));
end;

procedure TTestSchemaSingleOrArray.TestSchemaAcceptsSingleValues;
begin
  Assert.IsTrue(Accepts(
    '{"List":{"Name":"a"},"TypedList":{"Name":"b"},"Items":{"Name":"c"},' +
    '"Numbers":42,"Triple":7,"Plain":[]}'));
end;

procedure TTestSchemaSingleOrArray.TestSchemaAcceptsArrays;
begin
  Assert.IsTrue(Accepts(
    '{"List":[{"Name":"a"}],"TypedList":[],"Items":[{"Name":"c"}],' +
    '"Numbers":[1,2],"Triple":[1,2,3],"Plain":[1]}'));
end;

procedure TTestSchemaSingleOrArray.TestSchemaRejectsWrongItem;
begin
  // A single value is only admitted where the attribute is, and only if it
  // matches the item schema
  Assert.IsFalse(Accepts('{"Plain":42}'));
  Assert.IsFalse(Accepts('{"Numbers":"abc"}'));
  Assert.IsFalse(Accepts('{"Numbers":["abc"]}'));
end;

procedure TTestSchemaSingleOrArray.TestSchemaAcceptsWhatIsWritten;
var
  LEntity: TSoaEntity;
  LJSON: TJSONValue;
begin
  LEntity := TSoaEntity.Create;
  try
    LEntity.Numbers := [42];
    LJSON := TNeon.ObjectToJSON(LEntity);
    try
      Assert.IsTrue(TNeon.ValidateJSON(LJSON, FSchema).IsValid, LJSON.ToJSON);
    finally
      LJSON.Free;
    end;
  finally
    LEntity.Free;
  end;
end;

end.
