{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
program ReadOnlyConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  ReadOnlyConsole.Entities in 'ReadOnlyConsole.Entities.pas',
  ReadOnlyConsole.Runner in 'ReadOnlyConsole.Runner.pas';

{$R *.res}

var
  LDemo: TReadOnlyDemo;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    LDemo := TReadOnlyDemo.Create;
    try
      LDemo.Run;
    finally
      LDemo.Free;
    end;

    WriteLn;
    WriteLn('Press Enter to quit');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn(Format('Error: [%s] %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;
end.
