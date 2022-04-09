unit TyroControls;
{**
 *  This file is part of the "Tyro"
 *
 * @license   MIT
 *
 * @author    Zaher Dirkey 
 *
 *}

{$ifdef FPC}
{$mode delphi}
{$H+}{$M+}
{$endif}

interface

uses
  Classes, SysUtils, Types,
  mnUtils, mnClasses,
  {$ifdef FPC}
  LCLType,
  {$endif}
  SyncObjs, //after LCLType
  RayLib, RayClasses,
  TyroClasses;

type
  {$ifdef FPC}
  TUTF8Char = LCLType.TUTF8Char;
  {$else}
  TUTF8Char = String[7]; //* ported from LCLType;
  {$endif}

  TMouseButton = (mbLeft, mbRight, mbMiddle);

  TScrollbarType = (sbtHorizontal, sbtVertical);
  TScrollbarTypes = set of TScrollbarType;

  TScrollCode = (
    scrollTOP,
    scrollBOTTOM,
    scrollLINEDOWN,
    scrollLINEUP,
    scrollPAGEDOWN,
    scrollPAGEUP,
    scrollTHUMBPOSITION,
    scrollTHUMBTRACK,
    scrollENDSCROLL
  );

  TTyroControlState = (csCreating, csCreated, csDestroying);
  TTyroControlStates = set of TTyroControlState;

  TTyroContainer = class;
  TTyroControl = class;
  TTyroCustomWindow = class;

  TTyroControls = class(TmnObjectList<TTyroControl>)
  public
  end;

  { TTyroContainer }

  TTyroContainer = class abstract(TObject)
  private
    FControls: TTyroControls;
  protected
    procedure AddControl(AControl: TTyroControl);
  public
    constructor Create;
    destructor Destroy; override;
    property Controls: TTyroControls read FControls;
  end;

  TTyroSizable = class abstract(TTyroContainer)
  private
    FBoundsRect: TRect;
  protected
    procedure SetBoundsRect(AValue: TRect);
    function GetHeight: Integer;
    procedure SetHeight(AValue: Integer);
    function GetWidth: Integer;
    procedure SetWidth(AValue: Integer);
    procedure SetBounds(Left, Top, Width, Height: Integer); virtual;
    procedure SetLeft(AValue: Integer);
    procedure SetTop(AValue: Integer);
    procedure Resize; virtual;
  public
    property BoundsRect: TRect read FBoundsRect write SetBoundsRect;
    property Left: Integer read FBoundsRect.Left write SetLeft;
    property Top: Integer read FBoundsRect.Top write SetTop;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
  end;

  { TTyroControl }

  TTyroControl = class abstract(TTyroSizable)
  private
    FWindow: TTyroCustomWindow;
    FParent: TTyroContainer;
    FVisible: Boolean;
    function GetFocused: Boolean;
    procedure SetFocused(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
    procedure SetWindow(AValue: TTyroCustomWindow);
    procedure SetParent(AValue: TTyroContainer);
  protected
    State: TTyroControlStates;
    function GetClientRect: TRect;
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;

    procedure ShowScrollBar(Which: TScrollbarTypes; Visible: Boolean);
    procedure SetScrollRange(Which: TScrollbarType; AMin, AMax: Integer; APage: Integer);
    procedure SetScrollPosition(Which: TScrollbarType; AValue: Integer; Visible: Boolean);
    procedure Scroll(Witch: TScrollbarType; ScrollCode: TScrollCode; Pos: Integer); virtual;

    procedure DoPaintBackground(ACanvas: TTyroCanvas); virtual;
    procedure DoPaint(ACanvas: TTyroCanvas); virtual;

    procedure Created; virtual;
    property Window: TTyroCustomWindow read FWindow write SetWindow;
  public
    constructor Create(AParent: TTyroContainer); virtual;
    destructor Destroy; override;
    procedure Invalidate; virtual;

    procedure Paint(ACanvas: TTyroCanvas);

    procedure FocusChanged; virtual;
    property Parent: TTyroContainer read FParent write SetParent;
    procedure Show;
    procedure Hide;

    procedure KeyPress(var Key: TUTF8Char); virtual;
    procedure KeyDown(var Key: TKeyboardKey; Shift: TShiftState); virtual;
    procedure KeyUp(var Key: TKeyboardKey; Shift: TShiftState); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: integer); virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; x, y: integer); virtual;
    procedure MouseMove(Shift: TShiftState; x, y: integer); virtual;

    property Focused: Boolean read GetFocused write SetFocused;
    property ClientRect: TRect read GetClientRect;
    property ClientWidth: Integer read GetClientWidth;
    property ClientHeight: Integer read GetClientHeight;
    property Visible: Boolean read FVisible write SetVisible;
  end;

  { TTyroPanel }

  TTyroPanel = class(TTyroControl)
  public
    constructor Create(AParent: TTyroContainer); override;
    procedure DoPaint(ACanvas: TTyroCanvas); override;
  end;

  { TTyroTexture }

  TTyroTextureControl = class(TTyroControl) //Own a texture
  private
    FCanvas: TTyroTextureCanvas;
    procedure SetCanvas(AValue: TTyroTextureCanvas);
  public
    //TODO
    constructor Create(AParent: TTyroContainer); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    procedure Draw; virtual;
    procedure Resize; override;
    property Canvas: TTyroTextureCanvas read FCanvas write SetCanvas;
  end;

  { TTyroCustomWindow }

  TTyroCustomWindow = class abstract(TTyroSizable)
  private
    FCanvas: TTyroCanvas;
    FFocused: TTyroControl;
    FTitle: utf8string;
    procedure SetCanvas(AValue: TTyroCanvas);
    procedure SetFocused(AValue: TTyroControl);
    procedure SetTitle(AValue: utf8string);
  protected
    Margin: Integer;
    procedure PrepareCanvas; virtual;
    function CreateCanvas: TTyroCanvas; virtual; abstract;
  public
    Visible: Boolean;
    constructor Create; overload;
    constructor Create(AWidth, AHeight: Integer); overload;
    destructor Destroy; override;
    procedure Paint;
    property Canvas: TTyroCanvas read FCanvas write SetCanvas;
    property Title: utf8string read FTitle write SetTitle;
    property Focused: TTyroControl read FFocused write SetFocused;
  end;

  TTyroWindow = class(TTyroCustomWindow)
  protected
    function CreateCanvas: TTyroCanvas; override;
  public
  end;

  TTyroMainOption = (moWindow, moOpaque, moShowFPS);
  TTyroMainOptions= set of TTyroMainOption;

  { TTyroMain }

  TTyroMain = class(TTyroCustomWindow)
  private
    FFPS: Integer;
    FOptions: TTyroMainOptions;
  protected
    IsTerminated: Boolean;
    FCanvasLock: TCriticalSection;
    function CreateCanvas: TTyroCanvas; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ShowWindow(AWidth, AHeight: Integer); virtual;
    procedure SetFPS(FPS: Integer); virtual;
    procedure HideWindow; virtual;

    procedure Init; virtual;
    procedure Preload; virtual;
    function Terminated: Boolean;
    procedure Setup; virtual;
    procedure Shutdown; virtual;
    procedure PrepareDraw; virtual;
    procedure Draw; virtual;
    procedure Loop; virtual;
    procedure Terminate; virtual;
    procedure Unload; virtual;

    procedure Run;

    property CanvasLock: TCriticalSection read FCanvasLock;
    property Options: TTyroMainOptions read FOptions write FOptions;
    property FPS: Integer read FFPS write SetFPS;
  end;

