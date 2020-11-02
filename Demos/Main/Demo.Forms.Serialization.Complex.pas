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
  FireDAC.Comp.Client, Vcl.Imaging.pngimage, Vcl.CategoryButtons,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList;

type
  TfrmSerializationComplex = class(TfrmSerializationBase)
    actSerClassSimple: TAction;
    actSerClassComplex: TAction;
    actSerGenericList: TAction;
    actSerGenericObjectList: TAction;
    actSerStreamable: TAction;
    actSerStreamableProp: TAction;
    actSerClassFilter: TAction;
    actSerDictionary: TAction;
    actDesClassSimple: TAction;
    actDesClassComplex: TAction;
    actDelClassFilter: TAction;
    actDesGenericList: TAction;
    actDesGenericObjectList: TAction;
    actDesDictionary: TAction;
    actDesStreamable: TAction;
    actDesStreamableProp: TAction;
    procedure actDelClassFilterExecute(Sender: TObject);
    procedure actDesClassComplexExecute(Sender: TObject);
    procedure actDesClassSimpleExecute(Sender: TObject);
    procedure actDesDictionaryExecute(Sender: TObject);
    procedure actDesGenericListExecute(Sender: TObject);
    procedure actDesGenericObjectListExecute(Sender: TObject);
    procedure actDesStreamableExecute(Sender: TObject);
    procedure actDesStreamablePropExecute(Sender: TObject);
    procedure actSerClassComplexExecute(Sender: TObject);
    procedure actSerClassFilterExecute(Sender: TObject);
    procedure actSerClassSimpleExecute(Sender: TObject);
    procedure actSerDictionaryExecute(Sender: TObject);
    procedure actSerGenericListExecute(Sender: TObject);
    procedure actSerGenericObjectListExecute(Sender: TObject);
    procedure actSerStreamableExecute(Sender: TObject);
    procedure actSerStreamablePropExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDelClassFilterExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesClassComplexExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesClassSimpleExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesDictionaryExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesGenericListExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesGenericObjectListExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesStreamableExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actDesStreamablePropExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerClassComplexExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerClassFilterExecute(Sender: TObject);
var
  LObj: TFilterClass;
begin
  LObj := TFilterClass.DefaultValues;
  try
    SerializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationComplex.actSerClassSimpleExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerDictionaryExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerGenericListExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerGenericObjectListExecute(Sender: TObject);
var
  LBook: TAddressBook;
begin
  LBook := TAddressBook.Create;
  try
    LBook.Add('Piacenza', 'Italy');
    LBook.Add('London', 'UK');
    LBook.NoteList.Add('Note 1');
    LBook.NoteList.Add('Note 2');
    LBook.NoteList.Add('Note 3');

    SerializeObject(LBook, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LBook.Free;
  end;
end;

procedure TfrmSerializationComplex.actSerStreamableExecute(Sender: TObject);
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

procedure TfrmSerializationComplex.actSerStreamablePropExecute(Sender: TObject);
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
