{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018 Paolo Rossi                                              }
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
unit Benchmarks.Form.Source;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TfrmSource = class(TForm)
    richSourceSimple: TRichEdit;
    richSourceComplex: TRichEdit;
    pgcSource: TPageControl;
    tsSourceSimple: TTabSheet;
    tsSourceComplex: TTabSheet;
    lblSimple: TLabel;
    pnlHeader: TPanel;
    shpHeader: TShape;
    lblHeader: TLabel;
    lblHeader2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSource: TfrmSource;

implementation

{$R *.dfm}

procedure TfrmSource.FormCreate(Sender: TObject);
begin
  richSourceSimple.Lines.LoadFromFile('..\Data\Benchmarks\benchmark-simple.rtf');
  richSourceComplex.Lines.LoadFromFile('..\Data\Benchmarks\benchmark-complex.rtf');
end;

end.