const
  cDefaultWindowWidth = 640;
  cDefaultWindowHeight = 480;

var
  Main: TTyroMain = nil;

function Canvas: TTyroCanvas; inline;

implementation

{ TTyroMain }

function Canvas: TTyroCanvas;
begin
  Result := Main.Canvas;
end;

constructor TTyroMain.Create;
begin
  inherited;
  FOptions := [moWindow, moOpaque];
  WorkSpace := ExtractFilePath(ParamStr(0));
  RayLibrary.Load;
  FCanvasLock := TCriticalSection.Create;
end;

function TTyroMain.CreateCanvas: TTyroCanvas;
begin
  Result := TTyroMainCanvas.Create(Width, Height);
end;

destructor TTyroMain.Destroy;
begin
  FreeAndNil(FCanvasLock);
  inherited;
end;

function TTyroMain.Terminated: Boolean;
begin
  Result := IsTerminated;
end;

procedure TTyroMain.Preload;
begin
end;

procedure TTyroMain.SetFPS(FPS: Integer);
begin
  FFPS := FPS;
  SetTargetFPS(FPS);
end;

procedure TTyroMain.Setup;
begin

end;

procedure TTyroMain.Shutdown;
begin

end;

procedure TTyroMain.PrepareDraw;
begin

end;

