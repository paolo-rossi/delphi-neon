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
unit Demo.Forms.Details;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Data.DB,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.DBCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.StdCtrls,
  Vcl.Mask,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  FireDAC.Stan.StorageJSON;

type
  TfrmDetails = class(TForm)
    imgNeon: TImage;
    dbgPersons: TDBGrid;
    dsPersons: TFDMemTable;
    dsPersonsName: TStringField;
    dsPersonsSurname: TStringField;
    dsPersonsAge: TIntegerField;
    dsoPersons: TDataSource;
    navPersons: TDBNavigator;
    pnlGrid: TPanel;
    dsPersonsAvatar: TGraphicField;
    imgAvatar: TDBImage;
    edtName: TDBEdit;
    edtSurname: TDBEdit;
    edtAge: TDBEdit;
    btnAvatar: TButton;
    dlgOpenAvatar: TOpenDialog;
    dsPersonsDelphiDev: TBooleanField;
    chkDelphiDev: TDBCheckBox;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    dsPersonsBirthDate: TDateTimeField;
    procedure FormCreate(Sender: TObject);
    procedure btnAvatarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  public
    procedure ClearImage;
    procedure EmptyDataSet;
  end;

var
  frmDetails: TfrmDetails;

implementation

uses
  System.IOUtils,
  Vcl.Imaging.pngimage,
  Vcl.Imaging.jpeg;

{$R *.dfm}

procedure TfrmDetails.FormCreate(Sender: TObject);
var
  LFileName: string;
begin
  LFilename := TDirectory.GetParent(TDirectory.GetParent(Application.ExeName));
  LFileName := TPath.Combine(LFileName, 'Data\persons.json');

  dsPersons.LoadFromFile(LFileName);
end;

procedure TfrmDetails.btnAvatarClick(Sender: TObject);
begin
  if dlgOpenAvatar.Execute then
  begin
    dsPersons.Edit;
    try
      (dsPersons.FieldByName('Avatar') as TGraphicField).LoadFromFile(dlgOpenAvatar.FileName);
      dsPersons.Post;
    except
      dsPersons.Cancel;
    end;
  end;
end;

procedure TfrmDetails.Button1Click(Sender: TObject);
begin
  dsPersons.SaveToFile('persons.json', sfJSON);
end;

procedure TfrmDetails.ClearImage;
begin
  imgNeon.Picture.Bitmap.SetSize(0,0);
end;

procedure TfrmDetails.EmptyDataSet;
begin
  dsPersons.EmptyDataSet;
end;

end.
