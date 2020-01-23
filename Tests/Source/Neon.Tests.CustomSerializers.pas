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

initialization
  TDUnitX.RegisterTestFixture(TTestCustomSerializers);

end.
