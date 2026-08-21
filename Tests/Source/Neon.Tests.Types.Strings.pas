{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Strings;

interface

uses
  System.SysUtils, System.Rtti, System.JSON, DUnitX.TestFramework,

  Neon.Core.Persistence.JSON,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  TStringArray = TArray<string>;
  TIntegerArray = TArray<Integer>;

  [TestFixture]
  [Category('stringtypes')]
  TTestStringsTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestAnsiNormal', 'Paolo,"Paolo"')]
    [TestCase('TestAnsiEmpty', ',""')]
    [TestCase('TestAnsiSpace', ' ," "')]
    [TestCase('TestAnsiExtended', 'Cantù,"Cant\u00F9"')]
    procedure TestAnsiString(const AValue: AnsiString; const _Result: string);

    [Test]
    [TestCase('TestUnicodeNormal', 'Paolo,"Paolo"')]
    [TestCase('TestUnicodeEmpty', ',""')]
    [TestCase('TestUnicodeSpace', ' ," "')]
    [TestCase('TestUnicodeExtended', 'Cantù,"Cant\u00F9"')]
    procedure TestUnicodeString(const AValue: string; const _Result: string);

    [Test]
    [TestCase('TestUTF8Normal', 'Paolo,"Paolo"')]
    [TestCase('TestUTF8Empty', ',""')]
    [TestCase('TestUTF8Space', ' ," "')]
    [TestCase('TestUTF8Extended', 'Cantù,"Cant\u00F9"')]
    procedure TestUTF8String(const AValue: UTF8String; const _Result: string);

    [Test]
    procedure TestPrettyPrintStringEndingWithBackslash;

    [Test]
    procedure TestPrettyPrintStringWithEscapedQuote;
  end;

implementation

uses
  System.DateUtils;

procedure TTestStringsTypes.Setup;
begin
end;

procedure TTestStringsTypes.TearDown;
begin
end;

procedure TTestStringsTypes.TestAnsiString(const AValue: AnsiString; const _Result: string);
var
  LResult: string;
begin
  LResult := TTestUtils.SerializeValue(TValue.From<AnsiString>(AValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestStringsTypes.TestPrettyPrintStringEndingWithBackslash;
var
  LJSON: TJSONValue;
begin
  // The quote that closes "C:\\" is preceded by a backslash but is not escaped
  // by it: the pretty printer used to read it as string content and leave the
  // rest of the document unformatted
  LJSON := TJSONObject.ParseJSONValue('{"path":"C:\\","n":1}');
  try
    Assert.AreEqual(
      '{' + sLineBreak +
      '  "path": "C:\\",' + sLineBreak +
      '  "n": 1' + sLineBreak +
      '}',
      TNeon.Print(LJSON, True));
  finally
    LJSON.Free;
  end;
end;

procedure TTestStringsTypes.TestPrettyPrintStringWithEscapedQuote;
var
  LJSON: TJSONValue;
begin
  // The other half of the same rule: a single backslash does escape the quote
  // that follows it, so the comma inside the string is not a separator
  LJSON := TJSONObject.ParseJSONValue('{"q":"a \"b\", c","n":1}');
  try
    Assert.AreEqual(
      '{' + sLineBreak +
      '  "q": "a \"b\", c",' + sLineBreak +
      '  "n": 1' + sLineBreak +
      '}',
      TNeon.Print(LJSON, True));
  finally
    LJSON.Free;
  end;
end;

procedure TTestStringsTypes.TestUnicodeString(const AValue: string; const _Result: string);
var
  LResult: string;
begin
  LResult := TTestUtils.SerializeValue(TValue.From<string>(AValue));
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestStringsTypes.TestUTF8String(const AValue: UTF8String; const _Result: string);
var
  LResult: string;
begin
  LResult := TTestUtils.SerializeValue(TValue.From<UTF8String>(AValue));
  Assert.AreEqual(_Result, LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStringsTypes);

end.
