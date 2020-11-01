program Neon.Tests.Framework;

{$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
{$ENDIF}

{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Neon.Data.Tests in 'Source\Neon.Data.Tests.pas' {DataTests: TDataModule},
  Neon.Serializers.Tests in 'Source\Neon.Serializers.Tests.pas',
  Neon.Tests.Utils in 'Source\Neon.Tests.Utils.pas',
  Neon.Tests.Entities in 'Source\Neon.Tests.Entities.pas',
  Neon.Tests.Serializer in 'Source\Neon.Tests.Serializer.pas',
  Neon.Tests.Types.Enums in 'Source\Neon.Tests.Types.Enums.pas',
  Neon.Tests.Types.Simple in 'Source\Neon.Tests.Types.Simple.pas',
  Neon.Tests.Types.Arrays in 'Source\Neon.Tests.Types.Arrays.pas',
  Neon.Tests.Types.Strings in 'Source\Neon.Tests.Types.Strings.pas',
  Neon.Tests.Types.Records in 'Source\Neon.Tests.Types.Records.pas',
  Neon.Tests.Types.Reference in 'Source\Neon.Tests.Types.Reference.pas',
  Neon.Tests.CustomSerializers in 'Source\Neon.Tests.CustomSerializers.pas',
  Neon.Tests.Config.MemberCase in 'Source\Neon.Tests.Config.MemberCase.pas';

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
