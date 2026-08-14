{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Generator;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.JSON,
  System.Generics.Collections,
  DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Generator;

type
  /// <summary>
  ///   Mapping of the JSON values onto the Delphi types
  /// </summary>
  [TestFixture]
  [Category('entitygen')]
  TTestEntityGeneratorTypes = class(TObject)
  public
    [Test] procedure TestSimpleTypes;
    [Test] procedure TestLargeIntegerBecomesInt64;
    [Test] procedure TestIntegerWrittenAsFloatIsAFloat;
    [Test] procedure TestIntegerAndFloatSamplesMergeIntoFloat;
    [Test] procedure TestDateTimeDetection;
    [Test] procedure TestDateOnlyDetection;
    [Test] procedure TestDateTimeDetectionCanBeDisabled;
    [Test] procedure TestNotEveryStringIsADate;
    [Test] procedure TestAlwaysNullMemberFallsBackToUnknownType;
    [Test] procedure TestUnknownTypeIsConfigurable;
    [Test] procedure TestConflictingSamplesFallBackToUnknownType;
    [Test] procedure TestNullDoesNotConflictWithTheOtherSamples;
  end;

  /// <summary>
  ///   JSON member names turned into Delphi identifiers
  /// </summary>
  [TestFixture]
  [Category('entitygen')]
  TTestEntityGeneratorNaming = class(TObject)
  public
    [Test] procedure TestSnakeCaseName;
    [Test] procedure TestKebabCaseName;
    [Test] procedure TestCamelCaseName;
    [Test] procedure TestScreamingSnakeName;
    [Test] procedure TestSeparatorsAreDropped;
    [Test] procedure TestNameStartingWithADigit;
    [Test] procedure TestUnchangedCase;
    [Test] procedure TestNeonPropertyOnlyWhenTheNameChanges;
    [Test] procedure TestNeonPropertyCanBeDisabled;
    [Test] procedure TestQuoteInTheJSONNameIsEscaped;
    [Test] procedure TestReservedWordIsEscaped;
    [Test] procedure TestReservedMemberIsRenamed;
    [Test] procedure TestReservedMemberIsKeptInRecords;
    [Test] procedure TestNamesCollidingAfterTheConversion;
  end;

  /// <summary>
  ///   Structure of the generated entities: nesting, arrays, type merging
  /// </summary>
  [TestFixture]
  [Category('entitygen')]
  TTestEntityGeneratorStructure = class(TObject)
  public
    [Test] procedure TestNestedObjectIsDeclaredBeforeItsOwner;
    [Test] procedure TestArrayOfObjects;
    [Test] procedure TestArrayItemNameIsSingularized;
    [Test] procedure TestArrayKindDynamicArray;
    [Test] procedure TestArrayKindGenericList;
    [Test] procedure TestArrayOfSimpleValues;
    [Test] procedure TestArrayOfArrays;
    [Test] procedure TestAlwaysEmptyArray;
    [Test] procedure TestArrayItemsAreAllSamplesOfOneEntity;
    [Test] procedure TestEqualStructuresShareOneEntity;
    [Test] procedure TestMergingCanBeDisabled;
    [Test] procedure TestDifferentStructuresGetDistinctNames;
    [Test] procedure TestRootArrayGeneratesAListAlias;
    [Test] procedure TestRootArrayOfSimpleValuesGeneratesNoEntity;
    [Test] procedure TestRootSimpleValueGeneratesNoEntity;
    [Test] procedure TestSamplesCanBeAddedOneAtATime;
    [Test] procedure TestNullableForAMemberSometimesNull;
    [Test] procedure TestNullableForAnOptionalMember;
    [Test] procedure TestNullableIsNotUsedForEntities;
    [Test] procedure TestRecords;
    [Test] procedure TestEmptyObject;
  end;

  /// <summary>
  ///   The generated unit as a whole
  /// </summary>
  [TestFixture]
  [Category('entitygen')]
  TTestEntityGeneratorUnit = class(TObject)
  public
    [Test] procedure TestUnitStructure;
    [Test] procedure TestUsesClause;
    [Test] procedure TestUsesNullables;
    [Test] procedure TestNoUsesClauseWhenNothingIsNeeded;
    [Test] procedure TestLifetimeMethods;
    [Test] procedure TestObjectListIsCreatedOwningItsItems;
    [Test] procedure TestLifetimeCanBeDisabled;
    [Test] procedure TestNoLifetimeWithoutOwnedMembers;
    [Test] procedure TestHeaderCanBeDisabled;
    [Test] procedure TestIndentSize;
    [Test] procedure TestGeneratingTwiceGivesTheSameSource;
    [Test] procedure TestGenerateWithoutADocumentRaises;
    [Test] procedure TestParsingAnInvalidDocumentRaises;
    [Test] procedure TestParseValue;
  end;

  { Entities equivalent to what the generator emits for CUSTOMER_JSON, used to
    check that the generated source is what a hand written Neon entity looks
    like: same names, same attributes, same containers }

  TGenAddress = class
  private
    FCity: string;
  public
    [NeonProperty('city')]
    property City: string read FCity write FCity;
  end;

  TGenOrder = class
  private
    FCode: string;
    FTotal: Double;
  public
    [NeonProperty('code')]
    property Code: string read FCode write FCode;
    [NeonProperty('total')]
    property Total: Double read FTotal write FTotal;
  end;

  TGenCustomer = class
  private
    FFirstName: string;
    FAge: Integer;
    FAddress: TGenAddress;
    FOrders: TObjectList<TGenOrder>;
  public
    constructor Create;
    destructor Destroy; override;

    [NeonProperty('first_name')]
    property FirstName: string read FFirstName write FFirstName;
    [NeonProperty('age')]
    property Age: Integer read FAge write FAge;
    [NeonProperty('address')]
    property Address: TGenAddress read FAddress write FAddress;
    [NeonProperty('orders')]
    property Orders: TObjectList<TGenOrder> read FOrders write FOrders;
  end;

  /// <summary>
  ///   The generated entities against the hand written ones they stand for
  /// </summary>
  [TestFixture]
  [Category('entitygen')]
  TTestEntityGeneratorEntities = class(TObject)
  public
    [Test] procedure TestGeneratedSourceMatchesTheHandWrittenEntities;
    [Test] procedure TestHandWrittenEntitiesRoundTripTheDocument;
  end;

implementation

const
  CUSTOMER_JSON =
    '{"first_name":"Paolo","age":50,"address":{"city":"Parma"},' +
    '"orders":[{"code":"A1","total":10.5},{"code":"A2","total":20.0}]}';

/// <summary>
///   Joins the lines of an expected source fragment the way the generator
///   writes them out, trailing line break included
/// </summary>
function Lines(const ALines: array of string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := Low(ALines) to High(ALines) do
    Result := Result + ALines[LIndex] + sLineBreak;
end;

function TypesOf(const AJSON: string): string;
begin
  Result := TNeonEntityGenerator.JSONToTypes(AJSON);
end;

function TypesOfConfig(const AJSON: string; const AConfig: TNeonEntityConfig): string;
begin
  Result := TNeonEntityGenerator.JSONToTypes(AJSON, AConfig);
end;

{ TTestEntityGeneratorTypes }

procedure TTestEntityGeneratorTypes.TestSimpleTypes;
var
  LCode: string;
begin
  LCode := TypesOf('{"a":"text","b":12,"c":1.5,"d":true}');

  Assert.Contains(LCode, 'property A: string read FA write FA;', False);
  Assert.Contains(LCode, 'property B: Integer read FB write FB;', False);
  Assert.Contains(LCode, 'property C: Double read FC write FC;', False);
  Assert.Contains(LCode, 'property D: Boolean read FD write FD;', False);
end;

procedure TTestEntityGeneratorTypes.TestLargeIntegerBecomesInt64;
var
  LCode: string;
begin
  LCode := TypesOf('{"small":2147483647,"big":2147483648,"negative":-2147483649}');

  Assert.Contains(LCode, 'FSmall: Integer;', False);
  Assert.Contains(LCode, 'FBig: Int64;', False);
  Assert.Contains(LCode, 'FNegative: Int64;', False);
end;

procedure TTestEntityGeneratorTypes.TestIntegerWrittenAsFloatIsAFloat;
begin
  // The document says 1.0, not 1: the member is a floating point one
  Assert.Contains(TypesOf('{"value":1.0}'), 'FValue: Double;', False);
  Assert.Contains(TypesOf('{"value":1e3}'), 'FValue: Double;', False);
end;

procedure TTestEntityGeneratorTypes.TestIntegerAndFloatSamplesMergeIntoFloat;
begin
  Assert.Contains(TypesOf('[{"value":1},{"value":2.5}]'), 'FValue: Double;', False);
  Assert.Contains(TypesOf('[{"value":2.5},{"value":1}]'), 'FValue: Double;', False);
end;

procedure TTestEntityGeneratorTypes.TestDateTimeDetection;
begin
  Assert.Contains(TypesOf('{"when":"2026-08-12T10:00:00Z"}'), 'FWhen: TDateTime;', False);
  Assert.Contains(TypesOf('{"when":"2026-08-12T10:00:00.123+02:00"}'), 'FWhen: TDateTime;', False);
  Assert.Contains(TypesOf('{"when":"10:00:00"}'), 'FWhen: TDateTime;', False);
end;

procedure TTestEntityGeneratorTypes.TestDateOnlyDetection;
begin
  Assert.Contains(TypesOf('{"when":"2026-08-12"}'), 'FWhen: TDateTime;', False);
end;

procedure TTestEntityGeneratorTypes.TestDateTimeDetectionCanBeDisabled;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"when":"2026-08-12T10:00:00Z"}',
    TNeonEntityConfig.Default.SetDetectDateTime(False));

  Assert.Contains(LCode, 'FWhen: string;', False);
