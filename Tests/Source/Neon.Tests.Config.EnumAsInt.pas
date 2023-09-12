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
unit Neon.Tests.Config.EnumAsInt;

interface

uses
  System.Classes, DUnitX.TestFramework,

  Neon.Core.Types;

type
  [TestFixture]
  [Category('enumasint')]
  TTestConfigEnumAsInt = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestTDuplicates', '1,dupAccept')]
    procedure TestDeserialize(const AValue: String; _Result: TDuplicates);

    [Test]
    [TestCase('TestTDuplicates', 'dupAccept,1')]
    procedure TestSerialize(const AValue: TDuplicates; _Result: string);

    [Test]
    [TestCase('TestTDuplicates', '3,dupAccept')]
    [TestCase('TestTDuplicates', '-1,dupError')]
    procedure TestReadOutOfBounds(const AValue: String; _Result: TDuplicates);

  end;

implementation

uses
  System.Rtti, Neon.Tests.Utils, Neon.Core.Persistence;

{ TTestConfigEnumAsInt }

procedure TTestConfigEnumAsInt.Setup;
begin
end;

procedure TTestConfigEnumAsInt.TearDown;
begin
end;

procedure TTestConfigEnumAsInt.TestDeserialize(const AValue: String; _Result: TDuplicates);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<TDuplicates>(AValue, lConfig));
end;

procedure TTestConfigEnumAsInt.TestSerialize(const AValue: TDuplicates; _Result: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TDuplicates>(aValue), LConfig));
end;

procedure TTestConfigEnumAsInt.TestReadOutOfBounds(const AValue: String; _Result: TDuplicates);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<TDuplicates>(AValue, lConfig) end,
    ENeonException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigEnumAsInt);

end.
