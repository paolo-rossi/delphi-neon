{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
program SchemaConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaConsole.Entities in 'SchemaConsole.Entities.pas',
  SchemaConsole.Runner in 'SchemaConsole.Runner.pas';

{$R *.res}

var
  LDemo: TSchemaDemo;
begin
  try
    LDemo := TSchemaDemo.Create;
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
