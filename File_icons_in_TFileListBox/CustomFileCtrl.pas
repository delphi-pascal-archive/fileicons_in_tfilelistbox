(*

  Unité : CustomFileCtrl

  Comment mettre d'autres icônes dans TFileListBox

  J'en ai profité pour modifier également  TDirectoryListBox et  TDriveComboBox

  ceci sans installation supplémentaire de composants.

  Il suffit simplement d'ajouter "CustomFileCtrl" dans les uses
  (dans la partie Interface) de l'unité et surtout après FileCtrl (Voir Démo)

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
on s'en sert pour redéfinir le message qui sera affiché à chaque click
sur un élément de la FileLisBox (ShowHint doit être a True) }
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

{Procedure qui dessine les Icônes et le texte}
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

{Procedure qui libère les Handles des Icônes si il y en a
et ré initialise la taille du tableau à zéro}
procedure TFileListBox.FreeArray;
Var I : Integer;
begin
  For I := Low(FFileData) To High(FFileData) Do
    If FFileData[I].hIcon > 0 Then DestroyIcon(FFileData[I].hIcon);
  InitArray(0);
end;

{Procedure qui initialise la taille du tableau à NewLength}
procedure TFileListBox.InitArray(NewLength: Integer);
begin
  SetLength(FFileData, NewLength);
end;

{Ici on surcharge la procedure qui récupère les noms des fichiers dans les répertoires
afin d'y ajouter les icônes}
Procedure TFileListBox.ReadFileNames;
Var I        : Integer;
Begin
  Inherited;{on fait appel à la méthode héritée}
  FreeArray;{Libère les Icônes}
  InitArray(Items.Count);{Initialise le tableau en fonction du nombre d'Items}
  For I := 0 to Items.Count - 1 Do {Récolte des nouvelles données}
    SHGetFileInfo(PChar(Items[I]), 0, FFileData[I],
      SizeOf(TSHFileInfo), SHGFI_DISPLAYNAME Or SHGFI_TYPENAME Or SHGFI_ICON
      Or SHGFI_SMALLICON );
End;

{Définition d'un Type TBitmapStyle pour charger les différents états d'une icône
 uniquement utilisé par TDirectoryListBox}
Type
  TBitmapStyle = (bsNormal, bsOpened, bsSelected);

{Procedure qui est utilisé par TDirectoryListBox et TDriveComboBox
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
 Ici on ne fait pas appel à la méthode héritée
 La méthode initiale est remplacée par celle-ci}
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

{Comme dans TDriveComboBox la méthode ReadBitmaps n'est pas "Virtual"
j'utilise une autre méthode pour modifier les Bitmaps}
procedure TDriveComboBox.BuildList;
Var BoolDrvType : Array[TDriveType] of Boolean;
    I : Integer;
    DrvType: TDriveType;
    Buffer : Array[0..104] of Char;
    P      : PChar;
    Len    : DWord;
begin
  {Appel de la méthode héritée}
  Inherited;
  {On fait pointer P sur Buffer}
  P := Buffer;
  {Initialise le buffer à zéro}
  ZeroMemory(P, SizeOf(Buffer));
  {Récupération des noms de lecteurs et le nombre de caractères récupéré dans
   le buffer sans le dernier zéro terminal}
  Len := GetLogicalDriveStrings(SizeOf(Buffer), P);
  {Chaque lecteur est sur 3 caractères plus le zéro terminal Ex: C:\#0}
  Len := Len Div 4;
  For I := 1 to Len Do Begin
    {Récupère le Type du lecteur}
    DrvType := TDriveType(GetDriveType(P));

    {Si le Bitmap n'est pas encore modifié }
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
