{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Demo.Forms.Main;

interface

uses
  System.Classes, System.SysUtils, System.Actions, System.ImageList,
  Vcl.Forms, Vcl.ActnList, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Controls,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage, Vcl.ImgList, Vcl.Graphics,

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
    imgMain: TImageList;
    procedure FormCreate(Sender: TObject);
  private
    procedure CreateTab(const ACaption: string; AIcon: Integer; AColor: TColor; AClass: TfrmSerializationClass);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Generics.Collections,

  Demo.Forms.Serialization.Custom, Demo.Forms.Serialization.Delphi,
  Demo.Forms.Serialization.Simple, Demo.Forms.Serialization.Records,
  Demo.Forms.Serialization.Schema, Demo.Forms.Serialization.Complex;

{ TMainForm }

procedure TMainForm.CreateTab(const ACaption: string; AIcon: Integer; AColor: TColor; AClass: TfrmSerializationClass);
var
  LTab: TTabSheet;
  LForm: TfrmSerializationBase;
begin
  LTab := TTabSheet.Create(pgcMain);
  LTab.Caption := ACaption;
  LTab.PageControl := pgcMain;
  LTab.ImageIndex := AIcon;

  LForm := AClass.CreateEx(Self, frmConfiguration, AColor);
  LForm.BorderStyle := bsNone;
  LForm.Parent := LTab;
  LForm.Align := alClient;
  LForm.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  frmConfiguration.Initialize;

  CreateTab('Simple Types', 0, clGreen, TfrmSerializationSimple);
  CreateTab('Value Types', 11, clTeal, TfrmSerializationRecords);
  CreateTab('Reference Types', 3, clNavy, TfrmSerializationComplex);
  CreateTab('Delphi Types', 9, clOlive, TfrmSerializationDelphi);
  CreateTab('Custom Serializers', 4, clMaroon, TfrmSerializationCustom);
  CreateTab('Attributes && JSON Schema', 16, clWebTan, TfrmSerializationSchema);
end;

end.
