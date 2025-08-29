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
unit Neon.Tests.Config.MemberCase;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils,
  Neon.Core.Types;

type
  [TestFixture]
  [Category('membercase')]
  TTestConfigMemberCase = class(TObject)
  private
    FDataPath: string;
    FCaseObj1: TCaseClass;

    function GetFileName(const AMethod: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestPascalCase', 'TestPascalCase')]
    procedure TestPascalCase(const AMethod: string);

    [Test]
    [TestCase('TestCamelCase', 'TestCamelCase')]
    procedure TestCamelCase(const AMethod: string);

    [TestCase('TestSnakeCase', 'TestSnakeCase')]
    procedure TestSnakeCase(const AMethod: string);

    [TestCase('TestLowerCase', 'TestLowerCase')]
    procedure TestLowerCase(const AMethod: string);

    [TestCase('TestUpperCase', 'TestUpperCase')]
    procedure TestUpperCase(const AMethod: string);

    [TestCase('TestKebabCase', 'TestKebabCase')]
    procedure TestKebabCase(const AMethod: string);

    [TestCase('TestScreamingSnakeCase', 'TestScreamingSnakeCase')]
    procedure TestScreamingSnakeCase(const AMethod: string);
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

function TTestConfigMemberCase.GetFileName(const AMethod: string): string;
begin
  Result := TPath.Combine(FDataPath, ClassName + '.' + AMethod + '.json');
end;

procedure TTestConfigMemberCase.Setup;
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FCaseObj1 := TCaseClass.Create('Paolo', 'Rossi', 'Male', 'Italy', 50);
end;

procedure TTestConfigMemberCase.TearDown;
begin
  FCaseObj1.Free;
end;

procedure TTestConfigMemberCase.TestPascalCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonSettings.Default));
end;

procedure TTestConfigMemberCase.TestScreamingSnakeCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonSettings.ScreamingSnake));
end;

procedure TTestConfigMemberCase.TestSnakeCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonSettings.Snake));
end;

procedure TTestConfigMemberCase.TestUpperCase(const AMethod: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetMemberCase(TNeonCase.UpperCase);
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, LConfig.BuildSettings));
end;

procedure TTestConfigMemberCase.TestCamelCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonSettings.Camel));
end;

procedure TTestConfigMemberCase.TestKebabCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonSettings.Kebab));
end;

procedure TTestConfigMemberCase.TestLowerCase(const AMethod: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetMemberCase(TNeonCase.LowerCase);
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, LConfig.BuildSettings));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigMemberCase);

end.
