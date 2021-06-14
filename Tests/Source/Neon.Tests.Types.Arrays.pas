{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2021 Paolo Rossi                                         }
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
unit Neon.Tests.Types.Arrays;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  TStringArray = TArray<string>;
  TIntegerArray = TArray<Integer>;

  [TestFixture]
  [Category('arraytypes')]
  TTestArrayTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestManagedRecord', '[0,-10,20,-30,42]', '|')]
    procedure TestArrayInteger(_Result: string);

    [Test]
    [TestCase('TestManagedRecord', '[[0,1,2,3],[-10,22,1230000000],[20,-30,42],[]]', '|')]
    procedure TestMatrixInteger(_Result: string);

    [Test]
    [TestCase('TestManagedRecord', '[["Zero","Uno","Due"],["","\u00E7\u00B0\u00E8\u00E9"],[]]', '|')]
    procedure TestMatrixIntegerString(_Result: string);
  end;

implementation

uses
  System.DateUtils;

procedure TTestArrayTypes.Setup;
begin
end;

procedure TTestArrayTypes.TearDown;
begin
end;

procedure TTestArrayTypes.TestArrayInteger(_Result: string);
var
  LValue: TArray<Integer>;
  LResult: string;
begin
  LValue := [0,-10,20,-30,42];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<Integer>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypes.TestMatrixInteger(_Result: string);
var
  LValue: TArray<TIntegerArray>;
  LResult: string;
begin
  LValue := [[0,1,2,3], [-10,22,1230000000], [20,-30,42], []];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TIntegerArray>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypes.TestMatrixIntegerString(_Result: string);
var
  LValue: TArray<TStringArray>;
  LResult: string;
begin
  LValue := [['Zero','Uno','Due'], ['', 'η°θι'],[]];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TStringArray>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestArrayTypes);

end.
