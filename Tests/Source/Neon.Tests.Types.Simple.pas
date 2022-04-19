{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2022 Paolo Rossi                                         }
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
unit Neon.Tests.Types.Simple;

interface

uses
  System.Rtti, DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('simpletypes')]
  TTestSimpleTypesSer = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIntegerPos', '42,42')]
    [TestCase('TestIntegerZero', '0,0')]
    [TestCase('TestIntegerNeg', '-42,-42')]
    procedure TestInteger(const AValue: Integer; _Result: string);

    [Test]
    [TestCase('TestByte', '42,42')]
    [TestCase('TestByteLimit', '255,255')]
    [TestCase('TestByteZero', '0,0')]
    procedure TestByte(const AValue: Byte; _Result: string);

    [Test]
    [TestCase('TestString', 'Lorem "Ipsum" \n \\ {}')]
    procedure TestString(const AValue: string);

    [Test]
    [TestCase('TestFloatPos', '123.42,123.42')]
    [TestCase('TestFloatNull', '0.0,0')]
    [TestCase('TestFloatNeg', '-123.42,-123.42')]
    procedure TestFloat(const AValue: Double; _Result: string);

    [Test]
    [TestCase('TestBoolTrue', 'True,True')]
    [TestCase('TestBoolFalse', 'False,False')]
    procedure TestBoolean(const AValue: Boolean; _Result: string);

    [Test]
    [TestCase('TestDateOnly', '23/12/2019,"2019-12-23T00:00:00.000Z"')]
    [TestCase('TestDateTime', '23/12/2019 01:01:01,"2019-12-23T01:01:01.000Z"')]
    [TestCase('TestTimeOnly', '01:01:01,"1899-12-30T01:01:01.000Z"')]
    procedure TestDateTime(const AValue: TDateTime; _Result: string);

  end;

  [TestFixture]
  [Category('simpletypes')]
  TTestSimpleTypesDes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIntegerPos', '42,42')]
    [TestCase('TestIntegerZero', '0,0')]
    [TestCase('TestIntegerNeg', '-42,-42')]
    procedure TestInteger(const AValue: string; _Result: Integer);

    [Test]
    [TestCase('TestByte', '42,42')]
    [TestCase('TestByteLimit', '255,255')]
    [TestCase('TestByteZero', '0,0')]
    procedure TestByte(const AValue: string; _Result: Byte);

    [Test]
    [TestCase('TestShortIntRangeSup', '128')]
    [TestCase('TestShortIntRangeInf', '-129')]
    procedure TestShortIntRange(const AValue: string);

    [Test]
    [TestCase('TestByteRangeSup', '256')]
    [TestCase('TestByteRangeInf', '-1')]
    procedure TestByteRange(const AValue: string);

    [Test]
    [TestCase('TestSmallIntRangeSup', '32768')]
    [TestCase('TestSmallIntRangeInf', '-32769')]
    procedure TestSmallIntRange(const AValue: string);

    [Test]
    [TestCase('TestWordRangeSup', '65536')]
    [TestCase('TestWordRangeInf', '-1')]
    procedure TestWordRange(const AValue: string);

    [Test]
    [TestCase('TestIntegerRangeSup', '2147483648')]
    [TestCase('TestIntegerRangeInf', '-2147483649')]
    procedure TestIntegerRange(const AValue: string);

    [Test]
    [TestCase('TestCardinalRangeSup', '4294967296')]
    [TestCase('TestCardinalRangeInf', '-1')]
    procedure TestCardinalRange(const AValue: string);

    [Test]
    [TestCase('TestString', '"Lorem \"Ipsum\" \\n \\\\ {}",Lorem "Ipsum" \n \\ {}')]
    procedure TestString(const AValue, _Result: string);

    [Test]
    [TestCase('TestFloatPos', '123.42,123.42')]
    [TestCase('TestFloatNull', '0.0,0')]
    [TestCase('TestFloatNeg', '-123.42,-123.42')]
    procedure TestFloat(const AValue: string; _Result: Double);

    [Test]
    [TestCase('TestBoolTrue', 'true,True')]
    [TestCase('TestBoolFalse', 'false,False')]
    procedure TestBoolean(const AValue: string; _Result: Boolean);

    [Test]
    [TestCase('TestDateOnly', '"2019-12-23T00:00:00.000Z", 23/12/2019')]
    [TestCase('TestDateTime', '"2019-12-23T01:01:01.000Z", 23/12/2019 01:01:01')]
    [TestCase('TestTimeOnly', '"1899-12-30T01:01:01.000Z", 01:01:01')]
    procedure TestDateTime(const AValue: string; _Result: TDateTime);

  end;

implementation

procedure TTestSimpleTypesSer.Setup;
begin
end;

procedure TTestSimpleTypesSer.TearDown;
begin
end;

procedure TTestSimpleTypesSer.TestBoolean(const AValue: Boolean; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestByte(const AValue: Byte; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestDateTime(const AValue: TDateTime; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TDateTime>(AValue)));
end;

procedure TTestSimpleTypesSer.TestFloat(const AValue: Double; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestInteger(const AValue: Integer; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestString(const AValue: string);
begin
  Assert.AreEqual('"Lorem \"Ipsum\" \\n \\\\ {}"', TTestUtils.SerializeValue(AValue));
end;

{ TTestSimpleTypesDes }

procedure TTestSimpleTypesDes.Setup;
begin

end;

procedure TTestSimpleTypesDes.TearDown;
begin

end;

procedure TTestSimpleTypesDes.TestBoolean(const AValue: string; _Result: Boolean);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Boolean>(AValue));
end;

procedure TTestSimpleTypesDes.TestByte(const AValue: string; _Result: Byte);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Byte>(AValue));
end;

procedure TTestSimpleTypesDes.TestByteRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Byte>(AValue) end,
    ENeonException
  );
end;

procedure TTestSimpleTypesDes.TestCardinalRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Cardinal>(AValue) end,
    ENeonException
  );
end;

procedure TTestSimpleTypesDes.TestDateTime(const AValue: string; _Result: TDateTime);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<TDateTime>(AValue));
end;

procedure TTestSimpleTypesDes.TestFloat(const AValue: string; _Result: Double);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Double>(AValue));
end;

procedure TTestSimpleTypesDes.TestInteger(const AValue: string; _Result: Integer);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Integer>(AValue));
end;

procedure TTestSimpleTypesDes.TestIntegerRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Integer>(AValue) end,
    ENeonException
  )
end;

procedure TTestSimpleTypesDes.TestShortIntRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<ShortInt>(AValue) end,
    ENeonException
  );
end;

procedure TTestSimpleTypesDes.TestSmallIntRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<SmallInt>(AValue) end,
    ENeonException
  );
end;

procedure TTestSimpleTypesDes.TestString(const AValue, _Result: string);
var
  s: string;
begin
  s := TTestUtils.DeserializeValueTo<string>(AValue);
  Assert.AreEqual(_Result, s);
end;

procedure TTestSimpleTypesDes.TestWordRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Word>(AValue) end,
    ENeonException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSimpleTypesSer);

end.
