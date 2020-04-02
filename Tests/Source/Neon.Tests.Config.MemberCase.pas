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
unit Neon.Tests.Config.MemberCase;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

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

    [Test]
    [TestCase('TestSnakeCase', 'TestSnakeCase')]
    procedure TestSnakeCase(const AMethod: string);

    [Test]
    [TestCase('TestLowerCase', 'TestLowerCase')]
    procedure TestLowerCase(const AMethod: string);

    [Test]
    [TestCase('TestUpperCase', 'TestUpperCase')]
    procedure TestUpperCase(const AMethod: string);
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
    TTestUtils.SerializeObject(FCaseObj1, TNeonConfiguration.Default));
end;

procedure TTestConfigMemberCase.TestSnakeCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonConfiguration.Snake));
end;

procedure TTestConfigMemberCase.TestUpperCase(const AMethod: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetMemberCase(TNeonCase.UpperCase);
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, LConfig));
end;

procedure TTestConfigMemberCase.TestCamelCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonConfiguration.Camel));
end;

procedure TTestConfigMemberCase.TestLowerCase(const AMethod: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;
  LConfig.SetMemberCase(TNeonCase.LowerCase);
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, LConfig));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigMemberCase);

end.
