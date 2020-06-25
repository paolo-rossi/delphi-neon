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
program NeonMainDemo;

uses
  Forms,
  Demo.Forms.Main in 'Demo.Forms.Main.pas' {MainForm},
  Demo.Neon.Entities in 'Demo.Neon.Entities.pas',
  Demo.Neon.Serializers in 'Demo.Neon.Serializers.pas',
  Demo.Forms.Serialization.Custom in 'Demo.Forms.Serialization.Custom.pas' {frmSerializationCustom},
  Demo.Frame.Configuration in 'Demo.Frame.Configuration.pas' {frameConfiguration: TFrame},
  Demo.Forms.Serialization.Base in 'Demo.Forms.Serialization.Base.pas' {frmSerializationBase},
  Demo.Forms.Serialization.Simple in 'Demo.Forms.Serialization.Simple.pas' {frmSerializationSimple},
  Demo.Forms.Serialization.Complex in 'Demo.Forms.Serialization.Complex.pas' {frmSerializationComplex},
  Demo.Forms.Serialization.Delphi in 'Demo.Forms.Serialization.Delphi.pas' {frmSerializationDelphi},
  Demo.Forms.Serialization.Schema in 'Demo.Forms.Serialization.Schema.pas' {frmSerializationSchema},
  Demo.Forms.Details in 'Demo.Forms.Details.pas' {frmDetails},
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