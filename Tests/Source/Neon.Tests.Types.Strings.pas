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
unit Neon.Tests.Types.Strings;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

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
