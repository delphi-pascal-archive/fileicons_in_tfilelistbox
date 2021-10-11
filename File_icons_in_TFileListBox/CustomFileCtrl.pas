(*

  Unit� : CustomFileCtrl

  Comment mettre d'autres ic�nes dans TFileListBox

  J'en ai profit� pour modifier �galement  TDirectoryListBox et  TDriveComboBox

  ceci sans installation suppl�mentaire de composants.

  Il suffit simplement d'ajouter "CustomFileCtrl" dans les uses
  (dans la partie Interface) de l'unit� et surtout apr�s FileCtrl (Voir D�mo)

  Les modifications ne sont pas visible en mode Designe Time
  Uniquement en mode Run Time

*)
unit CustomFileCtrl;

interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, FileCtrl, ShellApi;

Type
  { TFileListBox }

  TFileListBox = class(FileCtrl.TFileListBox)
  private
    FFileData  : Array Of TSHFileInfo;
    procedure CMHintShow(var Message: TMessage); message CM_HINTSHOW;
    Procedure FreeArray;
    Procedure InitArray(NewLength : Integer);
  protected
    Procedure ReadFileNames; Override;
    Procedure DrawItem(Index: Integer; aRect: TRect; State: TOwnerDrawState);  Override;
  public
    Destructor Destroy; override;
  End;

  TDirectoryListBox = class(FileCtrl.TDirectoryListBox)
  protected
    procedure ReadBitmaps; Override;
  End;

  TDriveComboBox = class(FileCtrl.TDriveComboBox)
  protected
    procedure BuildList; Override;
  End;


  
Implementation
Const DataHint = 'Name : %s' +#13#10+
                 'Type : %s';
{ TFileListBox }

{Procedure qui intercepte le message CM_HINTSHOW
on s'en sert pour red�finir le message qui sera affich� � chaque click
sur un �l�ment de la FileLisBox (ShowHint doit �tre a True) }
procedure TFileListBox.CMHintShow(var Message: TMessage);
begin
  If ItemIndex > -1 Then
  With FFileData[ItemIndex] Do
  TCMHintShow(Message).HintInfo^.HintStr := Format(DataHint, [szDisplayName,
    szTypeName]);
  Inherited;
end;

Destructor TFileListBox.Destroy;
begin
  FreeArray;
  Inherited Destroy;
end; 

{Procedure qui dessine les Ic�nes et le texte}
Procedure TFileListBox.DrawItem(Index: Integer; aRect: TRect;
  State: TOwnerDrawState);
var
  offset: Integer;
begin
    Canvas.FillRect(aRect);
    offset := 2;
    if ShowGlyphs then
    begin
      With aRect do
        DrawIconEx(Canvas.Handle, Left + Offset, (Top + Bottom - ItemHeight) div 2, FFileData[Index].hIcon, ItemHeight, ItemHeight, 0, 0, DI_NORMAL	);
        offset := ItemHeight + 6;
    end;
    OffsetRect(aRect, Offset, 0);
    DrawText(Canvas.Handle, PChar(Items[Index]), -1 , aRect, DT_VCENTER or DT_SINGLELINE or DT_LEFT);
End;

{Procedure qui lib�re les Handles des Ic�nes si il y en a
et r� initialise la taille du tableau � z�ro}
procedure TFileListBox.FreeArray;
Var I : Integer;
begin
  For I := Low(FFileData) To High(FFileData) Do
    If FFileData[I].hIcon > 0 Then DestroyIcon(FFileData[I].hIcon);
  InitArray(0);
end;

{Procedure qui initialise la taille du tableau � NewLength}
procedure TFileListBox.InitArray(NewLength: Integer);
begin
  SetLength(FFileData, NewLength);
end;

