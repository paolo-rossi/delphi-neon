unit Demo.Forms.Serialization.Schema;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList, Vcl.CategoryButtons,
  System.JSON, System.Rtti,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON.Schema,
  Neon.Core.Utils;

type
  TfrmSerializationSchema = class(TfrmSerializationBase)
    actSerJSONSchema: TAction;
    actSerAttrUnwrapped: TAction;
    actDesAttrUnwrapped: TAction;
    actSerMiscTValueDict: TAction;
    actSerMiscTValue: TAction;
    actDesMiscTValue: TAction;
    actDesMiscTValueDict: TAction;
    procedure actDesAttrUnwrappedExecute(Sender: TObject);
    procedure actDesMiscTValueDictExecute(Sender: TObject);
    procedure actDesMiscTValueExecute(Sender: TObject);
    procedure actSerAttrUnwrappedExecute(Sender: TObject);
    procedure actSerJSONSchemaExecute(Sender: TObject);
    procedure actSerMiscTValueDictExecute(Sender: TObject);
    procedure actSerMiscTValueExecute(Sender: TObject);
  private
    function BuildConfig: INeonConfiguration;
  public
    { Public declarations }
  end;

var
  frmSerializationSchema: TfrmSerializationSchema;

implementation

uses
  Demo.Neon.Entities, Neon.Core.Persistence.JSON;

{$R *.dfm}

procedure TfrmSerializationSchema.actDesAttrUnwrappedExecute(Sender: TObject);
var
  LObj: TUnwrappedClass;
begin
  LObj := TUnwrappedClass.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, BuildConfig);
    SerializeObject(LObj, memoDeserialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationSchema.actDesMiscTValueDictExecute(Sender: TObject);
var
  LDict: TExtension;
begin
  LDict := TExtension.Create;
  try
    DeserializeObject(LDict, memoSerialize.Lines, BuildConfig);
    SerializeObject(LDict, memoDeserialize.Lines, BuildConfig);
  finally
    LDict.Free;
  end;
end;

procedure TfrmSerializationSchema.actDesMiscTValueExecute(Sender: TObject);
var
  LValue: TValue;
begin
  LValue := TValue.Empty;
  DeserializeSimple<TValue>(LValue);
end;

procedure TfrmSerializationSchema.actSerAttrUnwrappedExecute(Sender: TObject);
var
  LObj: TUnwrappedClass;
begin
  LObj := TUnwrappedClass.Sample1;
  try
    SerializeObject(LObj, memoSerialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationSchema.actSerJSONSchemaExecute(Sender: TObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TNeonSchemaGenerator.ClassToJSONSchema(TCaseClass);
  try
    memoSerialize.Lines.Text := TNeon.Print(LJSON, True);
  finally
    LJSON.Free;
  end;
end;

procedure TfrmSerializationSchema.actSerMiscTValueDictExecute(Sender: TObject);
var
  LExt: TExtension;
begin
  LExt := TExtension.Create();
  try
    LExt.Add('first', 'string value');
    LExt.Add('second', 123);
    LExt.Add('third', True);
    SerializeObject(LExt, memoSerialize.Lines, BuildConfig);
  finally
    LExt.Free;
  end;
end;

procedure TfrmSerializationSchema.actSerMiscTValueExecute(Sender: TObject);
var
  LValue: TValue;
begin
  LValue := 42;

  //SerializeSimple(10);
  SerializeSimple(LValue);
  //SerializeSimple(TValue.From<TValue>(LValue));
end;

function TfrmSerializationSchema.BuildConfig: INeonConfiguration;
begin
  Result := frmConfiguration.BuildSerializerConfig([TSerializersType.CustomNeon]);
end;

end.
