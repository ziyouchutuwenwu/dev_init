unit pkg_recv;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinSock, StdCtrls, pkg_header, pkg_callback;

type
  PkgRecv = class(TObject)
  private
    _savedData : TBytes;
    _pkgCallBack: IPkgCallBack;

    function getDataLenthFromHeader(buffer : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption): Integer;
    procedure dealWithData(totalData : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption);

  public
    constructor Create(); virtual;
    procedure setPkgCallBack(callback : IPkgCallBack);
    procedure loopRead(socket : Integer; pkgHeaderOption : pkg_header.PkgHeaderOption);
  end;
implementation

constructor PkgRecv.Create();
begin
  inherited Create;

  SetLength(_savedData, 0);
end;

procedure PkgRecv.setPkgCallBack(callback : IPkgCallBack);
begin
  Self._pkgCallBack := callback;
end;

procedure PkgRecv.loopRead(socket : Integer; pkgHeaderOption : pkg_header.PkgHeaderOption);
const
  READ_BUFFER_SIZE = 8;
var
  // 这里不能用动态数组
  readBuffer : array[0..READ_BUFFER_SIZE] of byte;
  readLen : Integer;

  buffer : TBytes;
  totalData : TBytes;
begin
  while(true) do
  begin
    readLen := WinSock.recv(socket, readBuffer, READ_BUFFER_SIZE, 0);

    if readLen <= 0 then
    begin
      if Self._pkgCallBack <> nil then
      begin
        self._pkgCallBack.onDisConnected();
        Break;
      end;
    end;

    SetLength(buffer, readlen);
    CopyMemory(buffer, @readBuffer[0], readLen);

    SetLength(totalData, Length(Self._savedData) + Length(buffer));
    CopyMemory(totalData, Self._savedData, Length(Self._savedData));
    CopyMemory(@totalData[Length(Self._savedData)], buffer, Length(buffer));

    Self.dealWithData(totalData, pkgHeaderOption);

  end;
end;

procedure PkgRecv.dealWithData(totalData : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption);
var
  totalDataLen : Integer;
  dataLen : Integer;
  frameLen : Integer;
  frameData : TBytes;
begin
  totalDataLen := Length(totalData);

  if totalDataLen <= PkgHeaderOption.headerSize then
  begin
    SetLength(Self._savedData, Length(totalData));
    CopyMemory(Self._savedData, totalData, Length(totalData));
  end;

  if totalDataLen > PkgHeaderOption.headerSize then
  begin
    dataLen := Self.getDataLenthFromHeader(totalData, pkgHeaderOption);

    if totalDataLen < pkgHeaderOption.headerSize + dataLen then
    begin
      SetLength(Self._savedData, Length(totalData));
      CopyMemory(Self._savedData, totalData, Length(totalData));
    end;

    if totalDataLen >= pkgHeaderOption.headerSize + dataLen then
    begin
      frameLen := pkgHeaderOption.headerSize + dataLen;

      // 一包数据
      SetLength(frameData, frameLen - pkgHeaderOption.headerSize);
      CopyMemory(frameData, @totalData[pkgHeaderOption.headerSize], frameLen - pkgHeaderOption.headerSize);
      if Self._pkgCallBack <> nil then
      begin
        self._pkgCallBack.onFullData(frameData);
      end;

      SetLength(self._savedData, Length(totalData) - frameLen);
      CopyMemory(self._savedData, @totalData[frameLen], Length(totalData) - frameLen);

      SetLength(totalData, Length(self._savedData));
      CopyMemory(totalData, Self._savedData, Length(Self._savedData));
    end;
  end;

end;

function PkgRecv.getDataLenthFromHeader( buffer : TBytes; pkgHeaderOption : pkg_header.PkgHeaderOption): Integer;
var
  dataLenth : Integer;
  length16 : int16;
  length32 : Int32;
begin
  dataLenth := 0;
  length16 := 0;
  length32 := 0;

  if pkgHeaderOption.headerSize = 2 then
  begin
    Move(buffer[0], length16, SizeOf(length16));
    dataLenth := ntohs(length16);
  end;

  if pkgHeaderOption.headerSize = 4 then
  begin
    Move(buffer[0], length32, 2);
    dataLenth := ntohl(length32);
  end;

  Result := dataLenth;
end;

end.
