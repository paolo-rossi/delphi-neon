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
unit Neon.Tests.Types.Arrays;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  // Dynamic Arrays
  TStringDynArray = TArray<string>;
  TIntegerDynArray = TArray<Integer>;

  // Static Arrays
  TIntegerArray = array [0..4] of Integer;
  TContactArray = array [0..1] of TContact;

  [TestFixture]
  [Category('arraytypes')]
  TTestArrayTypesSer = class(TObject)
  public
    // Static Array Tests
    [Test]
    [TestCase('TestArrayInteger', '[0,10,-2,12344545,30]', '|')]
    procedure TestArrayInteger(_Result: string);

    [Test]
    [TestCase('TestArrayContacts', '[{"ContactType":"Phone","Number":"123456789"},{"ContactType":"Skype","Number":"987654321"}]', '|')]
    procedure TestArrayContacts(_Result: string);

    // Dynamic Array Tests
    [Test]
    [TestCase('TestDynArrayInteger', '[0,-10,20,-30,42]', '|')]
    procedure TestDynArrayInteger(_Result: string);

    [Test]
    [TestCase('TestDynMatrixInteger', '[[0,1,2,3],[-10,22,1230000000],[20,-30,42],[]]', '|')]
    procedure TestDynMatrixInteger(_Result: string);

    [Test]
    [TestCase('TestDynMatrixIntegerString', '[["Zero","Uno","Due"],["","\u00E7\u00B0\u00E8\u00E9"],[]]', '|')]
    procedure TestDynMatrixIntegerString(_Result: string);
  end;


  [TestFixture]
  [Category('arraytypes')]
  TTestArrayTypesDes = class(TObject)
  public
    [Test]
    [TestCase('TestArrayInteger', '[0,10,-2,12344545,30]|[0,10,-2,12344545,30]', '|')]
    procedure TestArrayInteger(const AValue: string; _Result: TIntegerDynArray);
  end;


implementation

uses
  System.DateUtils;

procedure TTestArrayTypesSer.TestArrayContacts(_Result: string);
var
  LContact: TContact;
  LValue: TContactArray;
  LResult: string;
begin
  LValue[0] := TContact.Create;
  LValue[0].ContactType := TContactType.Phone;
  LValue[0].Number := '123456789';

  LValue[1] := TContact.Create;
  LValue[1].ContactType := TContactType.Skype;
  LValue[1].Number := '987654321';
  try
    LResult := TTestUtils.SerializeValue(TValue.From<TContactArray>(LValue));
  finally
    for LContact in LValue do
      LContact.Free;
  end;
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypesSer.TestArrayInteger(_Result: string);
var
  LValue: TIntegerArray;
  LResult: string;
begin
  //'[0,10,-2,12344545,30]'
  LValue[0] := 0;
  LValue[1] := 10;
  LValue[2] := -2;
  LValue[3] := 12344545;
  LValue[4] := 30;
  LResult := TTestUtils.SerializeValue(TValue.From<TIntegerArray>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypesSer.TestDynArrayInteger(_Result: string);
var
  LValue: TArray<Integer>;
  LResult: string;
begin
  LValue := [0,-10,20,-30,42];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<Integer>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypesSer.TestDynMatrixInteger(_Result: string);
var
  LValue: TArray<TIntegerDynArray>;
  LResult: string;
begin
  LValue := [[0,1,2,3], [-10,22,1230000000], [20,-30,42], []];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TIntegerDynArray>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestArrayTypesSer.TestDynMatrixIntegerString(_Result: string);
var
  LValue: TArray<TStringDynArray>;
  LResult: string;
begin
  LValue := [['Zero','Uno','Due'], ['', 'η°θι'],[]];
  LResult := TTestUtils.SerializeValue(TValue.From<TArray<TStringDynArray>>(LValue));
  Assert.AreEqual(_Result, LResult);
end;

{ TTestArrayTypesDes }

procedure TTestArrayTypesDes.TestArrayInteger(const AValue: string; _Result: TIntegerDynArray);
var
  LRes: TIntegerArray;
  LIndex: Integer;
begin
  LRes := TTestUtils.DeserializeValueTo<TIntegerArray>(AValue);

  for LIndex := 0 to Length(_Result) - 1 do
    Assert.AreEqual(_Result[LIndex], LRes[LIndex]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestArrayTypesSer);
  TDUnitX.RegisterTestFixture(TTestArrayTypesDes);

end.
