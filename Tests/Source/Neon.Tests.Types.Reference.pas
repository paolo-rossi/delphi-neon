{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Reference;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('reftypes')]
  TTestReferenceTypes = class(TObject)
  private
    FDataPath: string;
    FPerson1: TPerson;
    FPerson2: TPerson;

    function GetFileName(const AMethod: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestPersonAnsi', 'TestPersonAnsi')]
    procedure TestPersonAnsi(const AMethod: string);

    [Test]
    [TestCase('TestPersonUnicode', 'TestPersonUnicode')]
    procedure TestPersonUnicode(const AMethod: string);

    [Test]
    [TestCase('TestPersonPretty', 'TestPersonPretty')]
    procedure TestPersonPretty(const AMethod: string);

    [Test]
    [TestCase('TestPersonNil', 'TestPersonNil')]
    procedure TestPersonNil(const AMethod: string);

  end;

implementation

uses
  System.IOUtils, System.DateUtils;

constructor TTestReferenceTypes.Create;
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FPerson1 := TPerson.Create('Paolo', 50);
  FPerson1.AddAddress('Via Trento, 30', 'Parma', 'Italy', True);
  FPerson1.AddContact(TContactType.Phone, '+39.123.4567890');
  FPerson1.AddContact(TContactType.Email, 'paolo@mail.com');

  FPerson2 := TPerson.Create('', -0);
  FPerson2.AddAddress('Via Москва 334', 'Москва', 'Россия', True);
  FPerson2.AddContact(TContactType.Phone, '+39.123.4567890');
  FPerson2.AddContact(TContactType.Email, 'paolo@mail.com');
end;

destructor TTestReferenceTypes.Destroy;
begin
  FPerson1.Free;
  FPerson2.Free;

  inherited;
end;

function TTestReferenceTypes.GetFileName(const AMethod: string): string;
begin
  Result := TPath.Combine(FDataPath, ClassName + '.' + AMethod + '.json');
end;

procedure TTestReferenceTypes.Setup;
begin
end;

procedure TTestReferenceTypes.TearDown;
begin
end;

procedure TTestReferenceTypes.TestPersonAnsi(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson1));
end;

procedure TTestReferenceTypes.TestPersonNil(const AMethod: string);
begin
  Assert.AreEqual('{}',
    TTestUtils.SerializeObject(nil, TNeonConfiguration.Default));
end;

procedure TTestReferenceTypes.TestPersonPretty(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson1, TNeonConfiguration.Pretty));
end;

procedure TTestReferenceTypes.TestPersonUnicode(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson2));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestReferenceTypes);

end.
