{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
program Neon.Tests.Framework;

{$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
{$ENDIF}

{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  Neon.Data.Tests in 'Source\Neon.Data.Tests.pas' {DataTests: TDataModule},
  Neon.Serializers.Tests in 'Source\Neon.Serializers.Tests.pas',
  Neon.Tests.Utils in 'Source\Neon.Tests.Utils.pas',
  Neon.Tests.Entities in 'Source\Neon.Tests.Entities.pas',
  Neon.Tests.Serializer in 'Source\Neon.Tests.Serializer.pas',
  Neon.Tests.Types.Bytes in 'Source\Neon.Tests.Types.Bytes.pas',
  Neon.Tests.Types.Enums in 'Source\Neon.Tests.Types.Enums.pas',
  Neon.Tests.Types.Simple in 'Source\Neon.Tests.Types.Simple.pas',
  Neon.Tests.Types.Arrays in 'Source\Neon.Tests.Types.Arrays.pas',
  Neon.Tests.Types.Strings in 'Source\Neon.Tests.Types.Strings.pas',
  Neon.Tests.Types.Records in 'Source\Neon.Tests.Types.Records.pas',
  Neon.Tests.Types.Reference in 'Source\Neon.Tests.Types.Reference.pas',
  Neon.Tests.Config.MemberCase in 'Source\Neon.Tests.Config.MemberCase.pas',
  Neon.Tests.Config.EnumAsInt in 'Source\Neon.Tests.Config.EnumAsInt.pas',
  Neon.Tests.Config.AutoCreate in 'Source\Neon.Tests.Config.AutoCreate.pas',
  Neon.Tests.Attributes.Factory in 'Source\Neon.Tests.Attributes.Factory.pas',
  Neon.Tests.CustomSerializers in 'Source\Neon.Tests.CustomSerializers.pas',
  Neon.Tests.Config.IgnoreMembers in 'Source\Neon.Tests.Config.IgnoreMembers.pas',
  Neon.Tests.Config.IncludeIf in 'Source\Neon.Tests.Config.IncludeIf.pas',
  Neon.Tests.Config.ReadOnlyProps in 'Source\Neon.Tests.Config.ReadOnlyProps.pas',
  Neon.Tests.Config.MapSort in 'Source\Neon.Tests.Config.MapSort.pas',
  Neon.Tests.ConfigTypes in 'Source\Neon.Tests.ConfigTypes.pas',
  Neon.Tests.Tags in 'Source\Neon.Tests.Tags.pas',
  Neon.Tests.StructTags in 'Source\Neon.Tests.StructTags.pas',
  Neon.Tests.JsonSchema in 'Source\Neon.Tests.JsonSchema.pas',
  Neon.Tests.JsonSchemaValidator in 'Source\Neon.Tests.JsonSchemaValidator.pas';

var
  LRunner : ITestRunner;
  LResults : IRunResults;
  LLogger : ITestLogger;
  LNUnitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  Exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    LRunner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    LRunner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    LLogger := TDUnitXConsoleLogger.Create(true);
    LRunner.AddLogger(LLogger);
    //Generate an NUnit compatible XML File
    LNUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLogger);
    LRunner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    LResults := LRunner.Execute;
    if not LResults.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
