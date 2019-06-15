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
unit Demo.Forms.Serialization.Complex;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  Demo.Forms.Serialization.Base, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.StorageBin, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.Imaging.pngimage;

type
  TfrmSerializationComplex = class(TfrmSerializationBase)
    btnSerComplexObject: TButton;
    btnSerDictionary: TButton;
    btnSerFilterObject: TButton;
    btnSerGenericList: TButton;
    btnSerGenericObjectList: TButton;
    btnSerSimpleObject: TButton;
    btnSerStreamable: TButton;
    btnStreamableProp: TButton;
    btnDesComplexObject: TButton;
    btnDesDictionary: TButton;
    btnDesFilterObject: TButton;
    btnDesGenericList: TButton;
    btnDesGenericObjectList: TButton;
    btnDesSimpleObject: TButton;
    btnDesStreamable: TButton;
    btnDesStreamableProp: TButton;
    procedure btnDesComplexObjectClick(Sender: TObject);
    procedure btnDesDictionaryClick(Sender: TObject);
    procedure btnDesFilterObjectClick(Sender: TObject);
    procedure btnDesGenericListClick(Sender: TObject);
    procedure btnDesGenericObjectListClick(Sender: TObject);
    procedure btnDesSimpleObjectClick(Sender: TObject);
    procedure btnDesStreamableClick(Sender: TObject);
    procedure btnDesStreamablePropClick(Sender: TObject);
    procedure btnSerComplexObjectClick(Sender: TObject);
    procedure btnSerDictionaryClick(Sender: TObject);
    procedure btnSerFilterObjectClick(Sender: TObject);
    procedure btnSerGenericListClick(Sender: TObject);
    procedure btnSerGenericObjectListClick(Sender: TObject);
    procedure btnSerSimpleObjectClick(Sender: TObject);
    procedure btnSerStreamableClick(Sender: TObject);
    procedure btnStreamablePropClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSerializationComplex: TfrmSerializationComplex;

implementation

uses
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationComplex.btnDesComplexObjectClick(Sender: TObject);
var
  LPerson: TPerson;
begin
  LPerson := TPerson.Create;
  try
    DeserializeObject(LPerson, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LPerson, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LPerson.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesDictionaryClick(Sender: TObject);
var
  LMap: TObjectDictionary<TAddress, TNote>;
begin
  LMap := TObjectDictionary<TAddress, TNote>.Create([doOwnsKeys, doOwnsValues]);
  try
    DeserializeObject(LMap, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LMap, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LMap.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesFilterObjectClick(Sender: TObject);
var
  LObj: TFilterClass;
begin
  LObj := TFilterClass.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LObj, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesGenericListClick(Sender: TObject);
var
  LList: TList<Double>;
begin
  LList := TList<Double>.Create;
  try
    DeserializeObject(LList, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LList, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LList.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesGenericObjectListClick(Sender: TObject);
var
  LList: TAddressBook;
begin
  LList := TAddressBook.Create;
  try
    DeserializeObject(LList, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LList, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LList.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesSimpleObjectClick(Sender: TObject);
var
  LSimple: TCaseClass;
begin
  LSimple := TCaseClass.Create;
  try
    DeserializeObject(LSimple, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LSimple, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LSimple.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesStreamableClick(Sender: TObject);
var
  LStreamable: TStreamableSample;
begin
  LStreamable := TStreamableSample.Create;
  try
    DeserializeObject(LStreamable, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LStreamable, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LStreamable.Free;
  end;
end;

procedure TfrmSerializationComplex.btnDesStreamablePropClick(Sender: TObject);
var
  LStreamable: TStreamableComposition;
begin
  LStreamable := TStreamableComposition.Create;
  try
    DeserializeObject(LStreamable, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LStreamable, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LStreamable.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerComplexObjectClick(Sender: TObject);
var
  LPerson: TPerson;
begin
  LPerson := TPerson.Create;
  try
    LPerson.Name := 'Paolo';
    LPerson.Surname := 'Rossi';
    LPerson.AddAddress('Piacenza', 'Italy');
    LPerson.AddAddress('Parma', 'Italy');
    LPerson.Note.Date := Now;
    LPerson.Note.Text := 'Note Text';

    LPerson.Map.Add('first', TNote.Create(Now, 'First Object'));
    LPerson.Map.Add('second', TNote.Create(Now, 'Second Object'));
    LPerson.Map.Add('third', TNote.Create(Now, 'Third Object'));
    LPerson.Map.Add('fourth', TNote.Create(Now, 'Fourth Object'));

    SerializeObject(LPerson, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LPerson.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerDictionaryClick(Sender: TObject);
var
  LMap: TObjectDictionary<TAddress, TNote>;
begin
  LMap := TObjectDictionary<TAddress, TNote>.Create([doOwnsKeys, doOwnsValues]);
  try
    LMap.Add(TAddress.Create('Piacenza', 'Italy'), TNote.Create(Now, 'Lorem ipsum dolor sit amet'));
    LMap.Add(TAddress.Create('Dublin', 'Ireland'), TNote.Create(Now + 0.2, 'Fusce in libero posuere'));
    SerializeObject(LMap, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LMap.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerFilterObjectClick(Sender: TObject);
var
  LSimple: TFilterClass;
begin
  LSimple := TFilterClass.DefaultValues;
  try
    SerializeObject(LSimple, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LSimple.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerGenericListClick(Sender: TObject);
var
  LList: TList<Double>;
begin
  LList := TList<Double>.Create;
  try
    LList.Add(34.9);
    LList.Add(10.0);

    SerializeObject(LList, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LList.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerGenericObjectListClick(Sender: TObject);
var
  LBook: TAddressBook;
begin
  LBook := TAddressBook.Create;
  try
    LBook.Add('Verona', 'Italy');
    LBook.Add('Napoli', 'Italy');
    LBook.NoteList.Add('Note 1');
    LBook.NoteList.Add('Note 2');
    LBook.NoteList.Add('Note 3');

    SerializeObject(LBook, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LBook.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerSimpleObjectClick(Sender: TObject);
var
  LSimple: TCaseClass;
begin
  LSimple := TCaseClass.DefaultValues;
  try
    SerializeObject(LSimple, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LSimple.Free;
  end;
end;

procedure TfrmSerializationComplex.btnSerStreamableClick(Sender: TObject);
var
  LStreamable: TStreamableSample;
begin
  LStreamable := TStreamableSample.Create;
  try
    LStreamable.AsString := 'Paolo';
    SerializeObject(LStreamable, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LStreamable.Free;
  end;
end;

procedure TfrmSerializationComplex.btnStreamablePropClick(Sender: TObject);
var
  LStreamable: TStreamableComposition;
begin
  LStreamable := TStreamableComposition.Create;
  try
    LStreamable.InValue := 233;
    LStreamable.Stream.AsString := 'Paolo';

    SerializeObject(LStreamable, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LStreamable.Free;
  end;
end;

end.
