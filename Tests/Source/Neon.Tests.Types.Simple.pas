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
unit Neon.Tests.Types.Simple;

interface

//{$R+,O+}

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('simpletypes')]
  TTestSimpleTypesSer = class(TObject)
  private
    JSONFormatSettings: TFormatSettings;
  public
    constructor Create;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIntegerPos', '42,42')]
    [TestCase('TestIntegerZero', '0,0')]
    [TestCase('TestIntegerNeg', '-42,-42')]
    [TestCase('TestIntegerSup', '2147483647,2147483647')]
    [TestCase('TestIntegerInf', '-2147483648,-2147483648')]
    procedure TestInteger(const AValue: Integer; _Result: string);

    [Test]
    [TestCase('TestInt64Pos', '42,42')]
    [TestCase('TestInt64Zero', '0,0')]
    [TestCase('TestInt64Neg', '-42,-42')]
    [TestCase('TestInt64Sup', '9223372036854775807,9223372036854775807')]
    [TestCase('TestInt64Inf', '-9223372036854775808,-9223372036854775808')]
    procedure TestIn64(const AValue: Int64; _Result: string);

    [Test]
    [TestCase('TestUInt64Pos', '42,42')]
    [TestCase('TestUInt64Zero', '0,0')]
    [TestCase('TestUInt64Int', '2147483647,2147483647')]
    //[TestCase('TestUInt64Sup', '18446744073709551615,18446744073709551615')]
    procedure TestUIn64(const AValue: UInt64; _Result: string);

    [Test]
    procedure TestUIn64Sup;

    [Test]
    [TestCase('TestByte', '42,42')]
    [TestCase('TestByteLimit', '255,255')]
    [TestCase('TestByteZero', '0,0')]
    procedure TestByte(const AValue: Byte; _Result: string);

    [Test]
    [TestCase('TestString', 'Lorem "Ipsum" \n \\ {}')]
    procedure TestString(const AValue: string);

    [Test]
    [TestCase('TestSinglePos', '123.42,123.42')]
    [TestCase('TestSingleNull', '0.0,0')]
    [TestCase('TestSingleNeg', '-123.42,-123.42')]
    [TestCase('TestSingleSup', '3.40E38,3.40E38')]
    procedure TestSingle(const AValue: Single; _Result: string);

    [Test]
    [TestCase('TestDoublePos', '123.42,123.42')]
    [TestCase('TestDoubleNull', '0.0,0')]
    [TestCase('TestDoubleNeg', '-123.42,-123.42')]
    [TestCase('TestDoubleSup', '1.79E308,1.79E308')]
    procedure TestDouble(const AValue: Double; _Result: string);

    [Test]
    [TestCase('TestNumExponentLower', '1.1232e2,112.32')]
    [TestCase('TestNumExponentLowerPlus', '1.1232e+2,112.32')]
    [TestCase('TestNumExponentLowerMinus', '1.1232e-2,0.011232')]
    [TestCase('TestNumExponentUpper', '1.1232E2,112.32')]
    [TestCase('TestNumExponentUpperPlus', '1.1232E+2,112.32')]
    [TestCase('TestNumExponentUpperPlus', '1.1232E-2,0.011232')]
    procedure TestNumExponent(const AValue: Double; _Result: string);

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
    [TestCase('TestByte', '42,42')]
    [TestCase('TestByteLimit', '255,255')]
    [TestCase('TestByteZero', '0,0')]
    procedure TestByte(const AValue: string; _Result: Byte);

    [Test]
    [TestCase('TestIntegerPos', '42,42')]
    [TestCase('TestIntegerZero', '0,0')]
    [TestCase('TestIntegerNeg', '-42,-42')]
    procedure TestInteger(const AValue: string; _Result: Integer);

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
    [TestCase('TestSinglePos', '123.42,123.42')]
    [TestCase('TestSingleNull', '0.0,0')]
    [TestCase('TestSingleNeg', '-123.42,-123.42')]
    [TestCase('TestSingleSup', '3.40E38,3.40E38')]
    [TestCase('TestSingleInf', '-3.40E38,-3.40E38')]
    procedure TestSingle(const AValue: string; _Result: Single);

    [Test]
    [TestCase('TestSingleRangeSup', '3.41E38')]
    [TestCase('TestSingleRangeInf', '-3.41E38')]
    procedure TestSingleRange(const AValue: string);

    [Test]
    [TestCase('TestDoublePos', '123.42,123.42')]
    [TestCase('TestDoubleNull', '0.0,0')]
    [TestCase('TestDoubleNeg', '-123.42,-123.42')]
    [TestCase('TestDoubleSup', '1.79E308,1.79E308')]
    procedure TestDouble(const AValue: string; _Result: Double);

    [Test]
    [TestCase('TestDoubleRangeSup', '1.80e+308')]
    [TestCase('TestDoubleRangeInf', '-1.80e+308')]
    procedure TestDoubleRange(const AValue: string);

    [Test]
    [TestCase('TestNumExponentLower', '1.1232e2,1.1232e2')]
    [TestCase('TestNumExponentLowerPlus', '1.1232e+2,1.1232e+2')]
    [TestCase('TestNumExponentLowerMinus', '1.1232e-2,1.1232e-2')]
    [TestCase('TestNumExponentUpper', '1.1232E2,1.1232E2')]
    [TestCase('TestNumExponentUpperPlus', '1.1232E+2,1.1232E+2')]
    [TestCase('TestNumExponentUpperPlus', '1.1232E-2,1.1232E-2')]
    procedure TestNumExponent(const AValue: string; _Result: Double);

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

