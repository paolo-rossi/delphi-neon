{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.AutoCreate;

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
  [Category('autocreate')]
  TTestAutoCreate = class(TObject)
  private
    FDataPath: string;
    FNotCreated: TAutoCreateClass;
    FAlreadyCreated: TAutoCreateClass;

    function GetFileName(const AName: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestNotCreated', 'False,False')]
    [TestCase('TestNotCreated', 'False,True')]
    [TestCase('TestNotCreated', 'True,False')]
    [TestCase('TestNotCreated', 'True,True')]
    procedure TestNotCreated(ASubObject, AAutoCreate: Boolean);

    //[Test]
    //[TestCase('TestAlreadyCreated', 'TestAlreadyCreated')]
    [TestCase('TestAlreadyCreated', 'False,False')]
    [TestCase('TestAlreadyCreated', 'False,True')]
    [TestCase('TestAlreadyCreated', 'True,False')]
    [TestCase('TestAlreadyCreated', 'True,True')]
    procedure TestAlreadyCreated(ASubObject, AAutoCreate: Boolean);

  end;

implementation

uses
  System.IOUtils, System.DateUtils;

constructor TTestAutoCreate.Create;
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FNotCreated := TAutoCreateClass.Create;
  FAlreadyCreated := TAutoCreateClass.Create;
  FAlreadyCreated.Recursive := TAutoCreateClass.Create;
end;

destructor TTestAutoCreate.Destroy;
begin
  FNotCreated.Free;
  FAlreadyCreated.Free;

  inherited;
end;

function TTestAutoCreate.GetFileName(const AName: string): string;
begin
  Result := TPath.Combine(FDataPath, ClassName + '.' + AName + '.json');
end;

procedure TTestAutoCreate.Setup;
begin
end;

procedure TTestAutoCreate.TearDown;
begin
end;

procedure TTestAutoCreate.TestNotCreated(ASubObject, AAutoCreate: Boolean);
var
  LFileName: string;
  LConfig: INeonConfiguration;
begin
  if ASubObject then
    LFileName := GetFileName('SubObject')
  else
    LFileName := GetFileName('NoObject');

  LConfig := TNeonConfiguration.Default;
  LConfig.SetAutoCreate(AAutoCreate);
  TTestUtils.DeserializeObject(TFile.ReadAllText(LFileName), FNotCreated, LConfig);

  if AAutoCreate then
  begin
    if ASubObject then
      Assert.IsNotNull(FNotCreated.Recursive)
    else
      Assert.IsNull(FNotCreated.Recursive)
  end
  else
    Assert.IsNull(FNotCreated.Recursive)
end;

procedure TTestAutoCreate.TestAlreadyCreated(ASubObject, AAutoCreate: Boolean);
var
  LFileName: string;
  LConfig: INeonConfiguration;
begin
  if ASubObject then
    LFileName := GetFileName('SubObject')
  else
    LFileName := GetFileName('NoObject');

  LConfig := TNeonConfiguration.Default;
  LConfig.SetAutoCreate(AAutoCreate);
  TTestUtils.DeserializeObject(TFile.ReadAllText(LFileName), FAlreadyCreated, LConfig);
  Assert.IsNotNull(FNotCreated.Recursive);

  if ASubObject then
    Assert.AreEqual('TestSubObject', FAlreadyCreated.Recursive.Name)
  else
    Assert.IsEmpty(FAlreadyCreated.Recursive.Name);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAutoCreate);

end.