procedure TTyroMain.Draw;
begin
end;

procedure TTyroMain.Loop;
begin
end;

procedure TTyroMain.Run;
begin
  Init;
  if not Visible and (moWindow in Options) then
  begin
    ShowWindow(cDefaultWindowWidth, cDefaultWindowHeight);
    SetFPS(cFramePerSeconds);
  end;

  Preload;
  Setup;
  if FPS = 0 then
    SetFPS(cFramePerSeconds);
  repeat
    try
      CheckSynchronize;
      if WindowShouldClose() then
      begin
        Shutdown;
        Terminate;
      end
      else
      begin
        if Visible then
        begin
          PrepareDraw;
          Canvas.BeginDraw;
          if moOpaque in Options then
            Canvas.Clear;

          try
            Paint;
            Draw;
            if moShowFPS in Options then
              RayLib.DrawFPS(10, 10);
            //Canvas.DrawLine(10, 10, 100, 10, clRed);
            //Canvas.DrawText(2, 2, 'Test', clRed);

          finally
            Canvas.EndDraw;
          end;
        end;
      end;
      Loop;
      RayUpdates.Update;
    finally
    end;
  until Terminated;
  Unload;
  if Visible then
    RayLib.CloseWindow();
end;

procedure TTyroMain.ShowWindow(AWidth, AHeight: Integer);
begin
  if Visible then
  begin
    SetBounds(0, 0, AWidth, AHeight);
    SetWindowSize(AWidth, AHeight);
  end
  else
  begin
    //SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    SetBounds(0, 0, AWidth, AHeight);
    InitWindow(AWidth, AHeight, PUTF8Char(Title));
    ShowCursor();
    PrepareCanvas;
  end;
  Visible := True;
end;

procedure TTyroMain.HideWindow;
begin
  if Visible then
    CloseWindow;
end;

procedure TTyroMain.Init;
begin

end;

procedure TTyroMain.Terminate;
begin
  IsTerminated := True;
end;

procedure TTyroMain.Unload;
begin

end;

{ TTyroTextureControl }

procedure TTyroTextureControl.SetCanvas(AValue: TTyroTextureCanvas);
begin
  if FCanvas =AValue then Exit;
  FCanvas :=AValue;
end;

constructor TTyroTextureControl.Create(AParent: TTyroContainer);
begin
  inherited Create(AParent);
  FCanvas := TTyroTextureCanvas.Create(Width, Height);
end;

destructor TTyroTextureControl.Destroy;
begin
  FreeAndNil(FCanvas);
  inherited Destroy;
end;

procedure TTyroTextureControl.Invalidate;
begin
  inherited Invalidate;
  Paint(Canvas);
end;

procedure TTyroTextureControl.Draw;
begin
  with Canvas.Texture do
    DrawTextureRec(Texture, TRectangle.Create(0, 0, texture.width, -texture.height), Vector2Of(0, 0), clWhite);
