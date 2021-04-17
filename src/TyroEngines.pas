unit TyroEngines;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, fgl,
  RayLib3, RayClasses,
  TyroClasses;

type
  { TTyroMain }

  TTyroMain = class(TObject)
  private
    //FBoard: TTyroImage;
    function GetActive: Boolean;
  protected
    FQueue: TQueueObjects;
    FScript: TTyroScript;
    FScriptTypes: TScriptTypes;
    FCanvasLock: TCriticalSection;
    FCanvas: TTyroCanvas;
  protected
    DefaultBackColor: raylib3.TColor;

  public
    Running: Boolean;
    WindowVisible: Boolean;
    Title: string;
    FileName: string;//that to run in script
    WorkSpace: string;
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure ProcessQueue;
    procedure Run;
    procedure Loop;
    property Canvas: TTyroCanvas read FCanvas;
    //property Board: TTyroImage read FBoard;
    property Active: Boolean read GetActive;

    procedure RegisterLanguage(ATitle: string; AExtention: string; AScriptClass: TTyroScriptClass);

    property Queue: TQueueObjects read FQueue;
    property ScriptTypes: TScriptTypes read FScriptTypes;
    procedure ShowWindow(W, H: Integer);
    procedure HideWindow;

    property CanvasLock: TCriticalSection read FCanvasLock;
  end;

var
  Main : TTyroMain = nil;

implementation

{ TTyroMain }

function TTyroMain.GetActive: Boolean;
begin
  Result := Running or ((FScript <> nil) and FScript.Active);
end;

procedure TTyroMain.ShowWindow(W, H: Integer);
begin
  //SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(W, H, PChar(Title));
  SetTargetFPS(cFramePerSeconds);
  ShowCursor();
  WindowVisible := True;
  FCanvas := TTyroCanvas.Create(W, H);
  //FBoard := TTyroImage.Create(W, H);
end;

procedure TTyroMain.HideWindow;
begin
  if WindowVisible then
    CloseWindow;
end;

procedure TTyroMain.ProcessQueue;
var
  p: TQueueObject;
  c: Integer;
  fpd: Double;
  ft, ft2: Double;
begin
  if Canvas <> nil then
  begin
    CanvasLock.Enter;
    try
      ft := GetTime();
      fpd := (1 / cFramePerSeconds);
      Canvas.BeginDraw;
      c := 0;
      while Queue.Count > 0 do
      begin
        Lock.Enter;
        try
          p := Queue.Extract(Queue[0]);
        finally
          Lock.Leave;
        end;
        p.Execute;
        p.Free;
        Inc(c);
        ft2 := GetTime() - ft;
        if ft2 >= fpd then
        begin
          break;
        end;
      end;
      Canvas.EndDraw;
    finally
      CanvasLock.Leave;
    end;
  end;
end;

constructor TTyroMain.Create;
begin
  inherited Create;
  FCanvasLock := TCriticalSection.Create;
  RayLib.Load;
  //SetTraceLog(LOG_DEBUG or LOG_INFO or LOG_WARNING);
  SetTraceLogLevel([LOG_ERROR, LOG_FATAL]);
  FQueue := TQueueObjects.Create(True);
  FScriptTypes := TScriptTypes.Create(true);
  {$IFDEF DARWIN}
  SetExceptionMask([exDenormalized,exInvalidOp,exOverflow,exPrecision,exUnderflow,exZeroDivide]);
  {$IFEND}
  DefaultBackColor := TColor.Create(220, 230, 240, 0);
end;

destructor TTyroMain.Destroy;
begin
  //Stop;
  HideWindow;
  FreeAndNil(FCanvas);
  //FreeAndNil(FBoard);
  FreeAndNil(FQueue);
  FreeAndNil(FScriptTypes);
  FreeAndNil(FCanvasLock);
  inherited Destroy;
end;

procedure TTyroMain.Start;
var
  ScriptType: TScriptType;
begin
  Running := True;
//ShowWindow(ScreenWidth, ScreenHeight); with option to show window /w
  if FileName <> '' then
  begin
    ScriptType := ScriptTypes.FindByExtension(ExtractFileExt(FileName));
    if ScriptType <> nil then
    begin
      FScript := ScriptType.ScriptClass.Create;
      if SysUtils.FileExists(FileName) then
      begin
        if LeftStr(FileName, 1) = '.' then
          FileName := ExpandFileName(WorkSpace + FileName);
        FScript.AssetsFolder := ExtractFilePath(FileName);
        FScript.LoadFile(FileName);
      end;
    end
    else
      Log('Type of file not found: ' + FileName);
  end;
end;

procedure TTyroMain.Run;
var
  t: TTexture2D;
  //im: TImage;
begin
  if (FScript <> nil) and FScript.Suspended then
    FScript.Start;

  if WindowVisible then
  begin
    if WindowShouldClose() then
    begin
      Running := False;
      if (FScript <> nil) then
        FScript.Terminate;
    end;

    ProcessQueue;

    CanvasLock.Enter;
    try
      BeginDrawing;
      ClearBackground(DefaultBackColor);

      {if Board <> nil then
      begin
        t := Board.LoadTexture;
        DrawTextureRec(t, TRectangle.Create(0, 0, t.width, t.height), TVector2.Create(0, 0), WHITE);
        UnloadTexture(t);
      end;}

      with Canvas.Texture do
        DrawTextureRec(texture, TRectangle.Create(0, 0, texture.width, -texture.height), Vector2Of(0, 0), WHITE);

      ThreadSwitch; //Yield
    finally
      CanvasLock.Leave;
    end;
    BeginDrawing;
    Loop;
    ThreadSwitch; //Yield
    EndDrawing;
    RayUpdates.Update;
  end;
end;

procedure TTyroMain.Loop;
begin
end;

procedure TTyroMain.RegisterLanguage(ATitle: string; AExtention: string; AScriptClass: TTyroScriptClass);
var
  Item: TScriptType;
begin
  Item := TScriptType.Create;
  Item.Title := ATitle;
  Item.Extention := AExtention;
  Item.ScriptClass := AScriptClass;
  FScriptTypes.Add(Item);
end;

procedure TTyroMain.Stop;
begin
  Running := False;
  if FScript <> nil then
  begin
    FScript.Terminate;
    FScript.WaitFor;
    FreeAndNil(FScript);
  end;
end;

end.