constructor TTestSimpleTypesSer.Create;
begin
  JSONFormatSettings := TFormatSettings.Create('us');
  FormatSettings.ShortDateFormat := 'dd/mm/yyyy'; // need to explicitly specify this format so the TestCase attributes correctly pass the second value as hard-coded in the attribute.
end;

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

procedure TTestSimpleTypesSer.TestDouble(const AValue: Double; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestIn64(const AValue: Int64; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestInteger(const AValue: Integer; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestNumExponent(const AValue: Double; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestSingle(const AValue: Single; _Result: string);
var
  LResult: Single;
  LExpected: Single;
begin
  LResult := StrToFloat(TTestUtils.SerializeValue(AValue), JSONFormatSettings);
  LExpected := StrToFloat(_Result, JSONFormatSettings);
  Assert.AreEqual(LResult, LExpected, 0.000001);
end;

procedure TTestSimpleTypesSer.TestString(const AValue: string);
begin
  Assert.AreEqual('"Lorem \"Ipsum\" \\n \\\\ {}"', TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestUIn64(const AValue: UInt64; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypesSer.TestUIn64Sup;
var
  LNum: UInt64;
  LStr: string;
begin
  LNum := 18446744073709551615;
  LStr := '18446744073709551615';
  Assert.AreEqual(LStr, TTestUtils.SerializeValue(LNum));
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

procedure TTestSimpleTypesDes.TestDouble(const AValue: string; _Result: Double);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Double>(AValue));
end;

procedure TTestSimpleTypesDes.TestDoubleRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Single>(AValue) end,
    ENeonException
  );
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
  );
end;

procedure TTestSimpleTypesDes.TestNumExponent(const AValue: string; _Result: Double);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Double>(AValue));
end;

procedure TTestSimpleTypesDes.TestShortIntRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<ShortInt>(AValue) end,
    ENeonException
  );
end;

procedure TTestSimpleTypesDes.TestSingle(const AValue: string; _Result: Single);
begin
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<Single>(AValue));
end;

procedure TTestSimpleTypesDes.TestSingleRange(const AValue: string);
begin
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<Single>(AValue) end,
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
  LResult: string;
begin
  LResult := TTestUtils.DeserializeValueTo<string>(AValue);
  Assert.AreEqual(_Result, LResult);
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