end;

procedure TTyroTextureControl.Resize;
begin
  Canvas.Width := Width;
  Canvas.Height := Height;
  inherited Resize;
end;

{ TTyroContainer }

procedure TTyroContainer.AddControl(AControl: TTyroControl);
begin
  Controls.Add(AControl);
end;

constructor TTyroContainer.Create;
begin
  inherited Create;
  FControls := TTyroControls.Create(True);
end;

destructor TTyroContainer.Destroy;
var
  aControl: TTyroControl;
begin
  aControl := Controls.Last;
  while aControl <> nil do
  begin
    aControl.FParent := nil;
    Controls.Extract(aControl);
    aControl.Free;
    aControl := Controls.Last;
  end;
  FreeAndNil(FControls);
  inherited;
end;

{ TTyroCustomWindow }

constructor TTyroPanel.Create(AParent: TTyroContainer);
begin
  inherited;
  FBoundsRect.Right := 100;
  FBoundsRect.Bottom := 100;
end;

procedure TTyroPanel.DoPaint(ACanvas: TTyroCanvas);
begin
  inherited;
  ACanvas.DrawRectangle(ClientRect, ACanvas.BackColor, True);
end;

{ TTyroControl }

procedure TTyroSizable.SetBoundsRect(AValue: TRect);
begin
  if FBoundsRect = AValue then Exit;
  FBoundsRect := AValue;
  Resize;
end;

function TTyroSizable.GetHeight: Integer;
begin
  Result := FBoundsRect.Height;
end;

function TTyroSizable.GetWidth: Integer;
begin
  Result := FBoundsRect.Width;
end;

procedure TTyroSizable.SetHeight(AValue: Integer);
begin
  FBoundsRect.Height := AValue;
  Resize;
end;

procedure TTyroSizable.SetLeft(AValue: Integer);
begin
  FBoundsRect.Left := AValue;
  Resize;
end;

procedure TTyroSizable.SetTop(AValue: Integer);
begin
  FBoundsRect.Top := AValue;
  Resize;
end;

procedure TTyroSizable.SetWidth(AValue: Integer);
begin
  FBoundsRect.Width := AValue;
  Resize;
end;

procedure TTyroSizable.SetBounds(Left, Top, Width, Height: Integer);
begin
  FBoundsRect := Rect(Left, Top, Left + Width, Top + Height);
end;

procedure TTyroSizable.Resize;
begin

end;

function TTyroControl.GetFocused: Boolean;
begin
  Result := (Window <> nil) and (Window.Focused = Self);
end;

procedure TTyroControl.SetFocused(AValue: Boolean);
begin
  if Window <> nil then
    Window.Focused := Self;
end;

procedure TTyroControl.SetVisible(AValue: Boolean);
begin
  if FVisible =AValue then Exit;
  FVisible :=AValue;
  Invalidate;
end;

procedure TTyroControl.SetWindow(AValue: TTyroCustomWindow);
begin
  if FWindow =AValue then Exit;
  FWindow :=AValue;
end;

procedure TTyroControl.SetParent(AValue: TTyroContainer);
begin
  if FParent =AValue then
    Exit;
  if FParent <> nil then
    FParent.Controls.Extract(Self);
  FParent :=AValue;
  if FParent <> nil then
    FParent.AddControl(Self);
end;

function TTyroControl.GetClientRect: TRect;
begin
  Result := Rect(0, 0, Width, Height);
end;

function TTyroControl.GetClientWidth: Integer;
begin
  Result := ClientRect.Width;
end;

function TTyroControl.GetClientHeight: Integer;
begin
  Result := ClientRect.Height;
end;

procedure TTyroControl.ShowScrollBar(Which: TScrollbarTypes; Visible: Boolean);
begin

end;

procedure TTyroControl.SetScrollRange(Which: TScrollbarType; AMin, AMax: Integer; APage: Integer);
begin

end;

procedure TTyroControl.SetScrollPosition(Which: TScrollbarType; AValue: Integer; Visible: Boolean);
begin

