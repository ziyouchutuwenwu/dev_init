unit tcp_client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinSock, StdCtrls, pkg_header, pkg_sender, pkg_recv, pkg_callback, tcp_callback;

type
  TcpClient = class(TInterfacedObject, IPkgCallBack)
  private
    _socket: Integer;
    _isConnected: Boolean;
    _uiCallback: ITCPCallback;

    _threadThread: TThread;
    _pkgHeaderOption : pkg_header.PkgHeaderOption;
    _pkgSender : pkg_sender.PkgSender;
    _pkgRecv : pkg_recv.PkgRecv;

    procedure asyncConnect(ip : string; port : Integer);
    procedure startReadThread();
    procedure stopReadThread();
    procedure onReadThreadProc();

    procedure onConnected();
    // IPkgCallBack = interface
    procedure onDisConnected();
    procedure onFullData(data : TBytes);

  public
    constructor Create(AOwner: TComponent); virtual;
    procedure send(data : TBytes);
    procedure setCallBack(callback : ITCPCallback);
    procedure connect(ip : string; port : Integer);
    procedure disConnect();

  published
    property isConnected: Boolean read _isConnected;
  end;
implementation

{ TcpClient }

constructor TcpClient.Create(AOwner: TComponent);
var
  wsaData: TWSAData;
begin
  inherited create;

  _pkgHeaderOption := PkgHeaderOption.Create();
  _pkgHeaderOption.setPkgOptionWithHeaderSize(2);

  _pkgSender := PkgSender.Create;
  _pkgRecv := PkgRecv.Create;
  _pkgRecv.setPkgCallBack(self);

  Self._isConnected := False;
  WSAStartup($101, wsaData);
end;

procedure TcpClient.send(data : TBytes);
var
  i : Integer;
  result : TBytes;
  totalLength : integer;
  dataToSend: array[0..512] of byte;
begin
  if Self._isConnected = True then
  begin
    result := PkgSender.makeDataToSend(data, _pkgHeaderOption);
  totalLength := _pkgHeaderOption.headerSize + length(data);
  for i := 0 to totalLength-1 do
  begin
    dataToSend[i] := result[i];
  end;
  WinSock.send(self._socket, dataToSend, totalLength, 0);
  end;
end;

procedure TcpClient.setCallBack(callback : ITCPCallback);
begin
  self._uiCallback := callback;
end;

procedure TcpClient.connect(ip : string; port : Integer);
begin
  if Self._isConnected = True then
  begin
    Exit;
  end;

  if self._uiCallback <> nil then
  begin
    self._uiCallback.onConnectStarted();
  end;

  asyncConnect(ip, port);
end;

procedure TcpClient.asyncConnect(ip : string; port : Integer);
var
  sockAddr : TSockAddrIn;
  connectResult : integer;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      sockAddr.sin_family := AF_INET;
      sockAddr.sin_port := htons(port);
      sockAddr.sin_addr.S_addr := inet_addr(PAnsiChar(AnsiString(ip)));

      self._socket := WinSock.socket(AF_INET,SOCK_STREAM,0);
      connectResult := WinSock.connect(self._socket, sockAddr, SizeOf(sockAddr));
      if connectResult = 0 then
      begin
        Self._isConnected := True;
      end;

      if Self._isConnected then
      begin
        Self.onConnected();
      end
      else
      begin
        Self.onDisConnected();
      end;
    end
  ).start();
end;

procedure TcpClient.startReadThread();
begin
  _threadThread := TThread.CreateAnonymousThread(
    procedure
    begin
      _threadThread.FreeOnTerminate := True;
      self.onReadThreadProc();
    end
  );
  _threadThread.start();
end;
procedure TcpClient.stopReadThread();
begin
  if _threadThread <> nil then
  begin
    _threadThread.Terminate();
    _threadThread := nil;
  end;
end;
procedure TcpClient.onReadThreadProc();
begin
  _pkgRecv.loopRead(Self._socket, _pkgHeaderOption);
end;

procedure TcpClient.disConnect();
begin
  if Self._isConnected = True then
  begin
    WinSock.closesocket(Self._socket);
  end;
end;

procedure TcpClient.onConnected();
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if self._uiCallback <> nil then
      begin
        self._uiCallback.onConnected();
      end;
    end);

  startReadThread();
end;

procedure TcpClient.onDisConnected();
begin
  stopReadThread();
  Self._isConnected := false;

  TThread.Synchronize(nil,
    procedure
    begin
      if self._uiCallback <> nil then
      begin
        self._uiCallback.onDisConnected();
      end;
    end);
end;

procedure TcpClient.onFullData(data : TBytes);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if self._uiCallback <> nil then
      begin
        self._uiCallback.onFullData(data);
      end;
    end);
end;
end.
