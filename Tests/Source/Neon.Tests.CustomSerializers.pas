{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.CustomSerializers;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.JSON, DUnitX.TestFramework,

  FireDAC.Comp.DataSet, FireDAC.Comp.Client,

  Neon.Core.Nullables,
  Neon.Core.Persistence,
  Neon.Core.Types,
  Neon.Tests.Entities,
  Neon.Tests.Utils,
  Neon.Data.Tests;

type

  TStreamHolder = class
  private
    FStream: TStream;
  public
    property Stream: TStream read FStream write FStream;
  end;

  TBoom = class
  public
    function GetExplode: string;
    property Explode: string read GetExplode;
  end;

  TBoomHolder = class
  private
    FBoom: TBoom;
  public
    property Boom: TBoom read FBoom write FBoom;
  end;

  TNullableGUIDHolder = class
  private
    FValue: Nullable<TGUID>;
  public
    property Value: Nullable<TGUID> read FValue write FValue;
  end;

  TJSONValueHolder = class
  private
    FData: TJSONObject;
    FAny: TJSONValue;
  public
    destructor Destroy; override;

    property Data: TJSONObject read FData write FData;
    property Any: TJSONValue read FAny write FAny;
  end;

  [TestFixture]
  TTestCustomSerializers = class(TObject)
  private
    FData: TDataTests;
    FConfig: INeonConfiguration;

    procedure RegisterSerializers;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSerializerRegistryCount;

    [Test]
    procedure TestDistanceAlgorithm;

    [Test]
    procedure TestSelectorAlgorithmOnValue;

    [Test]
    procedure TestSelectorUnregister;

    [Test]
    procedure TestSelectorAlgorithmOnClass;

    [Test]
    procedure TestNilStreamMemberSerializeSkips;

    [Test]
    procedure TestNilStreamMemberDeserializeSkips;

    [Test]
    procedure TestNestedErrorPropagatesWhenRaising;

    [Test]
    procedure TestNestedErrorSwallowedByDefault;

    [Test]
    procedure TestAssignDoesNotShareInstances;

    [Test]
    procedure TestRegisterInvalidatesCache;

    [Test]
    procedure TestNullableInnerSerializerRoundTrips;

    [Test]
    procedure TestJSONValueMemberWithoutAnInstance;

    [Test]
    procedure TestJSONValueMemberTakesAnyKind;

    [Test]
    procedure TestJSONValueMemberReplacesOnASecondRead;

    [Test]
    procedure TestJSONValueMemberRefusesAnIncompatibleKind;

    [Test]
    procedure TestJSONValueAsTheOriginalInstance;

  end;

implementation

uses
  Neon.Core.Persistence.JSON,
  Neon.Core.Serializers.DB,
  Neon.Core.Serializers.RTL,
  Neon.Core.Serializers.VCL,
  Neon.Serializers.Tests;

procedure TTestCustomSerializers.RegisterSerializers;
begin
  FConfig.GetSerializers.Clear;

  // Standard Serializers
  FConfig.GetSerializers.RegisterSerializer(TGUIDSerializer);
  FConfig.GetSerializers.RegisterSerializer(TStreamSerializer);
  FConfig.GetSerializers.RegisterSerializer(TDataSetSerializer);
  FConfig.GetSerializers.RegisterSerializer(TImageSerializer);

  // Test Serializers
  FConfig.GetSerializers.RegisterSerializer(TGUIDSerializerTest);
  FConfig.GetSerializers.RegisterSerializer(TFDDataSetSerializerTest);
end;

procedure TTestCustomSerializers.Setup;
begin
  FData := TDataTests.Create(nil);
  FData.LoadDataSets;
  FConfig := TNeonConfiguration.Create;
end;

procedure TTestCustomSerializers.TearDown;
begin
  FConfig := nil;
  FData.Free;
end;

destructor TJSONValueHolder.Destroy;
begin
  FData.Free;
  FAny.Free;
  inherited;
end;

function JSONValueConfig: INeonConfiguration;
begin
  Result := TNeonConfiguration.Default.SetRaiseExceptions(True);
  Result.GetSerializers.RegisterSerializer(TJSONValueSerializer);
end;

procedure TTestCustomSerializers.TestJSONValueMemberWithoutAnInstance;
var
  LHolder: TJSONValueHolder;
begin
  // The serializer returns a clone of the JSON, so it no longer needs an
  // instance to read into: the member used to be skipped and logged unless
  // AutoCreate or [NeonAutoCreate] had built one for it (A22)
  LHolder := TJSONValueHolder.Create;
  try
    Assert.IsNull(LHolder.Data, 'the member starts nil');

    TNeon.JSONToObject(LHolder, '{"Data":{"a":1}}', JSONValueConfig);

    Assert.IsNotNull(LHolder.Data, 'a nil member must be filled, not skipped');
    Assert.AreEqual('{"a":1}', LHolder.Data.ToJSON);
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestJSONValueMemberTakesAnyKind;
var
  LHolder: TJSONValueHolder;
begin
  // A TJSONValue member takes whatever the document holds, scalars included:
  // only objects and arrays of the exact same class used to work (A22)
  LHolder := TJSONValueHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Any":"abc"}', JSONValueConfig);

    Assert.IsNotNull(LHolder.Any);
    Assert.IsTrue(LHolder.Any is TJSONString, 'a JSON string must arrive as a TJSONString');
    Assert.AreEqual('abc', LHolder.Any.Value);
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestJSONValueMemberReplacesOnASecondRead;
var
  LHolder: TJSONValueHolder;
begin
  // Reading a second document replaces the member: the pairs used to be merged
  // into the instance, so they accumulated (A22)
  LHolder := TJSONValueHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Data":{"a":1}}', JSONValueConfig);
    TNeon.JSONToObject(LHolder, '{"Data":{"b":2}}', JSONValueConfig);

    Assert.AreEqual('{"b":2}', LHolder.Data.ToJSON);
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestJSONValueMemberRefusesAnIncompatibleKind;
var
  LHolder: TJSONValueHolder;
begin
  // A TJSONString cannot be stored in a TJSONObject member: the member is left
  // alone and the error is logged
  LHolder := TJSONValueHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Data":"abc"}', JSONValueConfig);

    Assert.IsNull(LHolder.Data, 'an incompatible kind must not be assigned');
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestJSONValueAsTheOriginalInstance;
var
  LJSON: TJSONObject;
begin
  // JSONToObject<T> creates the instance and discards the deserializer's
  // result, so the serializer has to read into that instance instead of
  // replacing it - replacing would free the object the caller gets back
  LJSON := TNeon.JSONToObject<TJSONObject>('{"a":1}', JSONValueConfig);
  try
    Assert.IsNotNull(LJSON);
    Assert.AreEqual('{"a":1}', LJSON.ToJSON);
  finally
    LJSON.Free;
  end;
end;

procedure TTestCustomSerializers.TestNullableInnerSerializerRoundTrips;
const
  LGUIDText = '{1E2B3C4D-5A6B-7C8D-9E0F-1A2B3C4D5E6F}';
var
  LHolder: TNullableGUIDHolder;
  LConfig: INeonConfiguration;
  LJSON: string;
begin
  // The custom serializer registered for the inner type of a Nullable<T> is used
  // by WriteNullable, so ReadNullable has to use it too: reading it structurally
  // rebuilt the TGUID from its D1..D4 fields, which the JSON string does not have
  LConfig := TNeonConfiguration.Create.SetRaiseExceptions(True);
  LConfig.GetSerializers.RegisterSerializer(TGUIDSerializer);

  LHolder := TNullableGUIDHolder.Create;
  try
    LHolder.Value := StringToGUID(LGUIDText);
    LJSON := TTestUtils.SerializeObject(LHolder, LConfig);
    Assert.AreEqual('{"Value":"1e2b3c4d-5a6b-7c8d-9e0f-1a2b3c4d5e6f"}', LJSON);
  finally
    LHolder.Free;
  end;

  LHolder := TNullableGUIDHolder.Create;
  try
    TTestUtils.DeserializeObject(LJSON, LHolder, LConfig);
    Assert.IsTrue(LHolder.Value.HasValue, 'the Nullable must have a value');
    Assert.AreEqual(LGUIDText, GUIDToString(LHolder.Value.Value));
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestDistanceAlgorithm;
var
  LSerializer: TCustomSerializer;
begin
  RegisterSerializers;
  LSerializer := FConfig.GetSerializers.GetSerializer(TFDMemTable);
  Assert.IsNotNull(LSerializer);
  Assert.AreEqual(TFDDataSetSerializerTest, LSerializer.ClassType);
end;

procedure TTestCustomSerializers.TestSerializerRegistryCount;
begin
  RegisterSerializers;
  Assert.AreEqual(6, FConfig.GetSerializers.Count);
  FConfig.GetSerializers.UnregisterSerializer(TGUIDSerializer);
  Assert.AreEqual(5, FConfig.GetSerializers.Count);
end;

procedure TTestCustomSerializers.TestSelectorAlgorithmOnClass;
var
  LSerializer: TCustomSerializer;
begin
  RegisterSerializers;

  LSerializer := FConfig.GetSerializers.GetSerializer(TypeInfo(TMemoryStream));
  Assert.IsNotNull(LSerializer);
  Assert.AreEqual(TStreamSerializer, LSerializer.ClassType);
end;

procedure TTestCustomSerializers.TestSelectorAlgorithmOnValue;
var
  LSerializer: TCustomSerializer;
begin
  RegisterSerializers;

  LSerializer := FConfig.GetSerializers.GetSerializer(TypeInfo(TGUID));
  Assert.IsNotNull(LSerializer);
  Assert.AreEqual(TGUIDSerializer, LSerializer.ClassType);

  FConfig.GetSerializers.UnregisterSerializer(TGUIDSerializer);

  LSerializer := FConfig.GetSerializers.GetSerializer(TypeInfo(TGUID));
  Assert.IsNotNull(LSerializer);
  Assert.AreEqual(TGUIDSerializerTest, LSerializer.ClassType);
end;

procedure TTestCustomSerializers.TestSelectorUnregister;
var
  LSerializer: TCustomSerializer;
begin
  RegisterSerializers;

  FConfig.GetSerializers.UnregisterSerializer(TGUIDSerializer);

  LSerializer := FConfig.GetSerializers.GetSerializer(TypeInfo(TGUID));
  Assert.IsNotNull(LSerializer);
  Assert.AreEqual(TGUIDSerializerTest, LSerializer.ClassType);
end;

procedure TTestCustomSerializers.TestNilStreamMemberSerializeSkips;
var
  LHolder: TStreamHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Create.SetRaiseExceptions(True);
  LConfig.GetSerializers.RegisterSerializer(TStreamSerializer);
  LHolder := TStreamHolder.Create;
  try
    // A nil object member never reaches the custom serializer:
    // under the default IncludeIf.NotNull it is omitted instead of raising
    Assert.AreEqual('{}', TTestUtils.SerializeObject(LHolder, LConfig));
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestNilStreamMemberDeserializeSkips;
var
  LHolder: TStreamHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Create.SetRaiseExceptions(True);
  LConfig.GetSerializers.RegisterSerializer(TStreamSerializer);
  LHolder := TStreamHolder.Create;
  try
    // An abstract TStream member cannot be created without AutoCreate; the
    // deserializer must skip it (and log) instead of dereferencing nil (A2)
    TTestUtils.DeserializeObject('{"Stream":"aGVsbG8="}', LHolder, LConfig);
    Assert.IsNull(LHolder.Stream);
  finally
    LHolder.Free;
  end;
end;

{ TBoom }

function TBoom.GetExplode: string;
begin
  raise ENeonException.Create('boom');
end;

procedure TTestCustomSerializers.TestNestedErrorPropagatesWhenRaising;
var
  LHolder: TBoomHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Create.SetRaiseExceptions(True);
  LHolder := TBoomHolder.Create;
  try
    LHolder.Boom := TBoom.Create;
    try
      // With RaiseExceptions, an error in a member of a nested object must
      // propagate out of the container writer instead of being swallowed
      // at the WriteObject boundary
      Assert.WillRaise(
        procedure begin TTestUtils.SerializeObject(LHolder, LConfig) end,
        ENeonException);
    finally
      LHolder.Boom.Free;
    end;
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestNestedErrorSwallowedByDefault;
var
  LHolder: TBoomHolder;
begin
  LHolder := TBoomHolder.Create;
  try
    LHolder.Boom := TBoom.Create;
    try
      // With the default RaiseExceptions=False the failing member is
      // dropped and the nested object degrades to {} (no exception)
      Assert.AreEqual('{"Boom":{}}',
        TTestUtils.SerializeObject(LHolder, TNeonConfiguration.Default));
    finally
      LHolder.Boom.Free;
    end;
  finally
    LHolder.Free;
  end;
end;

procedure TTestCustomSerializers.TestAssignDoesNotShareInstances;
var
  LSource, LTarget: TNeonSerializerRegistry;
  LSourceSerializer, LTargetSerializer: TCustomSerializer;
begin
  LSource := TNeonSerializerRegistry.Create;
  LTarget := TNeonSerializerRegistry.Create;
  try
    LSource.RegisterSerializer(TGUIDSerializer);
    LTarget.Assign(LSource);

    // Each registry owns its own cached serializer instances; sharing them
    // between two value-owning caches would free the same instance twice
    LSourceSerializer := LSource.GetSerializer(TypeInfo(TGUID));
    LTargetSerializer := LTarget.GetSerializer(TypeInfo(TGUID));
    Assert.IsFalse(LSourceSerializer = LTargetSerializer);

    // The merged class list still resolves types registered in the source
    Assert.IsNotNull(LTarget.GetSerializer(TypeInfo(TGUID)));
    Assert.AreEqual(TGUIDSerializer, LTargetSerializer.ClassType);
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestCustomSerializers.TestRegisterInvalidatesCache;
begin
  FConfig.GetSerializers.Clear;

  // Resolve a derived dataset type with only the base serializer registered:
  // this populates the instance cache with TDataSetSerializer
  FConfig.GetSerializers.RegisterSerializer(TDataSetSerializer);
  Assert.AreEqual(TDataSetSerializer,
    FConfig.GetSerializers.GetSerializer(TFDMemTable).ClassType);

  // Registering a more-specific serializer afterwards must invalidate the
  // cached resolution, otherwise the stale instance keeps being returned
  FConfig.GetSerializers.RegisterSerializer(TFDDataSetSerializerTest);
  Assert.AreEqual(TFDDataSetSerializerTest,
    FConfig.GetSerializers.GetSerializer(TFDMemTable).ClassType);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCustomSerializers);

end.