end;

procedure TTestEntityGeneratorTypes.TestNotEveryStringIsADate;
begin
  Assert.Contains(TypesOf('{"when":"2026"}'), 'FWhen: string;', False);
  Assert.Contains(TypesOf('{"when":"12/08/2026"}'), 'FWhen: string;', False);

  // One sample that is not a date is enough to rule the whole member out
  Assert.Contains(TypesOf('[{"when":"2026-08-12"},{"when":"tomorrow"}]'),
    'FWhen: string;', False);
end;

procedure TTestEntityGeneratorTypes.TestAlwaysNullMemberFallsBackToUnknownType;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('{"name":"Paolo","nickname":null}');

    Assert.Contains(LGenerator.GenerateTypes, 'FNickname: string;', False);
    Assert.AreEqual(1, LGenerator.Warnings.Count);
    Assert.Contains(LGenerator.Warnings[0], 'nickname', False);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorTypes.TestUnknownTypeIsConfigurable;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"payload":null}',
    TNeonEntityConfig.Default.SetUnknownType('TJSONValue'));

  Assert.Contains(LCode, 'FPayload: TJSONValue;', False);
end;

procedure TTestEntityGeneratorTypes.TestConflictingSamplesFallBackToUnknownType;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('[{"value":1},{"value":"text"}]');

    Assert.Contains(LGenerator.GenerateTypes, 'FValue: string;', False);
    Assert.AreEqual(1, LGenerator.Warnings.Count);
    Assert.Contains(LGenerator.Warnings[0], '/value', False);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorTypes.TestNullDoesNotConflictWithTheOtherSamples;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    // null says nothing about the type, so it never conflicts with anything
    LGenerator.Parse('[{"value":null},{"value":42}]');

    Assert.Contains(LGenerator.GenerateTypes, 'FValue: Integer;', False);
    Assert.AreEqual(0, LGenerator.Warnings.Count);
  finally
    LGenerator.Free;
  end;
