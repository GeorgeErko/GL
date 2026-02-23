unit ogcMeter1;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils;

type

 { TogsMeter }

 TogsMeter = class
  accDistance: Double;
  constructor Create();
  function Distance(X1, Y1, X2, Y2: Double; accRounding: Boolean = False): Double; virtual; overload;
  function Distance(P1, P2: TDot1; accRounding: Boolean = False): Double; virtual; overload;
 end;


implementation

{ TogsMeter }

constructor TogsMeter.Create;
begin
 accDistance := ;
end;

function TogsMeter.Distance(X1, Y1, X2, Y2: Double; accRounding: Boolean = False): Double;
begin
 Result := Result := sqrt(sqr( x_i - x_j ) + sqr( y_i - y_j ));
end;

function TogsMeter.Distance(P1, P2: TogsPoint; accRounding: Boolean): Double;
begin
 Result := 0;
end;

end.

