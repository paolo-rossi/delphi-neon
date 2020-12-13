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
unit Demo.Forms.Serialization.Delphi;

interface

uses
  Winapi.Windows, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB,

  Demo.Forms.Serialization.Base,
  Neon.Core.Attributes, Vcl.CategoryButtons, System.Actions, Vcl.ActnList,
  System.ImageList, Vcl.ImgList;

type
  TfrmSerializationDelphi = class(TfrmSerializationBase)
    btnShowDetails: TButton;
    actSerDataSet: TAction;
    actSerImage: TAction;
    actSerBitmap: TAction;
    actStringList: TAction;
    actDesDataSet: TAction;
    actDesImage: TAction;
    actDesBitmap: TAction;
    actDesStringList: TAction;
    btnShowDetailsLeft: TButton;
    procedure actDesBitmapExecute(Sender: TObject);
    procedure actDesDataSetExecute(Sender: TObject);
    procedure actDesImageExecute(Sender: TObject);
    procedure actDesStringListExecute(Sender: TObject);
    procedure actSerBitmapExecute(Sender: TObject);
    procedure actSerDataSetExecute(Sender: TObject);
    procedure actSerImageExecute(Sender: TObject);
    procedure actStringListExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnShowDetailsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSerializationDelphi: TfrmSerializationDelphi;

implementation

uses
  System.UITypes,
  Demo.Forms.Details;

{$R *.dfm}

procedure TfrmSerializationDelphi.actDesBitmapExecute(Sender: TObject);
begin
  DeserializeObject(frmDetails.imgNeon.Picture.Bitmap, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  MessageDlg('Bitmap has been loaded from JSON. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actDesDataSetExecute(Sender: TObject);
begin
  frmDetails.dsPersons.EmptyDataSet;
  DeserializeObject(frmDetails.dsPersons, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  SerializeObject(frmDetails.dsPersons, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  MessageDlg('DataSet has been populated from JSON. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actDesImageExecute(Sender: TObject);
begin
  DeserializeObject(frmDetails.imgNeon, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  MessageDlg('Picture has been loaded from JSON. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actDesStringListExecute(Sender: TObject);
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    DeserializeObject(LList, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LList, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LList.Free;
  end;
end;

procedure TfrmSerializationDelphi.actSerBitmapExecute(Sender: TObject);
var
  LFileName: string;
begin
  LFileName := ExtractFilePath(Application.ExeName) + '..\..\neon-logo-600.bmp';
  frmDetails.imgNeon.Picture.Bitmap.LoadFromFile(LFileName);
  SerializeObject(frmDetails.imgNeon.Picture.Bitmap, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  frmDetails.ClearImage;
  MessageDlg('Bitmap has been cleared. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actSerDataSetExecute(Sender: TObject);
begin
  SerializeObject(frmDetails.dsPersons, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  frmDetails.EmptyDataSet;
  MessageDlg('DataSet has been emptied, you can change manually the JSON. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actSerImageExecute(Sender: TObject);
var
  LFileName: string;
begin
  LFileName := ExtractFilePath(Application.ExeName) + '..\..\neon-logo-600.bmp';
  frmDetails.imgNeon.Picture.Bitmap.LoadFromFile(LFileName);
  SerializeObject(frmDetails.imgNeon, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  frmDetails.ClearImage;
  MessageDlg('Picture has been cleared. Click the "Show details" button', mtInformation, [mbOK], 0);
end;

procedure TfrmSerializationDelphi.actStringListExecute(Sender: TObject);
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Add('Paolo');
    LList.Add('Marco');
    LList.Add('Nando');
    SerializeObject(LList, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LList.Free;
  end;
end;

procedure TfrmSerializationDelphi.FormCreate(Sender: TObject);
begin
  frmDetails := TfrmDetails.Create(Self);
end;

procedure TfrmSerializationDelphi.btnShowDetailsClick(Sender: TObject);
begin
  frmDetails.Visible := not frmDetails.Visible;
end;

end.
