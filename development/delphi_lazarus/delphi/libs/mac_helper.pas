unit mac_helper;

interface

uses
  Winapi.Windows, System.SysUtils, NB30;

// 多网卡情况
function getMacAddress(index: Integer; separator: string): string;
function genRandomMacAdress(separator:string): string;

implementation

function getMacAddress(index: Integer; separator: string): string;
var
   ncb : TNCB;                {NetBios控制块}
   AdapterS : TAdapterStatus; {网卡状态结构}
   LanaNum : TLanaeNum;       {Netbios Lana}
   i : Integer;
   rc : AnsiChar;                 {NetBios的返回代码}
   str : String;
begin
   Result := '';
   try
      ZeroMemory(@ncb, SizeOf(ncb));   {NetBios控制块清零}
      ncb.ncb_command := chr(NCBENUM); {ENUM}
      rc := NetBios(@ncb);             {取返回代码}

      ncb.ncb_buffer := @LanaNum;      {再一次处理ENUM命令}
      ncb.ncb_length := Sizeof(LanaNum);
      rc := NetBios(@ncb);             {取返回代码}

      if ord(rc)<>0 then exit;

      ZeroMemory(@ncb, Sizeof(ncb));   {NetBios控制块清零}
      ncb.ncb_command := chr(NCBRESET);
      ncb.ncb_lana_num := LanaNum.lana[index];
      rc := NetBios(@ncb);
      if ord(rc)<>0 then exit;

      ZeroMemory(@ncb, Sizeof(ncb));   {取网卡的状态}
      ncb.ncb_command := chr(NCBASTAT);
      ncb.ncb_lana_num := LanaNum.lana[index];
      StrPCopy(ncb.ncb_callname,'*');
      ncb.ncb_buffer := @AdapterS;
      ncb.ncb_length := SizeOf(AdapterS);
      rc := NetBios(@ncb);

      str := '';                       {将MAC地址转换成字符串}
      for i:=0 to 5 do
        begin
          str := str + IntToHex(Integer(AdapterS.adapter_address[i]),2);
          if i <> 5 then begin
            str := str + '-';
          end;
        end;
      Result := str;
   finally
   end;
end;


function genRandomMacAdress(separator: String): String;
var Symbol: PChar;
    mac: String;
    I: Integer;
begin
    Randomize;
    Symbol := '0123456789ABCDEF';
    if separator = '' then
    begin
        for I := 0 to 11 do
            mac := mac + Symbol[Random(16)];
    end
    else if (separator = '-') Or (separator = ':') then
    begin
        for I := 0 to 11 do
        begin
            if (I > 0) And (I mod 2 = 0) then
            begin
                mac := mac + separator + Symbol[Random(16)];
            end
            else
                mac := mac + Symbol[Random(16)];
        end;
    end
    else if separator = '.' then
        for I := 0 to 11 do
        begin
            if (I > 0) And (I mod 4 = 0) then
            begin
                mac := mac + separator + Symbol[Random(16)];
            end
            else
                mac := mac + Symbol[Random(16)];
        end;
    Result := mac;
end;

end.
