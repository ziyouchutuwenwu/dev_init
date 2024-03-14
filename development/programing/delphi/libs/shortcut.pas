unit shortcut;

interface

uses Windows, SysUtils, ComObj, ActiveX, ShlObj, Registry;

type
  TLINK_FILE_INFO = record
    Filename: array [0..MAX_PATH] of Char; { 目标文件名 }
    WorkDirectory: array [0..MAX_PATH] of Char; { 工作目录或者起始目录 }
    IconLocation: array [0..MAX_PATH] of Char; { 图标文件名 }
    IconIndex: Integer; { 图标索引 }
    Arguments: array [0..MAX_PATH] of Char; { 程序运行的参数 }
    Description: array [0..MAX_PATH] of Char; { 快捷方式的描述 }
    ItemIDList: PItemIDList; { 只供读取使用 }
    RelativePath: array [0..255] of Char; { 相对目录，只能设置 }
    ShowState: Integer; { 运行时的窗口状态 }
    HotKey: Word; { 快捷键 }
  end;

function isWin64(): Boolean;

function getShortcutInfo(shotcutFileName: String):TLINK_FILE_INFO;
procedure createShortcut(dir, name, description, originalFileName:string; isForced:Boolean=False);

implementation

function isWin64(): Boolean;
var
  Kernel32Handle: THandle;
  IsWow64Process: function(Handle: Windows.THandle; var Res: Windows.BOOL): Windows.BOOL; stdcall;
  GetNativeSystemInfo: procedure(var lpSystemInfo: TSystemInfo); stdcall;
  isWoW64: Bool;
  SystemInfo: TSystemInfo;
const
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
  PROCESSOR_ARCHITECTURE_IA64 = 6;
begin
  Kernel32Handle := GetModuleHandle('KERNEL32.DLL');
  if Kernel32Handle = 0 then
    Kernel32Handle := LoadLibrary('KERNEL32.DLL');
  if Kernel32Handle <> 0 then
  begin
    IsWOW64Process := GetProcAddress(Kernel32Handle,'IsWow64Process');
    GetNativeSystemInfo := GetProcAddress(Kernel32Handle,'GetNativeSystemInfo');
    if Assigned(IsWow64Process) then
    begin
      IsWow64Process(GetCurrentProcess,isWoW64);
      Result := isWoW64 and Assigned(GetNativeSystemInfo);
      if Result then
      begin
        GetNativeSystemInfo(SystemInfo);
        Result := (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64) or
                  (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_IA64);
      end;
    end
    else Result := False;
  end
  else Result := False;
end;

function getShortcutInfo(shotcutFileName: String):TLINK_FILE_INFO;
var
  linkInfo : TLINK_FILE_INFO;
  linkObj : IUnknown;
  shotcutComObject : IPersistFile;
  shellLinkObject : IShellLink;
  fileName: WideString;
  pfd : WIN32_FIND_DATA;
begin
  FillChar(linkInfo, SizeOf(linkInfo), #0);
  linkObj := CreateComObject(CLSID_ShellLink);
  shotcutComObject := linkObj as IPersistFile;
  shellLinkObject := linkObj as IShellLink;
  fileName := shotcutFileName;
  shotcutComObject.Load(PWideChar(fileName), 0);
  shellLinkObject.GetPath(linkInfo.Filename, MAX_PATH, pfd, SLGP_UNCPRIORITY); { 获取快捷方式文件路径 }
  shellLinkObject.GetWorkingDirectory(linkInfo.WorkDirectory, MAX_PATH); { 获取快捷方式工作目录 }
  shellLinkObject.GetIconLocation(linkInfo.IconLocation, MAX_PATH, linkInfo.IconIndex); { 获取快捷方式图标文件，和图标索引 }
  shellLinkObject.GetArguments(linkInfo.Arguments, MAX_PATH); { 获取快捷方式运行参数 }
  shellLinkObject.GetDescription(linkInfo.Arguments, MAX_PATH); { 获取快捷方式描述 }
  shellLinkObject.GetShowCmd(linkInfo.ShowState); { 获取快捷方式运行方式，1：常规窗体；2：最小化；3：最大化 }
  shellLinkObject.GetHotkey(linkInfo.HotKey); { 获取快捷方式快捷键 }
  shellLinkObject := nil;
  shotcutComObject := nil;
  Result := linkInfo;
end;

procedure createShortcut(dir, name, description, originalFileName:string; isForced:Boolean=False);
var
  shotcutFileName : string;
  isShotcutExist : Boolean;
  shellLinkObject : IShellLink;
  shotcutComObject : IPersistFile;
  fileToSave : WideString;
  regObj : TRegIniFile;
  comObject : IUnknown;
begin
  shotcutFileName := dir + '\' + name +'.lnk';
  isShotcutExist := FileExists(shotcutFileName);
  if (isShotcutExist and isForced) or ( not isShotcutExist ) then
  begin
    try
      regObj := TRegIniFile.Create('Software\MicroSoft\Windows\CurrentVersion\Explorer');
      comObject := CreateComObject(CLSID_ShellLink);
      shellLinkObject := comObject as IShellLink;
      shotcutComObject := comObject as IPersistFile;
      shellLinkObject.SetPath(PChar(originalFileName));
      shellLinkObject.SetWorkingDirectory(PChar(ExtractFilePath(originalFileName)));
      shellLinkObject.SetDescription(PChar(description));
      shotcutComObject.Save(PWideChar(shotcutFileName), False);
    finally
      regObj.Free;
    end;
  end;
end;

end.