end;

{ TTestEntityGeneratorNaming }

procedure TTestEntityGeneratorNaming.TestSnakeCaseName;
begin
  Assert.Contains(TypesOf('{"user_first_name":"x"}'),
    'property UserFirstName: string read FUserFirstName write FUserFirstName;', False);
end;

procedure TTestEntityGeneratorNaming.TestKebabCaseName;
begin
  Assert.Contains(TypesOf('{"zip-code":"x"}'), 'property ZipCode:', False);
end;

procedure TTestEntityGeneratorNaming.TestCamelCaseName;
begin
  Assert.Contains(TypesOf('{"shipToAddress":"x"}'), 'property ShipToAddress:', False);
end;

procedure TTestEntityGeneratorNaming.TestScreamingSnakeName;
begin
  // An all uppercase word is an acronym, and reads better folded
  Assert.Contains(TypesOf('{"USER_ID":1}'), 'property UserId:', False);
end;

procedure TTestEntityGeneratorNaming.TestSeparatorsAreDropped;
begin
  Assert.Contains(TypesOf('{"first name":"x"}'), 'property FirstName:', False);
  Assert.Contains(TypesOf('{"first.name":"x"}'), 'property FirstName:', False);
  Assert.Contains(TypesOf('{"@id":1}'), 'property Id:', False);
end;

procedure TTestEntityGeneratorNaming.TestNameStartingWithADigit;
begin
  Assert.Contains(TypesOf('{"1st":"x"}'), 'property _1st:', False);
