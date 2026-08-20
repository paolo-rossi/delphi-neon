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
  System.Classes, System.Rtti, DUnitX.TestFramework,

  FireDAC.Comp.DataSet, FireDAC.Comp.Client,

  Neon.Core.Persistence,
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

  end;

implementation

uses
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
    // A nil object member never reaches the custom serializer (review A2):
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

initialization
  TDUnitX.RegisterTestFixture(TTestCustomSerializers);

end.
