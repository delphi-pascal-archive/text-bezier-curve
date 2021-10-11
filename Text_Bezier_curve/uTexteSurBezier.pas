unit uTexteSurBezier;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, uManipBMP2, ExtCtrls, StdCtrls, ComCtrls, Jpeg, ExtDlgs;

type
  TForm1 = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel1: TPanel;
    labInfos: TLabel;
    labFonte: TLabel;
    imgTexture: TImage;
    Label1: TLabel;
    edTexte: TEdit;
    Label2: TLabel;
    edDXombre: TEdit;
    UpDDXombre: TUpDown;
    Label3: TLabel;
    edDYombre: TEdit;
    UpDDYombre: TUpDown;
    bSauverSous: TSpeedButton;
    bOuvrir: TSpeedButton;
    OpenPictureDialog1: TOpenPictureDialog;
    SavePictureDialog1: TSavePictureDialog;
    FontDialog1: TFontDialog;
    bFonte: TSpeedButton;
    Label4: TLabel;
    edEpBord: TEdit;
    UpDown1: TUpDown;
    bAnnuler: TSpeedButton;
    bTexture: TSpeedButton;
    bCoulBord: TSpeedButton;
    bCoulFace: TSpeedButton;
    rbFaceUnie: TRadioButton;
    rbFaceTexturee: TRadioButton;
    ColorDialog1: TColorDialog;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure bSauverSousClick(Sender: TObject);
    procedure bOuvrirClick(Sender: TObject);
    procedure bFonteClick(Sender: TObject);
    procedure bAnnulerClick(Sender: TObject);
    procedure bTextureClick(Sender: TObject);
    procedure edDXombreChange(Sender: TObject);
    procedure edDYombreChange(Sender: TObject);
    procedure edEpBordChange(Sender: TObject);
    procedure bCoulFaceClick(Sender: TObject);
    procedure bCoulBordClick(Sender: TObject);
    procedure rbFaceUnieClick(Sender: TObject);
    procedure rbFaceTextureeClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure edTexteChange(Sender: TObject);
    procedure edTexteKeyPress(Sender: TObject; var Key: Char);
  private
    { Déclarations privées }
    procedure ActualiserAffichage;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

var       BmpUndo : tBitMap;
          CoulFace,CoulBord : tColor;

procedure TForm1.FormCreate(Sender: TObject);
begin     labInfos.caption:=' Saisir un texte puis cliquer sur l''image pour positionner le début du texte';
          scrollbox1.DoubleBuffered:=true;
          labFonte.Font.Size:=36;
          CoulFace:=clAqua;
          CoulBord:=clMaroon;
          labFonte.Font.color:=CoulFace;
          bCoulFace.Font.color:=CoulFace;
          bCoulBord.Font.Color:=CoulBord;
          BmpUndo :=tBitMap.create;
          BmpUndo.Assign(Image1.Picture.BitMap);
end;

var       PremFois     : boolean;
          xMp,yMp      : integer;
          indPC        : shortInt;
          PositFini    : boolean;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
          if Button=mbLeft then  // Bouton-souris-Gauche : pour positionner, déplacer, déformer le texte.
                                 // Texte suivant possible après avoir figé le texte en enlevant
                                 // les poignées avec click Bouton-souris-Droite
          begin with TexteSurBezier do
                begin if PremFois then
                      begin PreCalcCoefs(30);
                            PremFois:=False;
                            PositFini:=True;
                      end;
                      if PositFini then // PositFini sera ensuite False tant que le Positionnement du texte ne sera pas Fini
                      begin if rbFaceTexturee.checked
                            then Add( Image1.Picture.BitMap, X,Y, labFonte.Font,
                                      CoulBord, StrToIntDef(edEpBord.text,0), pmCopy,
                                      imgTexture.Picture.bitMap, trim(edTexte.text),
                                      StrToIntDef(edDXombre.text,0),StrToIntDef(edDYombre.text,0))
                            else Add( Image1.Picture.BitMap, X,Y, labFonte.Font,
                                      CoulBord, StrToIntDef(edEpBord.text,0), pmCopy,
                                      Nil, trim(edTexte.text),
                                      StrToIntDef(edDXombre.text,0),StrToIntDef(edDYombre.text,0));
                            TracePoignees;
                            TraceTexte;
                            Image1.Repaint;
                            PositFini:=False;
                      end;
                end; // with
          end; // if Button=mbLeft
          xMp:=X; yMp:=Y;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var       dx,dy,i : integer; info : string;