{Ici on surcharge la procedure qui r�cup�re les noms des fichiers dans les r�pertoires
afin d'y ajouter les ic�nes}
Procedure TFileListBox.ReadFileNames;
Var I        : Integer;
Begin
  Inherited;{on fait appel � la m�thode h�rit�e}
  FreeArray;{Lib�re les Ic�nes}
  InitArray(Items.Count);{Initialise le tableau en fonction du nombre d'Items}
  For I := 0 to Items.Count - 1 Do {R�colte des nouvelles donn�es}
    SHGetFileInfo(PChar(Items[I]), 0, FFileData[I],
      SizeOf(TSHFileInfo), SHGFI_DISPLAYNAME Or SHGFI_TYPENAME Or SHGFI_ICON
      Or SHGFI_SMALLICON );
End;

{D�finition d'un Type TBitmapStyle pour charger les diff�rents �tats d'une ic�ne
 uniquement utilis� par TDirectoryListBox}
Type
  TBitmapStyle = (bsNormal, bsOpened, bsSelected);

{Procedure qui est utilis� par TDirectoryListBox et TDriveComboBox
pour "modifier" les Bitmaps d'origine}
Procedure SetBmp(Const Location : String; Var Bmp : TBitmap; Const Style : TBitmapStyle = bsNormal);
Var FileInfo : TSHFileInfo;
    aBmp     : tBitmap;
    Flags    : Cardinal;
begin
 Flags := SHGFI_ICON Or SHGFI_LARGEICON;
 Case Style of
   bsOpened :Flags := Flags Or SHGFI_OPENICON;
   bsSelected :Flags := Flags Or SHGFI_OPENICON Or SHGFI_SELECTED;
 End;
 If SHGetFileInfo(PChar(Location), 0, FileInfo, SizeOf(FileInfo), Flags) <> 0
 Then Begin
 aBmp := TBitmap.Create;
 Try
   With aBmp do Begin
     Width  := 32;
     Height := 32;
     Canvas.Brush.Color := clBtnFace;
     Canvas.FillRect(Rect(0, 0, Width, Height));
     DrawIconEx(Canvas.Handle, 0, 0, FileInfo.hIcon, Width, Height, 0, 0, DI_NORMAL);
   End;
   With Bmp do Begin
     SetStretchBltMode(Canvas.Handle, HALFTONE);
     StretchBlt(Canvas.Handle, 0, 0, Width, Height, aBmp.Canvas.Handle, 0, 0,
       aBmp.Width, aBmp.Height, srcCopy);
   End;
 Finally
   DestroyIcon(FileInfo.hIcon);
   aBmp.Free;
 End;
 End;
end;

{ TDirectoryListBox }

{Surcharge de la procedure qui charge les Bitmaps
 Ici on ne fait pas appel � la m�thode h�rit�e
 La m�thode initiale est remplac�e par celle-ci}
procedure TDirectoryListBox.ReadBitmaps;
  Function BmpCreate : TBitmap;
  Begin
    Result := TBitmap.Create;
    With Result do Begin
      Width  := 16;
      Height := 16;
    End;
  End;
Var aDir : String;
begin
  aDir := GetCurrentDir;
  OpenedBMP := BmpCreate;
  SetBmp(aDir, OpenedBMP, bsOpened);
  ClosedBMP := BmpCreate;
  SetBmp(aDir, ClosedBMP);
  CurrentBMP := BmpCreate;
  SetBmp(aDir, CurrentBMP, bsSelected);
end;

{ TDriveComboBox }

{Comme dans TDriveComboBox la m�thode ReadBitmaps n'est pas "Virtual"
j'utilise une autre m�thode pour modifier les Bitmaps}
procedure TDriveComboBox.BuildList;
Var BoolDrvType : Array[TDriveType] of Boolean;
    I : Integer;
    DrvType: TDriveType;
    Buffer : Array[0..104] of Char;
    P      : PChar;
    Len    : DWord;
begin
  {Appel de la m�thode h�rit�e}
  Inherited;
  {On fait pointer P sur Buffer}
  P := Buffer;
  {Initialise le buffer � z�ro}
  ZeroMemory(P, SizeOf(Buffer));
  {R�cup�ration des noms de lecteurs et le nombre de caract�res r�cup�r� dans
   le buffer sans le dernier z�ro terminal}
  Len := GetLogicalDriveStrings(SizeOf(Buffer), P);
  {Chaque lecteur est sur 3 caract�res plus le z�ro terminal Ex: C:\#0}
  Len := Len Div 4;
  For I := 1 to Len Do Begin
    {R�cup�re le Type du lecteur}
    DrvType := TDriveType(GetDriveType(P));

    {Si le Bitmap n'est pas encore modifi� }
    If Not BoolDrvType[DrvType] Then Begin
      Case DrvType Of
        dtFloppy:   SetBmp(P, FloppyBmp);
        dtFixed:    SetBmp(P, FixedBmp);
        dtNetwork:  SetBmp(P, NetworkBmp);
        dtCDRom:    SetBmp(P, CDRomBmp);
        dtRam:      SetBmp(P, RamBmp);
      End; {Case}
      BoolDrvType[DrvType] := True;
    End;
    {On passe au lecteur suivant}
    Inc(P, 4);
  End;
end;

End.
