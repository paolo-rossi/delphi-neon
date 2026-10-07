{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Exceptions;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('exceptions')]
  TTestExceptionTypes = class(TObject)
  public
    [Test]
    procedure TestExceptionSerializes;
  end;

implementation

{ TTestExceptionTypes }

procedure TTestExceptionTypes.TestExceptionSerializes;
var
  LException: Exception;
begin
  // BaseException reads back the instance it belongs to: the guard must omit it
  // instead of recursing, leaving the other members in the document
  LException := Exception.CreateHelp('boom', 42);
  try
    Assert.AreEqual('{"HelpContext":42,"Message":"boom","StackTrace":""}',
      TTestUtils.SerializeObject(LException));
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestExceptionTypes);

end.
