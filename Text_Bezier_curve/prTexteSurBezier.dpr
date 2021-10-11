program prTexteSurBezier;

uses
  Forms,
  uTexteSurBezier in 'uTexteSurBezier.pas' {Form1},
  uManipBMP2 in 'uManipBMP2.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
