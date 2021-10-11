unit uManipBMP2;

interface    // Conçu sous Delphi-5 par G.G

uses   Windows, Graphics, Sysutils, Math, Classes, Dialogs, Jpeg, extctrls, Forms,
       axCtrls; //<- pour TOleGraphic;

// ECRIRE sur un canvas un texte incliné, avec ou sans bordure, monochrome ou à face texturée :
procedure AffTexteIncliBordeTexture( C : TCanvas; X,Y : integer; Fonte : tFont;
                                     clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                     Texture : tBitMap; Texte : string; AngleDD : longint);

// ECRIRE idem à AffTexteIncliBordeTexture mais sur un BitMap et avec en + Vraie ombre :
procedure AffTexteIncliBordeTextureVraieOmbre( Bmp : TBitMap; X,Y : integer; Fonte : tFont;
                                               clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                               Texture : tBitMap; Texte : string; AngleDD : longint;
                                               DxOmbre,DyOmbre : integer);

// Bezier

// ECRIRE sur un Bitmap un texte suivant une courbe de Bézier, avec ou sans bordure, monochrome ou à face texturée et avec vraie ombre :

type tTexteSurBezier = object
                   // Params Bézier :
                   nbPointsC : integer; // Nb de points calculés pour chaque courbe de Bezier
                   c1,c2,c3,c4 : array of single;         // Coeffs Bezier précalculés
                   PC          : array [0..3] of tPoint;  // Points de Contrôle
                   // Params Texte :
                   Texte       : string;
                   BmpCible    : tBitmap;
                   Fonte       : tFont;
                   clBord      : TColor;
                   EpBord      : integer;
                   PenMode     : TPenMode;
                   Texture     : tBitMap;
                   DxOmbre,DyOmbre : integer;
                   PreCalcFini : boolean;
                   PCVisibles  : boolean;
                   constructor PreCalcCoefs(inbPointsC : integer);
                   destructor  Free;
                   procedure   Add( iBmpCible : tBitmap; X,Y : integer; iFonte : tFont;
                                    iclBord   : TColor; iEpBord : integer; iPenMode : TPenMode;
                                    iTexture  : tBitMap; iTexte : string; iDxOmbre,iDyOmbre : integer);
                   procedure   TracePoignees;
                   procedure   TraceTexte;

                   function    SourisSurPoignee(Point : tPoint) : shortInt; // Result = idice du Point de contrôle sinon -1
                   function    SourisSurTexte(Point : tPoint) : boolean;
                   procedure   AjusterA(TexteNouveau : string);
                   private
                       procedure CoordonneesB(P1,P2,P3,P4: Tpoint; t: single; var X,Y : single);
                       function  TangenteBezier(P1,P2,P3,P4: tPoint; t: single) : single;
           end;

var TexteSurBezier : tTexteSurBezier;

// Fichiers :

// Ouvrir un fichier *.BMP, *DIB, *.GIF, *.ICO, *.JIF, *.JPG, *.WMF, ou *.EMF'
// et le récupérer sous forme d'un BitMap :
function ImgFile_To_Bmp(const nomFichierImg : string) : tBitMap;

// Convertir un BitMap en un *.JPG :
function BMP_To_JPEG(const BMP : tBitMap) : TJPEGImage;

implementation

// Ecrire sur un canvas un texte incliné, avec ou sans bordure, monochrome ou à face texturée
procedure AffTexteIncliBordeTexture( C : TCanvas; X,Y : integer; Fonte : tFont;
                                     clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                     Texture : tBitMap; Texte : string; AngleDD : longint);
