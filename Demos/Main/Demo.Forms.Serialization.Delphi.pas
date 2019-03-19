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
  Demo.Forms.Serialization.Base;

type
  TfrmSerializationDelphi = class(TfrmSerializationBase)
    btnSerDataSet: TButton;
    btnDesDataSet: TButton;
    btnSerImage: TButton;
    btnSerStringList: TButton;
    btnDesStringList: TButton;
    btnDesImage: TButton;
    btnShowDetails: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnDesDataSetClick(Sender: TObject);
    procedure btnDesStringListClick(Sender: TObject);
    procedure btnSerDataSetClick(Sender: TObject);
    procedure btnSerImageClick(Sender: TObject);
    procedure btnSerStringListClick(Sender: TObject);
    procedure btnDesImageClick(Sender: TObject);
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
  Demo.Forms.Details;

{$R *.dfm}

procedure TfrmSerializationDelphi.FormCreate(Sender: TObject);
begin
  frmDetails := TfrmDetails.Create(Self);
end;

procedure TfrmSerializationDelphi.btnDesDataSetClick(Sender: TObject);
begin
  frmDetails.dsPersons.EmptyDataSet;
  DeserializeObject(frmDetails.dsPersons, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  SerializeObject(frmDetails.dsPersons, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationDelphi.btnDesStringListClick(Sender: TObject);
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

procedure TfrmSerializationDelphi.btnSerDataSetClick(Sender: TObject);
begin
  SerializeObject(frmDetails.dsPersons, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationDelphi.btnSerImageClick(Sender: TObject);
begin
  SerializeObject(frmDetails.imgNeon, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationDelphi.btnSerStringListClick(Sender: TObject);
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

procedure TfrmSerializationDelphi.btnDesImageClick(Sender: TObject);
begin
  DeserializeObject(frmDetails.imgNeon, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationDelphi.btnShowDetailsClick(Sender: TObject);
begin
  frmDetails.Visible := not frmDetails.Visible;
end;

end.