end;

procedure TTyroControl.Scroll(Witch: TScrollbarType; ScrollCode: TScrollCode; Pos: Integer);
begin

end;

procedure TTyroControl.Invalidate;
begin

end;

procedure TTyroControl.Paint(ACanvas: TTyroCanvas);
begin
  if Visible then
  begin
    ACanvas.SetOrigin(Left, Top);
    try
      DoPaintBackground(ACanvas);
      DoPaint(ACanvas)
    finally
      ACanvas.ResetOrigin;
    end;
  end;
end;

procedure TTyroControl.FocusChanged;
begin
end;

procedure TTyroControl.Show;
begin
  Visible := True;
end;

procedure TTyroControl.Hide;
begin
  Visible := False;
end;

procedure TTyroControl.DoPaintBackground(ACanvas: TTyroCanvas);
begin

end;

procedure TTyroControl.DoPaint(ACanvas: TTyroCanvas);
begin

end;

procedure TTyroControl.KeyPress(var Key: TUTF8Char);
begin

end;

procedure TTyroControl.KeyDown(var Key: TKeyboardKey; Shift: TShiftState);
begin

end;

procedure TTyroControl.KeyUp(var Key: TKeyboardKey; Shift: TShiftState);
begin

end;

procedure TTyroControl.MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: integer);
begin

end;

procedure TTyroControl.MouseUp(Button: TMouseButton; Shift: TShiftState; x, y: integer);
begin

end;

procedure TTyroControl.MouseMove(Shift: TShiftState; x, y: integer);
begin

end;

procedure TTyroControl.Created;
begin
end;

constructor TTyroControl.Create(AParent: TTyroContainer);
begin
  inherited Create;
  State := State + [csCreating];
  FParent := AParent;
  if Parent <> nil then
    Parent.AddControl(Self);
  if (Parent is TTyroCustomWindow) then
    FWindow := (Parent as TTyroCustomWindow);
  FVisible := True;
  Created;
  State := State - [csCreating] + [csCreated];
end;

destructor TTyroControl.Destroy;
begin
  State := State - [csCreating, csCreated] + [csDestroying];
  if Parent <> nil then
    Parent := nil;
  inherited;
end;

{ TTyroCustomWindow }

procedure TTyroCustomWindow.SetTitle(AValue: utf8string);
begin
  if FTitle =AValue then Exit;
  FTitle :=AValue;
end;

procedure TTyroCustomWindow.PrepareCanvas;
begin
  if FCanvas = nil then
    FCanvas := CreateCanvas;
end;

constructor TTyroCustomWindow.Create(AWidth, AHeight: Integer);
begin
  Create;
  Width := AWidth;
  Height := AHeight;
end;

procedure TTyroCustomWindow.SetFocused(AValue: TTyroControl);
begin
  if FFocused =AValue then Exit;
  if FFocused <> nil then
    FFocused.FocusChanged;
  FFocused :=AValue;
  if FFocused <> nil then
    FFocused.FocusChanged;
end;

procedure TTyroCustomWindow.SetCanvas(AValue: TTyroCanvas);
begin
  if FCanvas =AValue then Exit;
  FCanvas :=AValue;
end;

constructor TTyroCustomWindow.Create;
begin
  inherited Create;
end;

destructor TTyroCustomWindow.Destroy;
begin
  FreeAndNil(FCanvas);
  inherited Destroy;
end;

procedure TTyroCustomWindow.Paint;
var
  aControl: TTyroControl;
begin
  if Visible then
  begin
    try
      for aControl in Controls do
      begin
        aControl.Paint(Canvas);
      end;

    finally
    end;
  end;
end;

{ TTyroWindow }

function TTyroWindow.CreateCanvas: TTyroCanvas;
begin
  Result := TTyroTextureCanvas.Create(Width, Height);
end;

initialization
  Randomize;
finalization
  FreeAndNil(Main);
end.

