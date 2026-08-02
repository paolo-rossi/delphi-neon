{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
program NeonMainDemo;

uses
  Forms,
  Demo.Forms.Main in 'Demo.Forms.Main.pas' {MainForm},
  Demo.Neon.Entities in 'Demo.Neon.Entities.pas',
  Demo.Neon.Serializers in 'Demo.Neon.Serializers.pas',
  Demo.Forms.Details in 'Demo.Forms.Details.pas' {frmDetails},
  Demo.Forms.Serialization.Custom in 'Demo.Forms.Serialization.Custom.pas' {frmSerializationCustom},
  Demo.Frame.Configuration in 'Demo.Frame.Configuration.pas' {frameConfiguration: TFrame},
  Demo.Forms.Serialization.Base in 'Demo.Forms.Serialization.Base.pas' {frmSerializationBase},
  Demo.Forms.Serialization.Simple in 'Demo.Forms.Serialization.Simple.pas' {frmSerializationSimple},
  Demo.Forms.Serialization.Complex in 'Demo.Forms.Serialization.Complex.pas' {frmSerializationComplex},
  Demo.Forms.Serialization.Delphi in 'Demo.Forms.Serialization.Delphi.pas' {frmSerializationDelphi},
  Demo.Forms.Serialization.Schema in 'Demo.Forms.Serialization.Schema.pas' {frmSerializationSchema},
  Demo.Forms.Serialization.Records in 'Demo.Forms.Serialization.Records.pas' {frmSerializationRecords};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TfrmSerializationRecords, frmSerializationRecords);
  Application.Run;
end.