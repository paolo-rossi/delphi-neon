{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Bytes;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils,
  Neon.Data.Tests;

type
  [TestFixture]
  [Category('bytestypes')]
  TTestBytesTypesSer = class(TObject)
  public
    // Bytes Tests
    [Test]
    [TestCase('TestBytes', '[5,12,6,55,30]|"BQwGNx4="', '|')]
    [TestCase('TestBytesZero', '[0,0,0,0,0,0]|"AAAAAAAA"', '|')]
    [TestCase('TestBytesMax', '[255,255,255,255,255,255]|"////////"', '|')]
    [TestCase('TestBytesEmpty', '[]|""', '|')]
    procedure TestBytes(AInput: TBytes; _Result: string);

    [TestCase('TestBytesRec', '[5,12,6,55,30]|{"Bytes":"BQwGNx4=","ByteArray":[5,12,6,55,30]}', '|')]
    procedure TestBytesRec(AInput: TBytes; _Result: string);
  end;



implementation

uses
  Neon.Core.Serializers.RTL,
  Neon.Serializers.Tests;

{ TTestBytesTypesSer }

procedure TTestBytesTypesSer.TestBytes(AInput: TBytes; _Result: string);
var
  LResult: string;
  LConf: INeonConfiguration;
begin
  LConf := TNeonConfiguration.Default;
  LConf.GetSerializers.RegisterSerializer(TBytesSerializer);
  LResult := TTestUtils.SerializeValue(TValue.From<TBytes>(AInput), LConf);

  Assert.AreEqual(_Result, LResult);
end;

procedure TTestBytesTypesSer.TestBytesRec(AInput: TBytes; _Result: string);
var
  LResult: string;
  LRec: TBytes64Rec;
  LConf: INeonConfiguration;
begin
  LConf := TNeonConfiguration.Default;
  LConf.GetSerializers.RegisterSerializer(TBytesSerializer);
  LRec.Bytes := AInput;
  LRec.ByteArray := AInput;

  LResult := TTestUtils.SerializeValue(TValue.From<TBytes64Rec>(LRec), LConf);
  Assert.AreEqual(_Result, LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBytesTypesSer);

end.
