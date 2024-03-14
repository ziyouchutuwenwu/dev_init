unit tcp_callback;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinSock, StdCtrls;

type
  ITCPCallback = interface
    procedure onConnectStarted();
    procedure onConnected();
    procedure onDisConnected();
    procedure onFullData(data : TBytes);
  end;
implementation

end.
