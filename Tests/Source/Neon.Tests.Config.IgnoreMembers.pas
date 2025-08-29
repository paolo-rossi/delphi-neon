﻿{******************************************************************************}
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
unit Neon.Tests.Config.IgnoreMembers;

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

  TStdClass = class
  private
    FName: string;
    FCity: string;
  public
    property Name: string read FName write FName;
    property City: string read FCity write FCity;
  end;


  [TestFixture]
  [Category('ignoremembers')]
  TTestIgnoreMembers = class(TObject)
  private
    FDataPath: string;
    FTestObj: TTestClass;
    FTestStd: TStdClass;
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIgnoreAll', 'Name,Address,City,Country,Year|{}', '|')]
    [TestCase('TestIgnoreButYear', 'Name,Address,City,Country|{"Year":1969}', '|')]
    [TestCase('TestIgnoreButName', 'Address,City,Country,Year|{"Name":"Paolo"}', '|')]
    [TestCase('TestIgnoreSome', 'Address,Year|{"Name":"Paolo","City":"Piacenza","Country":"Italy"}', '|')]
    procedure TestIgnore(const AMemberList, _Result: string);

    [Test]
    [TestCase('TestIgnoreAll', 'Name,Address,City,Country,Year|{}', '|')]
    [TestCase('TestIgnoreButYear', 'Name,Address,City,Country|{"Year":1969}', '|')]
    [TestCase('TestIgnoreButName', 'Address,City,Country,Year|{"Name":"Paolo"}', '|')]
    [TestCase('TestIgnoreSome', 'Address,Year|{"Name":"Paolo","City":"Piacenza","Country":"Italy"}', '|')]
    procedure TestIgnoreType(const AMemberList, _Result: string);

    [Test]
    [TestCase('TestIgnoreAll', 'Name,Address|{"Name":"Paolo","City":"Piacenza"}', '|')]
    [TestCase('TestIgnoreButName', 'Address|{"Name":"Paolo","City":"Piacenza"}', '|')]
    procedure TestStdType(const AMemberList, _Result: string);
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

constructor TTestIgnoreMembers.Create;
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FTestObj := TTestClass.Create;
  FTestObj.Name := 'Paolo';
  FTestObj.City := 'Piacenza';
  FTestObj.Country := 'Italy';
  FTestObj.Year := 1969;

  FTestStd := TStdClass.Create;
  FTestStd.Name := 'Paolo';
  FTestStd.City := 'Piacenza';
end;

destructor TTestIgnoreMembers.Destroy;
begin
  FTestObj.Free;
  FTestStd.Free;
  inherited;
end;

procedure TTestIgnoreMembers.Setup;
begin
end;

procedure TTestIgnoreMembers.TearDown;
begin
end;

procedure TTestIgnoreMembers.TestIgnore(const AMemberList, _Result: string);
var
  LIgnoreList: TArray<string>;
  LConfig: INeonConfiguration;
begin
  LIgnoreList := AMemberList.Split([',']);

  LConfig := TNeonConfiguration.Default;
  LConfig.SetIgnoreMembers(LIgnoreList);

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig.BuildSettings));
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
    .BackToConfig;

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig.BuildSettings));
end;

procedure TTestIgnoreMembers.TestStdType(const AMemberList, _Result: string);
var
  LIgnoreList: TArray<string>;
  LConfig: INeonConfiguration;
begin
  LIgnoreList := AMemberList.Split([',']);

  LConfig := TNeonConfiguration.Default
    .Rules.ForClass<TTestClass>
      .SetIgnoreMembers(LIgnoreList)
    .BackToConfig;

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestStd, LConfig.BuildSettings));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIgnoreMembers);

end.