// params : C       = Canvas-cible
//          X,Y     = Coordonnées angle supérieur gauche du début du texte.
//          Fonte   = Police de caractères à utiliser : uniquement des fontes scalables.
//          clBord  = Couleur de la bordure.
//          EpBord  = Epaisseur de la bordure.
//          PenMode = TPenMode : utiliser en général pmCopy.
//          Texture = BitMap de texture : Si Texture = Nil alors la face sera de la couleur de Fonte avec un contour de clBord si EpBord > 0.
//          Texte   = Texte à écrire.
//          AngleDD = Angle d'inclinaison en Dixièmes de degré.
var	  dc     : HDC;
          lgFont : LOGFONT;
          AncFonte,NouvFonte : HFONT;
	  AncPen,NouvPen     : HPEN;
          AncBrush,NouvBrush : HBRUSH;
begin     C.Pen.Mode:=PenMode;
          dc := C.Handle;

          // Initialisation de la fonte
          zeroMemory(@lgFont,sizeOf(lgFont));
          strPCopy(lgFont.lfFaceName,Fonte.Name);
          lgFont.lfHeight := Fonte.Height;
          if Fonte.style=[]       then lgFont.lfWeight:=FW_REGULAR; // Normal
          if Fonte.style=[fsBold] then lgFont.lfWeight:=FW_BOLD;    // Gras

          if fsItalic in Fonte.style    then lgFont.lfItalic:=1;
          if fsUnderline in Fonte.style then lgFont.lfUnderline:=1;
          if fsStrikeout in Fonte.style then lgFont.lfStrikeout:=1;

          lgFont.lfEscapement:=AngleDD; // Modification de l'inclinaison

          NouvFonte := CreateFontInDirect(lgFont);
          AncFonte := SelectObject(dc,NouvFonte);

          // Initialisation du contour :
          if EpBord<>0 then NouvPen := CreatePen(PS_SOLID,EpBord,clBord)
                       else NouvPen := CreatePen(PS_NULL,0,0);
          AncPen := SelectObject(dc,NouvPen);

          // Initialisation de la couleur de la police ou de la Texture :
          if Texture=nil then NouvBrush := CreateSolidBrush(Fonte.color) 
                         else NouvBrush := CreatePatternBrush(Texture.Handle);
          AncBrush := SelectObject(dc,NouvBrush);
          // Le contexte doit être transparent
          SetBkMode(dc,TRANSPARENT);

          // Dessin du texe :
          BeginPath(dc);
          TextOut(dc,X,Y,PansiChar(Texte),length(texte));
          EndPath(dc);
          StrokeAndFillPath(dc);

          // Restauration objets et libération mémoire
          SelectObject(dc,AncFonte);
          DeleteObject(NouvFonte);
          SelectObject(dc,AncPen);
          DeleteObject(NouvPen);
          SelectObject(dc,AncBrush);
          DeleteObject(NouvBrush);
end; // AffTexteIncliBordeTexture

procedure AffTexteIncliBordeTextureVraieOmbre( Bmp : TBitMap; X,Y : integer; Fonte : tFont;
                                               clBord : TColor; EpBord : integer; PenMode : TPenMode;
                                               Texture : tBitMap; Texte : string; AngleDD : longint;
                                               DxOmbre,DyOmbre : integer);
var       TW,TH : integer;
          BmMasque : tBitmap; // Masque
          wBmM,hBmM: integer;
          BmAP     : tBitMap; // Arrière-Plan
          IncliRad : Extended;
          Si,Co    : Extended;
          TWSi,THSi,TWCo,THCo : integer;
          RDest,RSrc : tRect;
          XD,YD    : integer;
          Q        : byte;
          memoCl   : tColor;

          procedure AssombrirAP_si_Ombre;
          const     Bpp=3;
          var       // Arrière-Plan:
                    Scan0AP : integer;
                    MLS     : integer;
                    ScanAP  : integer;
                    // Masque
                    Scan0M  : integer;
                    ScanM   : integer;
                    ix      : integer;
                    iy      : integer;
          begin     Scan0AP := Integer(BmAP.ScanLine[0]);
                    Scan0M  := Integer(BmMasque.ScanLine[0]);
                    MLS     := Integer(BmAP.ScanLine[1]) - Scan0AP;
                    for iy:=0 to pred(hBmM) do begin
                        for ix:=0 to pred(wBmM) do begin
                            ScanM := Scan0M;
                            Inc(ScanM, iy*MLS + ix*Bpp);
                            if  (PRGBTriple(scanM)^.rgbtBlue=0)
                            and (PRGBTriple(scanM)^.rgbtGreen=0)
                            and (PRGBTriple(scanM)^.rgbtRed=0) then
                            begin ScanAP := Scan0Ap;
                                  Inc(ScanAP, iy*MLS + ix*Bpp);
                                  with PRGBTriple(scanAP)^ do
                                  begin Dec( rgbtRed,  64 );
                                        Dec( RgbtGreen,64 );
                                        Dec( RgbtBlue, 64 );
                                  end;
                            end;
                        end;
                    end;
          end;

