unit pkg_sender;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinSock, StdCtrls, pkg_header;

type
  PkgSender = class(TObject)
  private
    class procedure setDataLengthToHeader(buffer : TBytes; length : Integer; pkgHeaderOption : pkg_header.PkgHeaderOption);
  public
    class function makeDataToSend(data : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption):TBytes;
  end;
implementation

class procedure PkgSender.setDataLengthToHeader(buffer : TBytes; length : Integer; pkgHeaderOption : pkg_header.PkgHeaderOption);
var

  length16 : int16;
  length32 : Int32;
begin
  if pkgHeaderOption.headerSize = 2 then
  begin
    length16 := htons(length);
    Move(length16, buffer[0], 2);
  end;

  if pkgHeaderOption.headerSize = 4 then
  begin
    length32 := htonl(length);
    Move(length32, buffer[0], 4);
  end;
end;

class function PkgSender.makeDataToSend(data : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption):TBytes;
var
  dataLength : Integer;
  buffer : TBytes;
begin
  dataLength := Length(data);

  if dataLength > PkgHeaderOption.maxDataSize then
  begin
    Result := buffer;
    Exit;
  end;

  SetLength(buffer, pkgHeaderOption.headerFrameLen + dataLength);
  self.setDataLengthToHeader(buffer, dataLength, pkgHeaderOption);

  CopyMemory(@buffer[pkgHeaderOption.headerFrameLen], data, dataLength);
  Result := buffer;
end;

end.
