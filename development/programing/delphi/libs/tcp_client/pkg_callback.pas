unit pkg_callback;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinSock, StdCtrls;

type
  IPkgCallBack = interface
    procedure onDisConnected();
    procedure onFullData(data : TBytes);
  end;

implementation

end.