begin     Bmp.PixelFormat:=pf24bit;
          Bmp.Canvas.Font:=Fonte;
          with Bmp.Canvas do begin
               TW:=TextWidth(Texte);
               TH:=TextHeight(Texte);
          end;
          IncliRad:=DegToRad(AngleDD/10.0);
          SinCos(IncliRad,Si,Co);
          TWSi:=round(abs(TW*Si));
          THSi:=round(abs(TH*Si));
          TWCo:=round(abs(TW*Co));
          THCo:=round(abs(TH*Co));
          wBmM:=TWCo + THSi + abs(DxOmbre);
          hBmM:=THCo + TWSi + abs(DyOmbre);
          case AngleDD of
               -1800..-900 : begin XD:=wBmM;
                                   YD:=THCo;
                             end;
               -899..0     : begin XD:=THSi;
                                   YD:=0;
                             end;
               1..900      : begin Xd:=0;
                                   YD:=TWSi;
                             end;
               901..1800   : begin Xd:=TWCo;
                                   YD:=hbmM;
                             end;
          end;

          BmMasque :=tBitmap.create;
          with BmMasque do begin
               width:=wBmM; height:=hBmM; PixelFormat:=pf24bit;
               canvas.Brush.Style:=bsSolid; canvas.Brush.color:=clWhite;
               canvas.FillRect(BmMasque.canvas.ClipRect);
          end;
          // Incruster le texte en Noir sur le masque :
          memoCl:=Fonte.color;
          Fonte.color:=clBlack;
          AffTexteIncliBordeTexture( BmMasque.Canvas,XD+DxOmbre,YD+DyOmbre, Fonte,clBlack,EpBord,PenMode,
                                     nil, Texte, AngleDD);
          Fonte.color:=memoCl;
          // Copier l'Arrière-Plan :
          BmAP:=tBitmap.create;
          with BmAP do begin
               width:=wBmM; height:=hBmM; PixelFormat:=pf24bit;
          end;
          RDest:=Rect(0,0,wBmM,hBmM);
          RSrc :=Rect(X-XD,Y-Yd,X-XD+wBmM,Y-YD+hBmM);
          BmAP.Canvas.CopyRect(RDest, Bmp.canvas, RSrc);

          // Assombrir la zone d'arrière-plan dans l'ombre portée :
          AssombrirAP_si_Ombre;
          // Incruster le texte éventuellement texturé :
          AffTexteIncliBordeTexture( BmAP.Canvas, XD, YD, Fonte,clBord,EpBord,PenMode,
                                     Texture, Texte,AngleDD);
          RDest:=Rect(X-XD,Y-Yd,X-XD+wBmM,Y-YD+hBmM);
          RSrc :=Rect(0,0,wBmM,hBmM);
          Bmp.Canvas.CopyRect(RDest, BmAP.canvas, RSrc);

          BmMasque.free;
          BmAP.Free;

end;

// BEZIER :

function ArcTan22(dy,dx : Extended) : single;
begin    if dx<>0 then Result:=-ArcTan2(dy,dx)
         else begin if dy>0 then Result:=-Pi/2
                            else Result:=Pi/2;
              end;
end;

