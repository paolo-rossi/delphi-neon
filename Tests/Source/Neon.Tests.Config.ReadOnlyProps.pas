{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.ReadOnlyProps;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Tests.Utils;

type
  TReadOnlyChild = class
  private
    FValue: Integer;
  public
    property Value: Integer read FValue write FValue;
  end;

  TReadOnlyClass = class
  private
    FName: string;
    FChild: TReadOnlyChild;
    function GetComputed: string;
  public
    constructor Create;
    destructor Destroy; override;

    property Name: string read FName write FName;

    // Read-only and simply typed: dropped when IgnoreReadOnlyProps is on
    property Computed: string read GetComputed;

    // Read-only but class typed: kept even when IgnoreReadOnlyProps is on,
    // otherwise sub-objects exposed through a getter would never be written
    property Child: TReadOnlyChild read FChild;
  end;

  [TestFixture]
  [Category('readonlyprops')]
  TTestReadOnlyProps = class(TObject)
  private
    FTestObj: TReadOnlyClass;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestKeepReadOnly', 'False|{"Name":"Paolo","Computed":"Paolo!","Child":{"Value":42}}', '|')]
    [TestCase('TestDropReadOnly', 'True|{"Name":"Paolo","Child":{"Value":42}}', '|')]
    procedure TestIgnoreReadOnlyProps(const AIgnore: Boolean; const _Result: string);

    /// <summary>
    ///   The ignore list is applied before the read-only check, which probes
    ///   the member type: an ignored member must be dropped without its type
    ///   ever being looked at
    /// </summary>
    [Test]
    [TestCase('TestIgnoreSimpleReadOnly', 'Computed|{"Name":"Paolo","Child":{"Value":42}}', '|')]
    [TestCase('TestIgnoreClassReadOnly', 'Child|{"Name":"Paolo"}', '|')]
    [TestCase('TestIgnoreBoth', 'Computed,Child|{"Name":"Paolo"}', '|')]
    procedure TestIgnoreListWithReadOnlyProps(const AMemberList, _Result: string);
  end;

implementation

{ TReadOnlyClass }

constructor TReadOnlyClass.Create;
begin
  FChild := TReadOnlyChild.Create;
end;

destructor TReadOnlyClass.Destroy;
begin
  FChild.Free;
  inherited;
end;

function TReadOnlyClass.GetComputed: string;
begin
  Result := FName + '!';
end;

{ TTestReadOnlyProps }

procedure TTestReadOnlyProps.Setup;
begin
  FTestObj := TReadOnlyClass.Create;
  FTestObj.Name := 'Paolo';
  FTestObj.Child.Value := 42;
end;

procedure TTestReadOnlyProps.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestReadOnlyProps.TestIgnoreReadOnlyProps(const AIgnore: Boolean; const _Result: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetIgnoreReadOnlyProps(AIgnore);

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig));
end;

procedure TTestReadOnlyProps.TestIgnoreListWithReadOnlyProps(const AMemberList, _Result: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetIgnoreReadOnlyProps(True);
  LConfig.SetIgnoreMembers(AMemberList.Split([',']));

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestReadOnlyProps);

end.
