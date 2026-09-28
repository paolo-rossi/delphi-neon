{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.MemberCase;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils,
  Neon.Core.Types;

type
  /// <summary>
  ///   Fields that do and do not follow the F prefix convention
  /// </summary>
  TPrefixEntity = class
  private
    FFirstName: string;
    firstName: string;
    Formula: string;
    Total: string;
  protected
    FCode: string;
  public
    FPublicField: string;
    constructor Create;
  end;

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

    /// <summary>
    ///   Pins the documented acronym behavior of the case conversions
    /// </summary>
    [Test]
    procedure TestAcronymsAreOneWord;

    /// <summary>
    ///   Pins the documented behavior of IgnoreFieldPrefix
    /// </summary>
    [Test]
    procedure TestFieldPrefixNeedsTheConvention;
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
  FDataPath := TPath.GetAppPath;
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

procedure TTestConfigMemberCase.TestScreamingSnakeCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonConfiguration.ScreamingSnake));
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

procedure TTestConfigMemberCase.TestKebabCase(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FCaseObj1, TNeonConfiguration.Kebab));
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

procedure TTestConfigMemberCase.TestAcronymsAreOneWord;
begin
  // A run of capitals is never split: this is the documented behavior of the
  // conversions (see the remarks on TCaseAlgorithm and the README), not an
  // accident of the current regex. ignoreCase = False everywhere - DUnitX
  // compares strings case-insensitively by default, which would pass anyway
  Assert.AreEqual('first_name', TCaseAlgorithm.PascalToSnake('FirstName'), False);
  Assert.AreEqual('httpresponse', TCaseAlgorithm.PascalToSnake('HTTPResponse'), False);
  Assert.AreEqual('ipaddress', TCaseAlgorithm.PascalToSnake('IPAddress'), False);
  Assert.AreEqual('my_urlvalue', TCaseAlgorithm.PascalToSnake('MyURLValue'), False);

  // A trailing run of two or more capitals splits, a single one does not
  Assert.AreEqual('user_id', TCaseAlgorithm.PascalToSnake('UserID'), False);
  Assert.AreEqual('valuex', TCaseAlgorithm.PascalToSnake('ValueX'), False);

  Assert.AreEqual('httpresponse', TCaseAlgorithm.PascalToKebab('HTTPResponse'), False);
  Assert.AreEqual('user-id', TCaseAlgorithm.PascalToKebab('UserID'), False);
  Assert.AreEqual('HTTPRESPONSE', TCaseAlgorithm.PascalToScreamingSnake('HTTPResponse'), False);
  Assert.AreEqual('USER_ID', TCaseAlgorithm.PascalToScreamingSnake('UserID'), False);

  // camelCase lowercases the first character only
  Assert.AreEqual('hTTPResponse', TCaseAlgorithm.PascalToCamel('HTTPResponse'), False);
  Assert.AreEqual('firstName', TCaseAlgorithm.PascalToCamel('FirstName'), False);

  // The inverse conversions cannot restore the capitalization of a run
  Assert.AreEqual('UserId', TCaseAlgorithm.SnakeToPascal('user_id'), False);
  Assert.AreEqual('Httpresponse', TCaseAlgorithm.SnakeToPascal('httpresponse'), False);
end;

{ TPrefixEntity }

constructor TPrefixEntity.Create;
begin
  FFirstName := 'a';
  firstName := 'b';
  Formula := 'c';
  Total := 'd';
  FCode := 'e';
  FPublicField := 'f';
end;

procedure TTestConfigMemberCase.TestFieldPrefixNeedsTheConvention;
var
  LEntity: TPrefixEntity;
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default
    .SetMembers([TNeonMembers.Fields])
    .SetVisibility([mvPrivate, mvProtected, mvPublic, mvPublished]);

  LEntity := TPrefixEntity.Create;
  try
    // Off: every field keeps its Delphi name
    Assert.AreEqual(
      '{"FFirstName":"a","firstName":"b","Formula":"c","Total":"d","FCode":"e","FPublicField":"f"}',
      TTestUtils.SerializeObject(LEntity, LConfig), False);

    // On: the first letter of any private/protected field starting with F or f
    // goes, convention or not - firstName becomes irstName and Formula ormula.
    // Documented behavior (see SetIgnoreFieldPrefix and the README), not an
    // accident: [NeonProperty] is the way out for a member that needs its name
    Assert.AreEqual(
      '{"FirstName":"a","irstName":"b","ormula":"c","Total":"d","Code":"e","FPublicField":"f"}',
      TTestUtils.SerializeObject(LEntity, LConfig.SetIgnoreFieldPrefix(True)), False);
  finally
    LEntity.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigMemberCase);

end.