procedure tTexteSurBezier.CoordonneesB(P1,P2,P3,P4: Tpoint; t: single; var X,Y : single);
//        var X,Y renvoient les coordonnées du point de la courbe de Bézier X(t) et Y(t)
//        correspondant aux 4 points de contrôle
var       t2,  //   t^2
          t3,  //   t^3
          r1, r2, r3, r4 : single;
begin     t2 := t * t;
          t3 := t * t2;
          // formule (1-t)^3  = 1 - 3*t + 3*t^2 - t^3
          r1 := (1 - 3*t + 3*t2 -   t3)*P1.x;
          r2 := (    3*t - 6*t2 + 3*t3)*P2.x;
          r3 := (          3*t2 - 3*t3)*P3.x;
          r4 := (                   t3)*P4.x;
          X  := r1 + r2 + r3 + r4;
          r1 := (1 - 3*t + 3*t2 -   t3)*P1.y;
          r2 := (    3*t - 6*t2 + 3*t3)*P2.y;
          r3 := (          3*t2 - 3*t3)*P3.y;
          r4 := (                   t3)*P4.y;
          Y  := r1 + r2 + r3 + r4;
end; // tTexteSurBezier.CoordonneesB

function  tTexteSurBezier.TangenteBezier(P1,P2,P3,P4: tPoint; t: single) : single;
//        Params P1,C1,C2,P2 = points de contrôle
const     dt = 0.001;
var       x1,y1,x2,y2 : single;
begin     result := 0;
          if (t < 0) or (t > 1) then exit; // t hors intervalle
          if t=0 then begin result := ArcTan22(P2.y-P1.y, P2.x-P1.x); EXIT; end;
          if t=1 then begin result := ArcTan22(P3.y-P4.y, P3.x-P4.x); EXIT; end;
          CoordonneesB(P1,P2,P3,P4, t, x1,y1);
          if t+dt <= 1 then begin
             CoordonneesB(P1,P2,P3,P4, t+dt, x2,y2);
             result := ArcTan22(y2-y1, x2-x1);     EXIT;
          end else begin
              CoordonneesB(P1,P2,P3,P4, t-dt, x2,y2);
              result := ArcTan22(y1-y2, x1-x2);    EXIT;
          end;
end; // tTexteSurBezier.TangenteBezier

constructor tTexteSurBezier.PreCalcCoefs(inbPointsC : integer);
//          X(t) = (1-t)^3.x1 + 3.t.(1-t)^2.x2 + 3.t^2.(1-t).x3 + t^3.x4 pour 0 <= t <= 1
//          Y(t) = (1-t)^3.y1 + 3.t.(1-t)^2.y2 + 3.t^2.(1-t).y3 + t^3.y4 pour 0 <= t <= 1
var         t,dt,unmt,unmt2,t2 : single; jb : integer;
begin       nbPointsC:=inbPointsC;
            // Précalcul des coeffs Bezier c1,c2,c3,c4 :
            t:=0; dt:=1/nbPointsC;   SetLength(c1,nbPointsC);
            SetLength(c2,nbPointsC); SetLength(c3,nbPointsC); SetLength(c4,nbPointsC);
            for jb:=0 to nbPointsC-1 do begin
                unmt:=1-t; unmt2:=unmt*unmt; c1[jb]:=unmt2*unmt; t2:=t*t; c4[jb]:=t2*t;
                c2[jb]:=3*t*unmt2; c3[jb]:=3*t2*unmt;
                t:=t+dt;
            end;
            PreCalcFini:=True;
end; // tTexteSurBezier.PreCalcCoefs

destructor  tTexteSurBezier.Free;
begin       Fonte.Free;
end;

procedure   tTexteSurBezier.Add( iBmpCible : tBitmap; X,Y : integer; iFonte : tFont;
                                 iclBord : TColor; iEpBord : integer; iPenMode : TPenMode;
                                 iTexture : tBitMap; iTexte : string; iDxOmbre,iDyOmbre : integer);
