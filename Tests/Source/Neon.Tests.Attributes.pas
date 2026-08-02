{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Attributes;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('attrinclude')]
  TTestAttributesInclude = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIncludeIfAlways(const AMethod: string);
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

constructor TTestAttributesInclude.Create;
begin

end;

destructor TTestAttributesInclude.Destroy;
begin

  inherited;
end;

procedure TTestAttributesInclude.Setup;
begin
end;

procedure TTestAttributesInclude.TearDown;
begin
end;

procedure TTestAttributesInclude.TestIncludeIfAlways(const AMethod: string);
begin

end;

initialization
  TDUnitX.RegisterTestFixture(TTestAttributesInclude);

end.
