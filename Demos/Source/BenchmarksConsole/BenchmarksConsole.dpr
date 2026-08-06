{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
program BenchmarksConsole;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  BenchmarksConsole.Entities in 'BenchmarksConsole.Entities.pas',
  BenchmarksConsole.Runner in 'BenchmarksConsole.Runner.pas';

var
  LRunner: TBenchmarkRunner;
  LOutputPath: string;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    LOutputPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'Results');

    WriteLn('==============================================================');
    WriteLn(' Neon vs REST.Json vs System.JSON.Serializers - JSON Benchmark');
    WriteLn('==============================================================');

    LRunner := TBenchmarkRunner.Create(LOutputPath, 5);
    try
      LRunner.SaveJsonSamples;

      LRunner.RunSimpleUsersBenchmark([100, 1000, 5000]);
      LRunner.RunCustomersBenchmark([50, 500, 1000]);

      LRunner.PrintReport;
      LRunner.SaveReport;
    finally
      LRunner.Free;
    end;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;

  WriteLn;
  WriteLn('Done. Press ENTER to exit...');
  ReadLn;
end.