var         lg : integer;
begin       Texte:=iTexte;
            BmpCible:=iBmpCible;
            Fonte:=tFont.Create;
            Fonte.Assign(iFonte);
            clBord:=iclBord;
            EpBord:=iEpBord;
            PenMode:=iPenMode;
            Texture:=iTexture;
            DxOmbre:=idxOmbre;
            DyOmbre:=idyOmbre;
            with BmpCible.canvas do begin
                 Font:=Fonte;
                 lg:=TextWidth(Texte) + length(Texte)*abs(DxOmbre);
            end;
            PC[0]:=Point(X,Y);
            PC[1]:=Point(X+100,Y-150);
            PC[2]:=Point(X+lg-100,Y+80);
            PC[3]:=Point(X+lg,Y);
end; // tTexteSurBezier.Add

procedure   tTexteSurBezier.TracePoignees;
const       r = 4;
var         i,xpc,ypc : integer;
begin       with BmpCible.Canvas do begin
                 pen.color:=clBlack;
                 pen.width:=1;
                 pen.mode:=pmCopy;
                 brush.style:=bsSolid;
                 brush.color:=clRed;
                 for i:=0 to High(PC) do
                 begin xpc:=PC[i].x; ypc:=PC[i].y;
                       Rectangle(xpc-r,ypc-r, xpc+r,ypc+r);
                 end;
                 pen.color:=clSilver;
                 MoveTo(PC[0].x,PC[0].y);
                 LineTo(PC[1].x,PC[1].y);
                 MoveTo(PC[2].x,PC[2].y);
                 LineTo(PC[3].x,PC[3].y);
            end;
            PCVisibles:=True;
end; // tTexteSurBezier.TracePoignees

function  tTexteSurBezier.SourisSurPoignee(Point : tPoint) : shortInt;
//        Result = indice du Point de contrôle sous la souris, sinon -1
const     r = 10;
var       x,y,jpc : integer;
begin     Result:=-1;
          for jpc:=0 to High(PC) do begin
              x:=PC[jpc].x; y:=PC[jpc].y;
              if (abs(Point.x - x)<=r) and (abs(Point.y - y)<=r) then
              begin Result:=jpc;
                    break;
              end;
          end;
end; // tTexteSurBezier.SourisSurPoignee

procedure tTexteSurBezier.TraceTexte;
var       hd2,t   : single;
          x,y,i,ec,ThetaDD : integer;
          Theta   : Extended;
          pa      : tPoint;
          pbx,pby : single;

          function  T_Suivant : single;
          //        Result = t tel que distance de t-précédent à t = ec
          var       xo,yo,xt,yt,dt,ds : single;
          begin     CoordonneesB(PC[0],PC[1],PC[2],PC[3], t, xo,yo);
                    dt:=0.001; ds:=0; Result:=t;
                    while ds<ec do begin
                          Result:=Result + dt;
                          CoordonneesB(PC[0],PC[1],PC[2],PC[3], Result, xt,yt);
                          ds:=sqrt(sqr(xt-xo) + sqr(yt-yo));
                    end;
          end;

begin     with BmpCible.Canvas do begin
               // Texte :
               Font:=Fonte;
               hd2:=1.4*(TextHeight(Texte[1]) div 2);
               x:=PC[0].x; t:=0;
               for i:=1 to length(Texte) do begin
                   ec:=TextWidth(Texte[i])+1+DxOmbre;
                   Theta:=TangenteBezier(PC[0],PC[1],PC[2],PC[3], t);
                   ThetaDD:=round(10*RadToDeg(Theta));
                   CoordonneesB(PC[0],PC[1],PC[2],PC[3], t, pbx,pby);
                   pa.x:= round(pbx - hd2*sin(Theta));
                   pa.y:= round(pby - hd2*cos(Theta));
                   try AffTexteIncliBordeTextureVraieOmbre( BmpCible, pa.x,pa.y, Fonte,
                                                            clBord, EpBord, pmCopy,
                                                            Texture,Texte[i]+' ', ThetaDD,DxOmbre,DyOmbre);
                   except
                   end;
                   t:=T_Suivant;
               end;
          end;
