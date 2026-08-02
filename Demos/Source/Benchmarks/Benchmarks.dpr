{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
program Benchmarks;

uses
  Vcl.Forms,
  Benchmarks.Form.Main in 'Benchmarks.Form.Main.pas' {frmBenchmarks},
  Benchmarks.Entities in 'Benchmarks.Entities.pas',
  Benchmarks.Form.Source in 'Benchmarks.Form.Source.pas' {frmSource},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmBenchmarks, frmBenchmarks);
  Application.CreateForm(TfrmSource, frmSource);
  Application.Run;
end.
