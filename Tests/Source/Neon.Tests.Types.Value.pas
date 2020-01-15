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
unit Neon.Tests.Types.Value;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  TStringArray = TArray<string>;
  TIntegerArray = TArray<Integer>;

  [TestFixture]
  [Category('valuetypes')]
  TTestValueTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRecord;

    [Test]
    procedure TestArrayInteger;

    [Test]
    procedure TestMatrixInteger;

    [Test]
    procedure TestMatrixIntegerString;
  end;

implementation

uses
  System.DateUtils;

procedure TTestValueTypes.Setup;
begin
end;

procedure TTestValueTypes.TearDown;
begin
end;

procedure TTestValueTypes.TestArrayInteger;
const
  LExpected = '[0,-10,20,-30,42]';
var
  LValue: TArray<Integer>;
  LResult: string;
begin
  LValue := [0,-10,20,-30,42];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<Integer>>(LValue));
  Assert.AreEqual(LExpected, LResult);
end;

procedure TTestValueTypes.TestMatrixInteger;
const
  LExpected = '[[0,1,2,3],[-10,22,1230000000],[20,-30,42],[]]';
var
  LValue: TArray<TIntegerArray>;
  LResult: string;
begin
  LValue := [[0,1,2,3], [-10,22,1230000000], [20,-30,42], []];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TIntegerArray>>(LValue));
  Assert.AreEqual(LExpected, LResult);
end;

procedure TTestValueTypes.TestMatrixIntegerString;
const
  LExpected = '[["Zero","Uno","Due"],["","\u00E7\u00B0\u00E8\u00E9"],[]]';
var
  LValue: TArray<TStringArray>;
  LResult: string;
begin
  LValue := [['Zero','Uno','Due'], ['', 'η°θι'],[]];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TStringArray>>(LValue));
  Assert.AreEqual(LExpected, LResult);
end;

procedure TTestValueTypes.TestRecord;
const
  LExpected = '{"Name":"Paolo","BirthDate":"1969-10-02T03:00:00.000Z","Age":50}';
var
  LValue: TSimpleRecord;
  LResult: string;
begin
  LValue.Name := 'Paolo';
  LValue.BirthDate := EncodeDateTime(1969, 10, 02, 03, 0, 0, 0);
  LValue.Age := 50;
  LResult := TTestUtils.SerializeValue(TValue.From<TSimpleRecord>(LValue));
  Assert.AreEqual(LExpected, LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestValueTypes);

end.
