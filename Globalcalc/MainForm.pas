unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  { TfrmCalculator }
  TfrmCalculator = class(TForm)
    btn7: TButton;
    btn8: TButton;
    btn9: TButton;
    btnDivide: TButton;
    btnClear: TButton;
    btn4: TButton;
    btn5: TButton;
    btn6: TButton;
    btnMultiply: TButton;
    btnSqrt: TButton;
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    btnMinus: TButton;
    btnPercent: TButton;
    btn0: TButton;
    btnDecimal: TButton;
    btnEquals: TButton;
    btnPlus: TButton;
    edtDisplay: TEdit;
    pnlResult: TPanel;
    lblResult: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure NumberClick(Sender: TObject);
    procedure OperationClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnDecimalClick(Sender: TObject);
    procedure btnEqualsClick(Sender: TObject);
    procedure btnSqrtClick(Sender: TObject);
    procedure btnPercentClick(Sender: TObject);
  private
    FFirstNumber: Double;
    FSecondNumber: Double;
    FOperation: Char;
    FNewNumber: Boolean;
    procedure Calculate;
    procedure SaveResultToJPEG;
  public
    { Public declarations }
  end;

var
  frmCalculator: TfrmCalculator;

implementation

{$R *.frm}

{ TfrmCalculator }

procedure TfrmCalculator.FormCreate(Sender: TObject);
begin
  FNewNumber := True;
  edtDisplay.Text := '0';
  lblResult.Caption := '0';
  FOperation := #0;
end;

procedure TfrmCalculator.NumberClick(Sender: TObject);
begin
  if FNewNumber then
  begin
    edtDisplay.Text := (Sender as TButton).Caption;
    FNewNumber := False;
  end
  else
  begin
    if edtDisplay.Text = '0' then
      edtDisplay.Text := (Sender as TButton).Caption
    else
      edtDisplay.Text := edtDisplay.Text + (Sender as TButton).Caption;
  end;
end;

procedure TfrmCalculator.OperationClick(Sender: TObject);
begin
  if not FNewNumber then
    Calculate;
    
  FFirstNumber := StrToFloat(edtDisplay.Text);
  FOperation := (Sender as TButton).Caption[1];
  FNewNumber := True;
end;

procedure TfrmCalculator.Calculate;
begin
  if FOperation = #0 then Exit;
  
  FSecondNumber := StrToFloat(edtDisplay.Text);
  
  case FOperation of
    '+': FFirstNumber := FFirstNumber + FSecondNumber;
    '-': FFirstNumber := FFirstNumber - FSecondNumber;
    '*': FFirstNumber := FFirstNumber * FSecondNumber;
    '/': 
      if FSecondNumber <> 0 then
        FFirstNumber := FFirstNumber / FSecondNumber
      else
      begin
        ShowMessage('Ошибка: деление на ноль!');
        FOperation := #0;
        Exit;
      end;
  end;
  
  edtDisplay.Text := FloatToStr(FFirstNumber);
  lblResult.Caption := FloatToStr(FFirstNumber);
  SaveResultToJPEG;
  FOperation := #0;
  FNewNumber := True;
end;

procedure TfrmCalculator.btnClearClick(Sender: TObject);
begin
  edtDisplay.Text := '0';
  lblResult.Caption := '0';
  FFirstNumber := 0;
  FSecondNumber := 0;
  FOperation := #0;
  FNewNumber := True;
end;

procedure TfrmCalculator.btnDecimalClick(Sender: TObject);
begin
  if FNewNumber then
  begin
    edtDisplay.Text := '0.';
    FNewNumber := False;
  end
  else if Pos('.', edtDisplay.Text) = 0 then
    edtDisplay.Text := edtDisplay.Text + '.';
end;

procedure TfrmCalculator.btnEqualsClick(Sender: TObject);
begin
  Calculate;
  FNewNumber := True;
end;

procedure TfrmCalculator.btnSqrtClick(Sender: TObject);
var
  Value: Double;
begin
  try
    Value := StrToFloat(edtDisplay.Text);
    if Value >= 0 then
    begin
      edtDisplay.Text := FloatToStr(Sqrt(Value));
      lblResult.Caption := FloatToStr(Sqrt(Value));
      SaveResultToJPEG;
    end
    else
      ShowMessage('Ошибка: нельзя извлечь корень из отрицательного числа');
  except
    on E: Exception do
      ShowMessage('Ошибка: ' + E.Message);
  end;
  FNewNumber := True;
end;

procedure TfrmCalculator.btnPercentClick(Sender: TObject);
var
  Value: Double;
begin
  try
    Value := StrToFloat(edtDisplay.Text);
    edtDisplay.Text := FloatToStr(Value / 100);
    lblResult.Caption := FloatToStr(Value / 100);
    SaveResultToJPEG;
  except
    on E: Exception do
      ShowMessage('Ошибка: ' + E.Message);
  end;
  FNewNumber := True;
end;

procedure TfrmCalculator.SaveResultToJPEG;
var
  Bitmap: TBitmap;
  FileName: string;
  TextWidth, TextHeight, X, Y: Integer;
begin
  try
    Bitmap := TBitmap.Create;
    
    try
      // Создаем битмап размером с панель результата
      Bitmap.Width := pnlResult.Width;
      Bitmap.Height := pnlResult.Height;
      
      // Рисуем белый фон
      Bitmap.Canvas.Brush.Color := clWhite;
      Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
      
      // Рисуем текст большими красными буквами
      Bitmap.Canvas.Font.Name := 'Arial';
      Bitmap.Canvas.Font.Size := 48;
      Bitmap.Canvas.Font.Style := [fsBold];
      Bitmap.Canvas.Font.Color := clRed;
      
      // Вычисляем позицию для центрирования текста
      TextWidth := Bitmap.Canvas.TextWidth(lblResult.Caption);
      TextHeight := Bitmap.Canvas.TextHeight(lblResult.Caption);
      X := (Bitmap.Width - TextWidth) div 2;
      Y := (Bitmap.Height - TextHeight) div 2;
      
      // Рисуем текст
      Bitmap.Canvas.TextOut(X, Y, lblResult.Caption);
      
      // Сохраняем как BMP (встроенный формат) в каталоге с программой
      FileName := ExtractFilePath(ParamStr(0)) + 'calc_result_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.bmp';
      Bitmap.SaveToFile(FileName);
      
      ShowMessage('Результат сохранен в файл: ' + FileName);
      
    finally
      Bitmap.Free;
    end;
    
  except
    on E: Exception do
      ShowMessage('Ошибка сохранения: ' + E.Message);
  end;
end;

end.
