unit dir;

interface

uses Windows, Classes, StrUtils, SysUtils, ComObj, ActiveX, ShlObj, Registry;

function getSystemStartUpDir():string;
function getUserStartUpDir():string;
function getDesktopPath():string;
function listFiles(dir, ext : string):TStringList;

implementation

function getSystemStartUpDir():string;
begin
  Result := 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\';
end;

function getUserStartUpDir():string;
var
  regObj : TRegIniFile;
begin
  regObj := TRegIniFile.Create('Software\MicroSoft\Windows\CurrentVersion\Explorer');
  Result := regObj.ReadString('Shell Folders', 'startup', '')
end;

function getDesktopPath():string;
var
  pitem:PITEMIDLIST;
  Buffer:PChar;
begin
  Buffer:=StrAlloc(1024);
  shGetSpecialFolderLocation(0,CSIDL_DESKTOP,pitem);
  shGetPathFromIDList(pitem,Buffer);
  Result:= string(Buffer);
  StrDispose(Buffer);
end;

function listFiles(dir, ext : string):TStringList;
var
  searcher: TSearchrec;
  dirToSearch: string;
  fileList: TStringList;
  subFileList : TStringList;
  index : Integer;
begin
  fileList := TStringList.Create;

  if RightStr(Trim(dir), 1) <> '\' then
    dirToSearch := Trim(dir) + '\'
  else
    dirToSearch := Trim(dir);

  if FindFirst(dirToSearch + '*', faAnyfile, searcher) = 0 then
  begin
    repeat
      if ((searcher.Name = '.') or (searcher.Name = '..')) then Continue;
      if DirectoryExists(dirToSearch + searcher.Name) then
      begin
        subFileList := listFiles(dirToSearch + searcher.Name, ext);
        for index := 0 to subFileList.Count - 1 do
        begin
          fileList.Add(subFileList[index]);
        end;
      end
      else
        begin
          if (UpperCase(ExtractFileExt(dirToSearch + searcher.Name)) = UpperCase(ext)) or (ext = '.*') then
          begin
            fileList.Add(dirToSearch + searcher.Name);
          end;
        end;
    until FindNext(searcher) <> 0;
    SysUtils.FindClose(searcher);
  end;
  Result := fileList;
end;

end.