begin     with TexteSurBezier do
          begin if PremFois then EXIT;
                indPC:=SourisSurPoignee(Point(X,Y));
                if (Not (ssLeft in Shift)) and (Not (ssRight in Shift)) then
                begin info:='';
                      if indPC<>-1
                      then Info:=' Souris sur Point de Contrôle indice '+intToStr(indPC)+' : le point est déplacable avec le bouton-gauche-souris'
                      else
                      if SourisSurTexte(Point(X,Y))
                      then Info:=' Souris sur Texte : le texte est déplacable avec le bouton-gauche-souris';
                      labInfos.caption:=info;
                      if info<>'' then image1.Cursor:=crHandPoint
                                  else image1.Cursor:=crDefault;
                end;

                if (indPC>=0) and (ssLeft in Shift) then     // Déplacement d'un Point de Contrôle
                begin image1.Picture.Bitmap.Assign(bmpUndo); // effacement
                      PC[indPC].x:=X;
                      PC[indPC].y:=Y;
                      TracePoignees;                         //<- Lors du déplacement d'un PC on se contente de rafraîchir les poignées
                      //TraceTexte;
                      Application.ProcessMessages;
                      Image1.Repaint;                        // Rafraîchissement
                      EXIT;
                end;
                if (ssLeft in Shift) and SourisSurTexte(Point(X,Y)) then // Translation du texte
                begin image1.Picture.Bitmap.Assign(bmpUndo); // effacement
                      dx:=X-xMp;
                      dy:=Y-yMp;
                      for i:=0 to 3 do
                      begin PC[i].x:=PC[i].x + dx;
                            PC[i].y:=PC[i].y + dy;
                      end;
                      //sms('ici');
                      TraceTexte;
                      TracePoignees;
                      Application.ProcessMessages;
                      Image1.Repaint;                        // Rafraîchissement
                      xMp:=X; yMp:=Y;
                end;
          end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin     if PremFois then EXIT;
          if (Button=mbRight) then // Avec bouton-souris-Droite on fige le texte en enlevant les poignées
          begin image1.Picture.Bitmap.Assign(bmpUndo); // effacement
                TexteSurBezier.TraceTexte;             // on re-trace uniquement le texte
                TexteSurBezier.PCVisibles:=False;
                Application.ProcessMessages;
                Image1.Repaint;
                bmpUndo.Assign(image1.Picture.Bitmap);
                PositFini:=true;
          end;
          if (Button=mbLeft) then // Avec bouton-souris-Gauche : on vient de déplacer une poignée ou tout le texte
          begin image1.Picture.Bitmap.Assign(bmpUndo); // effacement
                TexteSurBezier.TraceTexte;             // on re-trace le texte et les poignées
                TexteSurBezier.TracePoignees;
                Application.ProcessMessages;
                Image1.Repaint;
                indPC:=-1;
          end;
end;

procedure TForm1.bSauverSousClick(Sender: TObject);
var       JP : tJPegImage; EX : string;
begin     with SavePictureDialog1 do begin
               Filter:= 'Fichiers BMP (*.bmp)|*.BMP|Fichiers JPG (*.jpg)|*.JPG';
               if Execute then begin
                  EX:=lowerCase(ExtractFileExt(FileName));
                  if EX='.bmp' then Image1.Picture.BitMap.SaveToFile(FileName) else
                  if EX='.jpg' then begin
                     JP:=BMP_To_JPEG(Image1.Picture.BitMap);
                     JP.SaveToFile(FileName);
                     JP.Free;
                  end else ShowMessage('Format '+EX+' : non prévu');
               end;
          end;
end;

procedure TForm1.bOuvrirClick(Sender: TObject);
begin     with OpenPictureDialog1 do begin
               Filter := GraphicFilter(TGraphic);
               if Execute then begin
                  Image1.Picture.Bitmap.Assign(ImgFile_To_Bmp(FileName));
                  BmpUndo.Assign(Image1.Picture.Bitmap);
               end;
          end;
end;

// Modifications de paramètres pour le texte en cours :

procedure TForm1.ActualiserAffichage;
begin     with TexteSurBezier do
          begin if PCVisibles then
                begin image1.Picture.Bitmap.Assign(bmpUndo);
                      TraceTexte;
                      TracePoignees;
                end;
          end;