end; // tTexteSurBezier.TraceTexte;

function  tTexteSurBezier.SourisSurTexte(Point : tPoint) : boolean;
//        Renvoie true si Point sur Texte
var       jb,x,y : integer; r : single;
begin     Result:=False;
          r:=0.2*BmpCible.Canvas.TextHeight('H'); //< r = marge de tolérance
          for jb:=0 to nbPointsC-1 do
          begin x := round(c1[jb]*PC[0].x + c2[jb]*PC[1].x + c3[jb]*PC[2].x + c4[jb]*PC[3].x);
                y := round(c1[jb]*PC[0].y + c2[jb]*PC[1].y + c3[jb]*PC[2].y + c4[jb]*PC[3].y);
                if (abs(Point.x - x)<=r) and (abs(Point.y - y)<=r)
                then begin Result:=True;
                           EXIT;
                end;
          end;
end; // tTexteSurBezier.SourisSurTexte

procedure tTexteSurBezier.AjusterA(TexteNouveau : string);
var       lg : integer;
begin     Texte:=TexteNouveau;
          // Ajustement position des deux PC de fin avec nouvelle longueur du texte :
          with BmpCible.canvas do begin
               Font:=Fonte;
               lg:=TextWidth(Texte) + length(Texte)*abs(DxOmbre);
          end;
          PC[2]:=Point(PC[0].X+lg-100,PC[0].Y+80);
          PC[3]:=Point(PC[0].X+lg,PC[0].Y);
end; // tTexteSurBezier.AjusterA

// FICHIERS :

function  ImgFile_To_Bmp(const nomFichierImg : string) : tBitMap;
const     FormatsSupportes = '.BMP.DIB.GIF.ICO.JIF.JPG.WMF.EMF';
var       OleGraphic: TOleGraphic; FS: TFileStream; ext : string; img : tImage;
begin     if not FileExists(nomFichierImg) then
          begin
                 showMessage(nomFichierImg+' : n''existe pas'); Result:=nil; EXIT;
          end;
          ext:=UpperCase(ExtractFileExt(nomFichierImg));
          if (ext='') or (pos(ext,FormatsSupportes)=0) then
          begin showMessage(ext+' = Format non supporté par BMPdeIMG');
                Result:=nil; EXIT;
          end;
          if ext='.BMP' then
          begin
             Result :=tBitmap.create;
             Result.PixelFormat:=pf24Bit;
             Result.LoadFromFile(nomFichierImg);
             EXIT;
          end;
          OleGraphic := TOleGraphic.Create;
          FS := TFileStream.Create(nomFichierImg, fmOpenRead or fmSharedenyNone);
          img:= tImage.Create(Application);
          try
             OleGraphic.LoadFromStream(FS);
             img.Picture.Assign(OleGraphic);
             Result :=tBitmap.create;
             with Result do
             begin PixelFormat:=pf24Bit;
                   Width :=img.Picture.Width;
                   Height:=img.Picture.Height;
                   Canvas.Draw(0, 0, img.Picture.Graphic);
             end;
          finally
             fs.Free;
             img.free;
             OleGraphic.Free;
          end;
end; // ImgFile_To_Bmp

function BMP_To_JPEG(const BMP : tBitMap) : TJPEGImage;
begin    Result:=TJPEGImage.Create;
         try
            with Result do
            begin PixelFormat := jf24Bit;
                  Grayscale   := False;
                  CompressionQuality := 80;
                  Scale := jsFullSize;
                  Assign(BMP);
                  JpegNeeded;
                  Compress;
            end;
            BMP.Dormant;
            BMP.FreeImage;
         except
            on EInvalidGraphic do
            begin Result.Free; Result := nil; end;
         end;
         Application.ProcessMessages;
end; // BMP_To_JPEG

END.
