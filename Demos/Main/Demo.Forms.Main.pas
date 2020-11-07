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
unit Demo.Forms.Main;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.ActnList, Vcl.ComCtrls, System.Rtti,
  Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, System.Diagnostics, System.Actions,
  System.TypInfo, Vcl.Dialogs, System.UITypes, Vcl.Imaging.pngimage, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Stan.StorageBin, Vcl.Grids, Vcl.DBGrids,
  Vcl.ToolWin, System.Contnrs, System.JSON, REST.Json,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Utils,
  Demo.Frame.Configuration,
  Demo.Forms.Serialization.Base;

type
  TMainForm = class(TForm)
    TopPanel: TPanel;
    imgNeon: TImage;
    pgcMain: TPageControl;
    frmConfiguration: TframeConfiguration;
    procedure FormCreate(Sender: TObject);
  private
    procedure CreateTab(const ACaption: string; AColor: TColor; AClass: TfrmSerializationClass);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Generics.Collections, Vcl.Graphics,

  Demo.Forms.Serialization.Custom, Demo.Forms.Serialization.Delphi,
  Demo.Forms.Serialization.Simple, Demo.Forms.Serialization.Records,
  Demo.Forms.Serialization.Schema, Demo.Forms.Serialization.Complex;

{ TMainForm }

procedure TMainForm.CreateTab(const ACaption: string; AColor: TColor; AClass: TfrmSerializationClass);
var
  LTab: TTabSheet;
  LForm: TfrmSerializationBase;
begin
  LTab := TTabSheet.Create(pgcMain);
  LTab.Caption := ACaption;
  LTab.PageControl := pgcMain;

  LForm := AClass.CreateEx(Self, frmConfiguration, AColor);
  LForm.BorderStyle := bsNone;
  LForm.Parent := LTab;
  LForm.Align := alClient;
  LForm.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  frmConfiguration.Initialize;

  CreateTab('Simple Types', clGreen, TfrmSerializationSimple);
  CreateTab('Value Types', clTeal, TfrmSerializationRecords);
  CreateTab('Reference Types', clNavy, TfrmSerializationComplex);
  CreateTab('Delphi Types', clOlive, TfrmSerializationDelphi);
  CreateTab('Custom Serializers', clMaroon, TfrmSerializationCustom);
  CreateTab('JSON Schema', clWebTan, TfrmSerializationSchema);
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

end.
