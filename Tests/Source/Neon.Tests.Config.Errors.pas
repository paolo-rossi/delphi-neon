{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.Errors;

interface

uses
  System.SysUtils, System.Classes, System.Rtti,
  DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Types;

type
  TBoomEntity = class
  public
    function GetExplode: string;
    property Explode: string read GetExplode;
  end;

  TBoomEntityHolder = class
  private
    FBoom: TBoomEntity;
  public
    property Boom: TBoomEntity read FBoom write FBoom;
  end;

  TAbstractStreamHolder = class
  private
    FStream: TStream;
  public
    property Stream: TStream read FStream write FStream;
  end;

  /// <summary>
  ///   With RaiseExceptions off (the default) a member that fails is logged and
  ///   skipped, and the TNeon facade frees the serializer - and its error list -
  ///   before returning: the error handler on the configuration is the only way
  ///   for such a caller to know that it happened
  /// </summary>
  [TestFixture]
  [Category('configerrors')]
  TTestConfigErrors = class(TObject)
  private
    FErrors: TStringList;
    FOperation: TNeonOperation;
    FCalls: Integer;

    /// <summary>
    ///   A configuration whose errors land in FErrors
    /// </summary>
    function ConfigWithHandler(const AConfig: INeonConfiguration): INeonConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHandlerSeesTheSkippedMember;

    [Test]
    procedure TestHandlerSeesTheDeserializeError;

    [Test]
    procedure TestHandlerIsSilentWhenNothingFails;

    [Test]
    procedure TestHandlerAlsoRunsWhenRaising;
  end;

implementation

uses
  Neon.Core.Serializers.RTL;

{ TBoomEntity }

function TBoomEntity.GetExplode: string;
begin
  raise ENeonException.Create('boom');
end;

{ TTestConfigErrors }

function TTestConfigErrors.ConfigWithHandler(const AConfig: INeonConfiguration): INeonConfiguration;
begin
  Result := AConfig.SetOnError(
    procedure (const AMessage: string; AOperation: TNeonOperation)
    begin
      FErrors.Add(AMessage);
      FOperation := AOperation;
      Inc(FCalls);
    end);
end;

procedure TTestConfigErrors.Setup;
begin
  FErrors := TStringList.Create;
  FCalls := 0;
end;

procedure TTestConfigErrors.TearDown;
begin
  FErrors.Free;
end;

procedure TTestConfigErrors.TestHandlerSeesTheSkippedMember;
var
  LHolder: TBoomEntityHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := ConfigWithHandler(TNeonConfiguration.Default);

  LHolder := TBoomEntityHolder.Create;
  try
    LHolder.Boom := TBoomEntity.Create;
    try
      // The failing member is still dropped, but no longer in silence
      Assert.AreEqual('{"Boom":{}}', TNeon.ObjectToJSONString(LHolder, LConfig));
    finally
      LHolder.Boom.Free;
    end;
  finally
    LHolder.Free;
  end;

  Assert.AreEqual(1, FCalls);
  Assert.Contains(FErrors[0], 'Explode');
  Assert.IsTrue(FOperation = TNeonOperation.Serialize);
end;

procedure TTestConfigErrors.TestHandlerSeesTheDeserializeError;
var
  LHolder: TAbstractStreamHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := ConfigWithHandler(TNeonConfiguration.Create);
  LConfig.GetSerializers.RegisterSerializer(TStreamSerializer);

  LHolder := TAbstractStreamHolder.Create;
  try
    // The abstract TStream member cannot be created, so the member is skipped
    // instead of being handed to the serializer as nil (A2)
    TNeon.JSONToObject(LHolder, '{"Stream":"aGVsbG8="}', LConfig);
    Assert.IsNull(LHolder.Stream);
  finally
    LHolder.Free;
  end;

  Assert.AreEqual(1, FCalls);
  Assert.Contains(FErrors[0], 'TStream');
  Assert.IsTrue(FOperation = TNeonOperation.Deserialize);
end;

procedure TTestConfigErrors.TestHandlerIsSilentWhenNothingFails;
var
  LHolder: TBoomEntityHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := ConfigWithHandler(TNeonConfiguration.Default);

  LHolder := TBoomEntityHolder.Create;
  try
    // No Boom instance, so no member fails: a nil object member is omitted
    // under the default IncludeIf.NotNull, which is not an error
    Assert.AreEqual('{}', TNeon.ObjectToJSONString(LHolder, LConfig));
  finally
    LHolder.Free;
  end;

  Assert.AreEqual(0, FCalls);
end;

procedure TTestConfigErrors.TestHandlerAlsoRunsWhenRaising;
var
  LHolder: TBoomEntityHolder;
  LConfig: INeonConfiguration;
begin
  LConfig := ConfigWithHandler(TNeonConfiguration.Default.SetRaiseExceptions(True));

  LHolder := TBoomEntityHolder.Create;
  try
    LHolder.Boom := TBoomEntity.Create;
    try
      // The member is logged before the error is re-raised, so the handler sees
      // the member that failed and the caller gets the exception
      Assert.WillRaise(
        procedure begin TNeon.ObjectToJSONString(LHolder, LConfig) end,
        ENeonException);
    finally
      LHolder.Boom.Free;
    end;
  finally
    LHolder.Free;
  end;

  Assert.IsTrue(FCalls > 0);
  Assert.Contains(FErrors[0], 'Explode');
end;

end.