end;

procedure TForm1.bFonteClick(Sender: TObject);
begin     FontDialog1.Font:=labFonte.Font;
          with FontDialog1 do
          begin if Execute then begin
                   labFonte.Font:=Font;
                   bCoulFace.Font.Color:=Font.color;
                   TexteSurBezier.Fonte:=Font;
                   bFonte.Hint:=Font.Name+' '+IntToStr(Font.size);
                   ActualiserAffichage;
                end;
          end;

end;

procedure TForm1.bAnnulerClick(Sender: TObject);
begin     image1.Picture.Bitmap.Assign(bmpUndo);
          TexteSurBezier.PCVisibles:=False;
          PositFini:=True;
end;

procedure TForm1.bTextureClick(Sender: TObject);
begin     with OpenPictureDialog1 do begin
               Filter := GraphicFilter(TGraphic);
               if Execute then begin
                  ImgTexture.Picture.Bitmap.Assign(ImgFile_To_Bmp(FileName));
                  TexteSurBezier.Texture:=ImgTexture.Picture.Bitmap;
                  rbFaceTexturee.Checked:=true;
                  ActualiserAffichage;
               end;
          end;
end;

procedure TForm1.edDXombreChange(Sender: TObject);
begin     TexteSurBezier.DxOmbre:=StrToIntDef(edDXombre.Text, 0);
          ActualiserAffichage;
end;

procedure TForm1.edDYombreChange(Sender: TObject);
begin     TexteSurBezier.DyOmbre:=StrToIntDef(edDYombre.Text, 0);
          ActualiserAffichage;
end;

procedure TForm1.edEpBordChange(Sender: TObject);
begin     TexteSurBezier.EpBord:=StrToIntDef(edEpBord.Text, 0);
          ActualiserAffichage;
end;

procedure TForm1.bCoulFaceClick(Sender: TObject);
begin     if ColorDialog1.Execute then
          begin CoulFace:=ColorDialog1.color;
                bCoulFace.Font.Color:=CoulFace;
                labFonte.Font.color:=CoulFace;
                TexteSurBezier.Fonte.color:=CoulFace;
                ActualiserAffichage;
          end;
end;

procedure TForm1.bCoulBordClick(Sender: TObject);
begin     if ColorDialog1.Execute then
          begin CoulBord:=ColorDialog1.color;
                bCoulBord.Font.Color:=CoulBord;
                TexteSurBezier.clBord:=CoulBord;
                ActualiserAffichage;
          end;
end;

procedure TForm1.rbFaceUnieClick(Sender: TObject);
begin     TexteSurBezier.Texture:=Nil;
          ActualiserAffichage;
end;

procedure TForm1.rbFaceTextureeClick(Sender: TObject);
begin     TexteSurBezier.Texture:=ImgTexture.Picture.bitMap;
          ActualiserAffichage;
end;

procedure TForm1.edTexteChange(Sender: TObject);
begin     if TexteSurBezier.PCVisibles
          then labInfos.caption:=' Valider cette modification avec la touche Enter en fin de saisie';
end;

procedure TForm1.edTexteKeyPress(Sender: TObject; var Key: Char);
var       lg : integer;
begin     if Key=#13 then
          begin TexteSurBezier.AjusterA(trim(edTexte.text));
                ActualiserAffichage;
                labInfos.caption:='';
          end;
end;

// On va faire clignoter les Points de Contrôle :
const     cl1 : tColor = clRed;
          cl2 : tColor = clMaroon;
var       cl  : tColor;
procedure TForm1.Timer1Timer(Sender: TObject);
const     r = 4;
var       i,x,y : integer;
begin     if cl=cl1 then cl:=cl2 else cl:=cl1;
          with TexteSurBezier do
          begin if PCVisibles then
                begin with BmpCible.Canvas do begin
                                 pen.color:=clBlack;
                                 pen.width:=1;
                                 pen.mode:=pmCopy;
                                 brush.style:=bsSolid;
                                 brush.color:=cl;
                                 for i:=0 to 3 do
                                 begin x:=PC[i].x; y:=PC[i].y;
                                       Rectangle(x-r,y-r, x+r,y+r);
                                 end;
                      end;
                end;
          end;

end;

initialization

          PremFois:=True;

end.


