unit pkg_header;

interface

type
  PkgHeaderOption = class(TObject)
  private
    _headerSize : Integer;
    _maxDataSize : integer;
    _headerFrameLen : integer;

  published
    property headerSize: Integer read _headerSize;
    property maxDataSize: Integer read _maxDataSize;
    property headerFrameLen: Integer read _headerFrameLen;
  public
    procedure setPkgOptionWithHeaderSize(headerSize : integer);
  end;
implementation

procedure PkgHeaderOption.setPkgOptionWithHeaderSize(headerSize : integer);
begin
  if headerSize = 0 then
  begin
    Self._headerSize := 2;
  end;

  if ( headerSize <> 2 ) and (headerSize <> 4 ) then
  begin
    Exit;
  end;

  Self._headerSize := headerSize;
  if Self._headerSize = 2 then
  begin
    Self._maxDataSize := $ffff;
    self._headerFrameLen := 2;
  end;

  if Self._headerSize = 4 then
  begin
    Self._maxDataSize := $7fffffff;
    self._headerFrameLen := 4;
  end;
end;
end.
