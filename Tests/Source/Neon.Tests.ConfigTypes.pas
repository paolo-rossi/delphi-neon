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
unit Neon.Tests.ConfigTypes;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils, Neon.Tests.Config.IgnoreMembers;

type
  TTestClass = class
  private
    FCity: string;
    FCountry: string;
    FName: string;
    FYear: Integer;
    FAddress: string;
  public
    property Name: string read FName write FName;
    property Address: string read FAddress write FAddress;
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;
    property Year: Integer read FYear write FYear;
  end;

  [TestFixture]
  [Category('configtypes')]
  TTestIgnoreMembers = class(TObject)
  private
    FDataPath: string;
    FObj: TTestClass;
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIgnoreAll', 'Name,Address,City,Country,Year|{}', '|')]
    procedure TestIgnoreType(const AMemberList, _Result: string);
  end;


implementation

uses
  System.IOUtils;

constructor TTestIgnoreMembers.Create;
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FObj := TTestClass.Create;
  FObj.Name := 'Paolo';
  FObj.City := 'Piacenza';
  FObj.Country := 'Italy';
  FObj.Year := 1969;
end;

destructor TTestIgnoreMembers.Destroy;
begin
  FObj.Free;

  inherited;
end;

procedure TTestIgnoreMembers.Setup;
begin
end;

procedure TTestIgnoreMembers.TearDown;
begin
end;

procedure TTestIgnoreMembers.TestIgnoreType(const AMemberList, _Result: string);
var
  LIgnoreList: TArray<string>;
  LConfig: INeonConfiguration;
begin
  LIgnoreList := AMemberList.Split([',']);

  LConfig := TNeonConfiguration.Default
    .Rules.ForClass<TTestClass>
      .SetIgnoreMembers(LIgnoreList)
      .ApplyConfig;
  TTestUtils.SerializeObject(FObj, LConfig);

  Assert.Pass('Typed Config');
end;

end.
