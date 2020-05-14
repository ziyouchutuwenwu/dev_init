unit int_hex;

interface

uses
  System.SysUtils;

function intToHexStr(intValue: Integer; length: Integer = 8): string;
function hexStrToInt(hexString: string): Integer;

implementation

function intToHexStr(intValue: Integer; length: Integer = 8): string;
begin
  Result := IntToHex(intValue, length);
end;

function hexStrToInt(hexString: string): Integer;
begin
  Result := StrToInt('$' + hexString);
end;

end.