end;

procedure TTestEntityGeneratorNaming.TestUnchangedCase;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"user_name":"x","zip-code":"y"}',
    TNeonEntityConfig.Default.SetNameCase(TNeonNameCase.Unchanged));

  Assert.Contains(LCode, 'property user_name: string read Fuser_name', False);
  // What is not legal in an identifier still has to go
  Assert.Contains(LCode, 'property zip_code:', False);
end;

procedure TTestEntityGeneratorNaming.TestNeonPropertyOnlyWhenTheNameChanges;
var
  LCode: string;
begin
  LCode := TypesOf('{"Name":"x","user_name":"y"}');

  Assert.Contains(LCode, '[NeonProperty(''user_name'')]', False);
  Assert.DoesNotContain(LCode, '[NeonProperty(''Name'')]', False);
end;

procedure TTestEntityGeneratorNaming.TestNeonPropertyCanBeDisabled;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"user_name":"y"}',
    TNeonEntityConfig.Default.SetUseNeonProperty(False));

  Assert.Contains(LCode, 'property UserName:', False);
  Assert.DoesNotContain(LCode, 'NeonProperty', False);
end;

procedure TTestEntityGeneratorNaming.TestQuoteInTheJSONNameIsEscaped;
begin
  Assert.Contains(TypesOf('{"it''s":"x"}'), '[NeonProperty(''it''''s'')]', False);
end;

procedure TTestEntityGeneratorNaming.TestReservedWordIsEscaped;
var
  LCode: string;
begin
  LCode := TypesOf('{"type":"x","end":1}');

  Assert.Contains(LCode, 'FType: string;', False);
  Assert.Contains(LCode, 'property &Type: string read FType write FType;', False);
  Assert.Contains(LCode, 'property &End: Integer read FEnd write FEnd;', False);
end;

procedure TTestEntityGeneratorNaming.TestReservedMemberIsRenamed;
var
  LCode: string;
begin
  // Escaping does not help here: TObject.Create and the property would still
  // be the same identifier
  LCode := TypesOf('{"create":"x","ToString":"y"}');

  Assert.Contains(LCode, 'property Create_: string read FCreate_ write FCreate_;', False);
  Assert.Contains(LCode, '[NeonProperty(''create'')]', False);
  Assert.Contains(LCode, 'property ToString_:', False);
end;

procedure TTestEntityGeneratorNaming.TestReservedMemberIsKeptInRecords;
var
  LCode: string;
begin
  // A record has no TObject methods to collide with
  LCode := TypesOfConfig('{"create":"x"}', TNeonEntityConfig.Records);

  Assert.Contains(LCode, 'Create: string;', False);
  Assert.DoesNotContain(LCode, 'Create_', False);
end;

procedure TTestEntityGeneratorNaming.TestNamesCollidingAfterTheConversion;
var
  LCode: string;
begin
  LCode := TypesOf('{"user_name":"a","userName":"b"}');

  Assert.Contains(LCode, 'property UserName: string read FUserName write FUserName;', False);
  Assert.Contains(LCode, 'property UserName2: string read FUserName2 write FUserName2;', False);
  Assert.Contains(LCode, '[NeonProperty(''userName'')]', False);
end;

{ TTestEntityGeneratorStructure }

procedure TTestEntityGeneratorStructure.TestNestedObjectIsDeclaredBeforeItsOwner;
var
  LCode: string;
begin
  LCode := TypesOf('{"address":{"city":"Parma"}}');

  Assert.Contains(LCode, 'TAddress = class', False);
  Assert.Contains(LCode, 'FAddress: TAddress;', False);
  // Declaring the members first is what makes forward declarations useless
  Assert.IsTrue(Pos('TAddress = class', LCode) < Pos('TRoot = class', LCode),
    'The nested entity must be declared before the entity using it');
end;

procedure TTestEntityGeneratorStructure.TestArrayOfObjects;
var
  LCode: string;
begin
  LCode := TypesOf('{"orders":[{"code":"A1"}]}');

  Assert.Contains(LCode, 'TOrder = class', False);
  Assert.Contains(LCode, 'FOrders: TObjectList<TOrder>;', False);
end;

procedure TTestEntityGeneratorStructure.TestArrayItemNameIsSingularized;
begin
  Assert.Contains(TypesOf('{"addresses":[{"city":"x"}]}'), 'TAddress = class', False);
  Assert.Contains(TypesOf('{"companies":[{"name":"x"}]}'), 'TCompany = class', False);
  Assert.Contains(TypesOf('{"boxes":[{"size":1}]}'), 'TBox = class', False);
  // An irregular plural is left alone: a plural type name costs nothing
  Assert.Contains(TypesOf('{"children":[{"name":"x"}]}'), 'TChildren = class', False);
end;

procedure TTestEntityGeneratorStructure.TestArrayKindDynamicArray;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"orders":[{"code":"A1"}]}',
    TNeonEntityConfig.Default.SetArrayKind(TNeonArrayKind.DynamicArray));

  Assert.Contains(LCode, 'FOrders: TArray<TOrder>;', False);
  // Nothing to own, so nothing to create and destroy
  Assert.DoesNotContain(LCode, 'constructor Create;', False);
end;

procedure TTestEntityGeneratorStructure.TestArrayKindGenericList;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"orders":[{"code":"A1"}]}',
    TNeonEntityConfig.Default.SetArrayKind(TNeonArrayKind.GenericList));

  Assert.Contains(LCode, 'FOrders: TList<TOrder>;', False);
end;

procedure TTestEntityGeneratorStructure.TestArrayOfSimpleValues;
var
  LCode: string;
begin
  LCode := TypesOf('{"tags":["a","b"],"sizes":[1,2]}');

  Assert.Contains(LCode, 'FTags: TArray<string>;', False);
  Assert.Contains(LCode, 'FSizes: TArray<Integer>;', False);
end;

procedure TTestEntityGeneratorStructure.TestArrayOfArrays;
begin
  Assert.Contains(TypesOf('{"matrix":[[1,2],[3,4]]}'),
    'FMatrix: TArray<TArray<Integer>>;', False);
end;

procedure TTestEntityGeneratorStructure.TestAlwaysEmptyArray;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('{"tags":[]}');

    Assert.Contains(LGenerator.GenerateTypes, 'FTags: TArray<string>;', False);
    Assert.AreEqual(1, LGenerator.Warnings.Count);
    Assert.Contains(LGenerator.Warnings[0], 'tags', False);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorStructure.TestArrayItemsAreAllSamplesOfOneEntity;
var
  LCode: string;
begin
  // The items describe one type between them: the members of the entity are
  // the union of the members of the items
  LCode := TypesOf('{"orders":[{"code":"A1"},{"note":"hi"}]}');

  Assert.Contains(LCode, 'FCode: string;', False);
  Assert.Contains(LCode, 'FNote: string;', False);
  Assert.AreEqual(2, Length(SplitString(LCode, '=')) - 1, 'One entity per JSON object shape');
end;

procedure TTestEntityGeneratorStructure.TestEqualStructuresShareOneEntity;
var
  LCode: string;
begin
  LCode := TypesOf('{"from":{"city":"Parma"},"to":{"city":"Rome"}}');

  Assert.Contains(LCode, 'FFrom: TFrom;', False);
  Assert.Contains(LCode, 'FTo: TFrom;', False);
  Assert.DoesNotContain(LCode, 'TTo = class', False);
end;

procedure TTestEntityGeneratorStructure.TestMergingCanBeDisabled;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"from":{"city":"Parma"},"to":{"city":"Rome"}}',
    TNeonEntityConfig.Default.SetMergeEqualTypes(False));

  Assert.Contains(LCode, 'TFrom = class', False);
  Assert.Contains(LCode, 'TTo = class', False);
  Assert.Contains(LCode, 'FTo: TTo;', False);
end;

procedure TTestEntityGeneratorStructure.TestDifferentStructuresGetDistinctNames;
var
  LCode: string;
begin
  // Same member name, different structure: the second entity cannot take the
  // name of the first one
  LCode := TypesOf('{"a":{"item":{"x":1}},"b":{"item":{"y":"text"}}}');

  Assert.Contains(LCode, 'TItem = class', False);
  Assert.Contains(LCode, 'TItem2 = class', False);
end;

procedure TTestEntityGeneratorStructure.TestRootArrayGeneratesAListAlias;
var
  LGenerator: TNeonEntityGenerator;
  LCode: string;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('[{"code":"A1"},{"code":"A2"}]');
    LCode := LGenerator.GenerateTypes;

    Assert.Contains(LCode, 'TRoot = class', False);
    Assert.Contains(LCode, 'TRootList = TObjectList<TRoot>;', False);
    Assert.AreEqual('TRootList', LGenerator.RootTypeName);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorStructure.TestRootArrayOfSimpleValuesGeneratesNoEntity;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('[1,2,3]');

    Assert.AreEqual('', LGenerator.GenerateTypes);
    Assert.AreEqual('TArray<Integer>', LGenerator.RootTypeName);
    Assert.AreEqual(1, LGenerator.Warnings.Count);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorStructure.TestRootSimpleValueGeneratesNoEntity;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('"just a string"');

    Assert.AreEqual('', LGenerator.GenerateTypes);
    Assert.AreEqual('string', LGenerator.RootTypeName);
    Assert.AreEqual(1, LGenerator.Warnings.Count);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorStructure.TestSamplesCanBeAddedOneAtATime;
var
  LGenerator: TNeonEntityGenerator;
  LCode: string;
begin
  // Two responses of the same endpoint describe one entity between them
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse('{"code":"A1"}');
    LGenerator.AddSample('{"code":"A2","note":"hi"}');
    LCode := LGenerator.GenerateTypes;

    Assert.Contains(LCode, 'FCode: string;', False);
    Assert.Contains(LCode, 'FNote: string;', False);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorStructure.TestNullableForAMemberSometimesNull;
var
  LCode: string;
begin
  LCode := TypesOfConfig('[{"note":"hi"},{"note":null}]',
    TNeonEntityConfig.Default.SetUseNullables(True));

  Assert.Contains(LCode, 'FNote: Nullable<string>;', False);
end;

procedure TTestEntityGeneratorStructure.TestNullableForAnOptionalMember;
var
  LCode: string;
begin
  // "note" is missing from one of the samples, which says as much about it as
  // an explicit null would
  LCode := TypesOfConfig('[{"code":"A1","note":"hi"},{"code":"A2"}]',
    TNeonEntityConfig.Default.SetUseNullables(True));

  Assert.Contains(LCode, 'FCode: string;', False);
  Assert.Contains(LCode, 'FNote: Nullable<string>;', False);
end;

procedure TTestEntityGeneratorStructure.TestNullableIsNotUsedForEntities;
var
  LCode: string;
begin
  // A class member is already nil when the document says null, and a dynamic
  // array is already empty
  LCode := TypesOfConfig('[{"address":{"city":"Parma"},"tags":["a"]},{"address":null,"tags":null}]',
    TNeonEntityConfig.Default.SetUseNullables(True));

  Assert.Contains(LCode, 'FAddress: TAddress;', False);
  Assert.Contains(LCode, 'FTags: TArray<string>;', False);
end;

procedure TTestEntityGeneratorStructure.TestRecords;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"name":"Paolo","address":{"city":"Parma"},"orders":[{"code":"A1"}]}',
    TNeonEntityConfig.Records);

  Assert.Contains(LCode, 'TAddress = record', False);
  Assert.Contains(LCode, 'TRoot = record', False);
  Assert.Contains(LCode, 'Address: TAddress;', False);
  // Records own nothing: an object list would have nobody to free it
  Assert.Contains(LCode, 'Orders: TArray<TOrder>;', False);
  Assert.DoesNotContain(LCode, 'constructor', False);
  Assert.DoesNotContain(LCode, 'property', False);
end;

procedure TTestEntityGeneratorStructure.TestEmptyObject;
begin
  Assert.AreEqual(Lines([
    'type',
    '  TRoot = class',
    '  end;'
  ]), TypesOf('{}'));
end;

{ TTestEntityGeneratorUnit }

procedure TTestEntityGeneratorUnit.TestUnitStructure;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"name":"Paolo"}', 'Demo.Entities');

  Assert.Contains(LCode, 'unit Demo.Entities;', False);
  Assert.Contains(LCode, 'interface', False);
  Assert.Contains(LCode, 'type', False);
  Assert.Contains(LCode, 'implementation', False);
  Assert.EndsWith('end.' + sLineBreak, LCode);
end;

procedure TTestEntityGeneratorUnit.TestUsesClause;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"orders":[{"my_code":"A1"}]}', 'Demo.Entities');

  Assert.Contains(LCode, 'System.Generics.Collections', False);
  Assert.Contains(LCode, 'Neon.Core.Attributes', False);
end;

procedure TTestEntityGeneratorUnit.TestUsesNullables;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"note":null}', 'Demo.Entities',
    TNeonEntityConfig.Default.SetUseNullables(True).SetUnknownType('string'));

  // A member with no type at all cannot be made nullable: nothing to wrap
  Assert.DoesNotContain(LCode, 'Neon.Core.Nullables', False);

  LCode := TNeonEntityGenerator.JSONToUnit('[{"note":"hi"},{"note":null}]', 'Demo.Entities',
    TNeonEntityConfig.Default.SetUseNullables(True));

  Assert.Contains(LCode, 'Neon.Core.Nullables', False);
end;

procedure TTestEntityGeneratorUnit.TestNoUsesClauseWhenNothingIsNeeded;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"Name":"Paolo"}', 'Demo.Entities',
    TNeonEntityConfig.Records.SetWriteHeader(False));

  Assert.DoesNotContain(LCode, 'uses', False);
end;

procedure TTestEntityGeneratorUnit.TestLifetimeMethods;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"address":{"city":"Parma"}}', 'Demo.Entities');

  Assert.Contains(LCode, Lines([
    '    constructor Create;',
    '    destructor Destroy; override;'
  ]), False);

  Assert.Contains(LCode, Lines([
    'constructor TRoot.Create;',
    'begin',
    '  inherited Create;',
    '  FAddress := TAddress.Create;',
    'end;'
  ]), False);

  Assert.Contains(LCode, Lines([
    'destructor TRoot.Destroy;',
    'begin',
    '  FAddress.Free;',
    '  inherited Destroy;',
    'end;'
  ]), False);
end;

procedure TTestEntityGeneratorUnit.TestObjectListIsCreatedOwningItsItems;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"orders":[{"code":"A1"}]}', 'Demo.Entities');

  Assert.Contains(LCode, 'FOrders := TObjectList<TOrder>.Create(True);', False);
  Assert.Contains(LCode, 'FOrders.Free;', False);
end;

procedure TTestEntityGeneratorUnit.TestLifetimeCanBeDisabled;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"address":{"city":"Parma"}}', 'Demo.Entities',
    TNeonEntityConfig.Default.SetGenerateLifetime(False));

  Assert.Contains(LCode, 'FAddress: TAddress;', False);
  Assert.DoesNotContain(LCode, 'constructor', False);
  Assert.DoesNotContain(LCode, 'destructor', False);
end;

procedure TTestEntityGeneratorUnit.TestNoLifetimeWithoutOwnedMembers;
var
  LCode: string;
begin
  LCode := TNeonEntityGenerator.JSONToUnit('{"name":"Paolo","tags":["a"]}', 'Demo.Entities');

  Assert.DoesNotContain(LCode, 'constructor', False);
  Assert.DoesNotContain(LCode, 'destructor', False);
end;

procedure TTestEntityGeneratorUnit.TestHeaderCanBeDisabled;
var
  LCode: string;
begin
  Assert.StartsWith('{****', TNeonEntityGenerator.JSONToUnit('{"a":1}', 'Demo.Entities'));

  LCode := TNeonEntityGenerator.JSONToUnit('{"a":1}', 'Demo.Entities',
    TNeonEntityConfig.Default.SetWriteHeader(False));

  Assert.StartsWith('unit Demo.Entities;', LCode);
end;

procedure TTestEntityGeneratorUnit.TestIndentSize;
var
  LCode: string;
begin
  LCode := TypesOfConfig('{"name":"Paolo"}', TNeonEntityConfig.Default.SetIndentSize(4));

  Assert.Contains(LCode, Lines([
    '    TRoot = class',
    '    private',
    '        FName: string;'
  ]), False);
end;

procedure TTestEntityGeneratorUnit.TestGeneratingTwiceGivesTheSameSource;
var
  LGenerator: TNeonEntityGenerator;
begin
  // Names are assigned at every generation: running it twice must not turn
  // TRoot into TRoot2
  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse(CUSTOMER_JSON);
    Assert.AreEqual(LGenerator.GenerateUnit('Demo.Entities'), LGenerator.GenerateUnit('Demo.Entities'));
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorUnit.TestGenerateWithoutADocumentRaises;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LGenerator.GenerateTypes;
      end, ENeonException);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorUnit.TestParsingAnInvalidDocumentRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TNeonEntityGenerator.JSONToTypes('{"broken"');
    end, ENeonException);
end;

procedure TTestEntityGeneratorUnit.TestParseValue;
var
  LGenerator: TNeonEntityGenerator;
  LJSON: TJSONValue;
begin
  LGenerator := TNeonEntityGenerator.Create;
  try
    LJSON := TJSONObject.ParseJSONValue('{"name":"Paolo"}');
    try
      LGenerator.ParseValue(LJSON);
    finally
      LJSON.Free;
    end;

    // The document is read into the model, not held on to
    Assert.Contains(LGenerator.GenerateTypes, 'FName: string;', False);
  finally
    LGenerator.Free;
  end;
end;

{ TGenCustomer }

constructor TGenCustomer.Create;
begin
  inherited Create;
  FAddress := TGenAddress.Create;
  FOrders := TObjectList<TGenOrder>.Create(True);
end;

destructor TGenCustomer.Destroy;
begin
  FOrders.Free;
  FAddress.Free;
  inherited Destroy;
end;

{ TTestEntityGeneratorEntities }

procedure TTestEntityGeneratorEntities.TestGeneratedSourceMatchesTheHandWrittenEntities;
var
  LGenerator: TNeonEntityGenerator;
begin
  LGenerator := TNeonEntityGenerator.Create(
    TNeonEntityConfig.Default.SetTypePrefix('TGen').SetRootName('Customer'));
  try
    LGenerator.Parse(CUSTOMER_JSON);

    Assert.AreEqual(Lines([
      'type',
      '  TGenAddress = class',
      '  private',
      '    FCity: string;',
      '  public',
      '    [NeonProperty(''city'')]',
      '    property City: string read FCity write FCity;',
      '  end;',
      '',
      '  TGenOrder = class',
      '  private',
      '    FCode: string;',
      '    FTotal: Double;',
      '  public',
      '    [NeonProperty(''code'')]',
      '    property Code: string read FCode write FCode;',
      '    [NeonProperty(''total'')]',
      '    property Total: Double read FTotal write FTotal;',
      '  end;',
      '',
      '  TGenCustomer = class',
      '  private',
      '    FFirstName: string;',
      '    FAge: Integer;',
      '    FAddress: TGenAddress;',
      '    FOrders: TObjectList<TGenOrder>;',
      '  public',
      '    constructor Create;',
      '    destructor Destroy; override;',
      '',
      '    [NeonProperty(''first_name'')]',
      '    property FirstName: string read FFirstName write FFirstName;',
      '    [NeonProperty(''age'')]',
      '    property Age: Integer read FAge write FAge;',
      '    [NeonProperty(''address'')]',
      '    property Address: TGenAddress read FAddress write FAddress;',
      '    [NeonProperty(''orders'')]',
      '    property Orders: TObjectList<TGenOrder> read FOrders write FOrders;',
      '  end;'
    ]), LGenerator.GenerateTypes);

    Assert.AreEqual(Lines([
      '{ TGenCustomer }',
      '',
      'constructor TGenCustomer.Create;',
      'begin',
      '  inherited Create;',
      '  FAddress := TGenAddress.Create;',
      '  FOrders := TObjectList<TGenOrder>.Create(True);',
      'end;',
      '',
      'destructor TGenCustomer.Destroy;',
      'begin',
      '  FOrders.Free;',
      '  FAddress.Free;',
      '  inherited Destroy;',
      'end;',
      ''
    ]), LGenerator.GenerateImplementation);
  finally
    LGenerator.Free;
  end;
end;

procedure TTestEntityGeneratorEntities.TestHandWrittenEntitiesRoundTripTheDocument;
var
  LCustomer: TGenCustomer;
  LJSON: TJSONValue;
begin
  // The entities above are the generated source, compiled: deserializing and
  // serializing the document they were generated from gives it back unchanged
  LCustomer := TNeon.JSONToObject<TGenCustomer>(CUSTOMER_JSON);
  try
    Assert.AreEqual('Paolo', LCustomer.FirstName);
    Assert.AreEqual(50, LCustomer.Age);
    Assert.AreEqual('Parma', LCustomer.Address.City);
    Assert.AreEqual(2, LCustomer.Orders.Count);
    Assert.AreEqual('A2', LCustomer.Orders[1].Code);

    LJSON := TNeon.ObjectToJSON(LCustomer);
    try
      Assert.AreEqual(CUSTOMER_JSON, TNeon.Print(LJSON, False));
    finally
      LJSON.Free;
    end;
  finally
    LCustomer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEntityGeneratorTypes);
  TDUnitX.RegisterTestFixture(TTestEntityGeneratorNaming);
  TDUnitX.RegisterTestFixture(TTestEntityGeneratorStructure);
  TDUnitX.RegisterTestFixture(TTestEntityGeneratorUnit);
  TDUnitX.RegisterTestFixture(TTestEntityGeneratorEntities);

end.
