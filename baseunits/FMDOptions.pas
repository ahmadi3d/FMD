unit FMDOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fileinfo, jsonini, FileUtil, Forms, Graphics,
  LazFileUtils, LazUTF8;

type

  TFMDDo = (DO_NOTHING, DO_EXIT, DO_POWEROFF, DO_HIBERNATE, DO_UPDATE);

const
  FMD_INSTANCE = '_FreeMangaDownloaderInstance_';
  FMD_TARGETOS  = {$i %FPCTARGETOS%};
  FMD_TARGETCPU = {$i %FPCTARGETCPU%};

  EXPARAM_PATH = '%PATH%';
  EXPARAM_CHAPTER = '%CHAPTER%';
  DEFAULT_EXPARAM = '"' + EXPARAM_PATH + EXPARAM_CHAPTER + '"';

  DEFAULT_MANGA_CUSTOMRENAME = '%MANGA%';
  DEFAULT_CHAPTER_CUSTOMRENAME = '%CHAPTER%';
  DEFAULT_FILENAME_CUSTOMRENAME = '%FILENAME%';

  DATA_EXT = '.dat';
  DBDATA_EXT = '.db';
  DBDATA_SERVER_EXT = '.7z';
  UPDATER_EXE = 'updater.exe';
  OLD_UPDATER_EXE = 'old_' + UPDATER_EXE;
  ZIP_EXE = '7za.exe';
  RUN_EXE = '.run';

  SOCKHEARTBEATRATE = 500;
  {$IFDEF WINDOWS}
  {$IFDEF WIN32}
  MAX_TASKLIMIT = 16;
  MAX_CONNECTIONPERHOSTLIMIT = 64;
  {$ENDIF}
  {$IFDEF WIN64}
  MAX_TASKLIMIT = 64;
  MAX_CONNECTIONPERHOSTLIMIT = 256;
  {$ENDIF}
  {$ELSE}
  MAX_TASKLIMIT = 8;
  MAX_CONNECTIONPERHOSTLIMIT = 32;
  {$ENDIF}

  BACKUP_FILE_PREFIX = 'fmdbackup_';
  BACKUP_FILE_EXT = '7z';

{$i revision.inc}

var
  FMD_VERSION_NUMBER: TProgramVersion;
  FMD_VERSION_STRING,
  FMD_DIRECTORY,
  FMD_EXENAME,
  CURRENT_UPDATER_EXE,
  OLD_CURRENT_UPDATER_EXE,
  CURRENT_ZIP_EXE,
  APPDATA_DIRECTORY,
  DEFAULT_PATH,
  USERDATA_FOLDER,
  DOWNLOADSDB_FILE,
  DOWNLOADEDCHAPTERS_FILE,
  DOWNLOADEDCHAPTERSDB_FILE,
  FAVORITES_FILE,
  FAVORITESDB_FILE,
  CONFIG_FOLDER,
  SETTINGS_FILE,
  BASE_FILE,
  ACCOUNTS_FILE,
  MODULES_FILE,
  DATA_FOLDER,
  IMAGE_FOLDER,
  CHANGELOG_FILE,
  DEFAULT_LOG_FILE,
  README_FILE,
  LUA_WEBSITEMODULE_FOLDER,
  LUA_REPO_FOLDER,
  LUA_REPO_FILE,
  LUA_REPO_WORK_FILE,
  BACKUP_FOLDER: String;

  // program params
  AppParams: TStringList;

  // json files
  settingsfile: TJSONIniFile;

  // base url, should be in base.json
  DEFAULT_SELECTED_WEBSITES: String = '';
  DB_URL: String = '';
  UPDATE_URL: String = '';
  UPDATE_PACKAGE_NAME: String = '';

  currentWebsite: String;

  // available website
  AvailableWebsites: TStringList;

  // general
  DoAfterFMD: TFMDDo;
  OptionLetFMDDo: TFMDDo = DO_NOTHING;
  OptionDeleteCompletedTasksOnClose: Boolean = False;
  OptionSortDownloadsWhenAddingNewDownloadTasks: Boolean = False;

  // saveto
  OptionChangeUnicodeCharacter: Boolean = False;
  OptionChangeUnicodeCharacterStr: String = '_';
  OptionGenerateMangaFolder: Boolean = False;
  OptionMangaCustomRename: String;
  OptionGenerateChapterFolder: Boolean = True;
  OptionChapterCustomRename: String;
  OptionFilenameCustomRename: String;

  OptionConvertDigitVolume: Boolean;
  OptionConvertDigitChapter: Boolean;
  OptionConvertDigitVolumeLength: Integer;
  OptionConvertDigitChapterLength: Integer;

  OptionPDFQuality: Cardinal = 95;

  OptionPNGSaveAsJPEG: Boolean = False;
  OptionWebPSaveAs: Integer = 1;
  OptionPNGCompressionLevel: Integer = 1;
  OptionJPEGQuality: Integer = 80;

  // connections
  OptionMaxParallel: Integer = 1;
  OptionMaxThreads: Integer = 1;
  OptionMaxRetry: Integer = 5;
  OptionConnectionTimeout: Integer = 30;
  OptionRetryFailedTask: Integer = 1;
  OptionAlwaysStartTaskFromFailedChapters: Boolean = True;
  OptionEnableCloudflareBypass: Boolean = True;
  OptionAutomaticallyDisableCloudflareBypass: Boolean = False;

  // view
  OptionEnableLoadCover: Boolean = False;
  OptionShowBalloonHint: Boolean = True;
  OptionShowFavoritesTabOnNewManga: Boolean = False;
  OptionShowDownloadsTabOnNewTasks: Boolean = True;
  
  // favorites (context menu settings)
  OptionDefaultAction: Integer = 0;

  // updates
  OptionAutoCheckLatestVersion: Boolean = True;
  OptionAutoCheckFavStartup: Boolean = True;
  OptionAutoCheckFavInterval: Boolean = True;
  OptionAutoCheckFavIntervalMinutes: Cardinal = 60;
  OptionNewMangaTime: Integer = 1;
  OptionJDNNewMangaTime: Integer = MaxInt;
  OptionAutoCheckFavDownload: Boolean = False;
  OptionAutoCheckFavRemoveCompletedManga: Boolean = False;
  OptionUpdateListNoMangaInfo: Boolean = False;
  OptionUpdateListRemoveDuplicateLocalData: Boolean = False;

  // modules
  OptionModulesUpdaterShowUpdateWarning: Boolean = True;
  OptionModulesUpdaterAutoRestart: Boolean = False;

  OptionHTTPUseGzip: Boolean = True;

  OptionRemoveMangaNameFromChapter: Boolean = False;

  OptionRestartFMD: Boolean = False;

  //custom color
  //basiclist
  CL_BSNormalText: TColor = clWindowText;
  CL_BSFocusedSelectionText: TColor = clHighlightText;
  CL_BSUnfocesedSelectionText: TColor = clWindowText;
  CL_BSOdd: TColor = clBtnFace;
  CL_BSEven: TColor = clWindow;
  CL_BSSortedColumn: TColor = $F8E6D6;
  CL_BSEnabledWebsiteSettings: TColor = clYellow;

  //mangalist color
  CL_MNNewManga: TColor = $FDC594;
  CL_MNCompletedManga: TColor = $B8FFB8;

  //favoritelist color
  CL_FVBrokenFavorite: TColor = $8080FF;
  CL_FVChecking: TColor = $80EBFE;
  CL_FVNewChapterFound: TColor = $FDC594;
  CL_FVCompletedManga: TColor = $B8FFB8;
  CL_FVEmptyChapters: TColor = $CCDDFF;

  //chapterlist color
  CL_CHDownloaded: TColor = $B8FFB8;

// set base directory
procedure SetFMDdirectory(const ADir: String);
procedure SetAppDataDirectory(const ADir: String);

procedure RestartFMD;
procedure DoRestartFMD;

implementation

uses process, UTF8Process;

procedure FreeNil(var Obj);
begin
  if Pointer(Obj) <> nil then
    TObject(Obj).Free;
  Pointer(Obj) := nil;
end;

procedure FreeIniFiles;
begin
  FreeNil(settingsfile);
end;

procedure SetIniFiles;
begin
  FreeIniFiles;
  settingsfile := TJSONIniFile.Create(SETTINGS_FILE);
end;

procedure ReadBaseFile;
begin
  if not FileExistsUTF8(BASE_FILE) then Exit;
  with TJSONIniFile.Create(BASE_FILE) do
    try
      DEFAULT_SELECTED_WEBSITES:=ReadString('base','default_selected_websites',DEFAULT_SELECTED_WEBSITES);
      DB_URL:=ReadString('base','db_url',DB_URL);
      UPDATE_URL:=ReadString('base','update_url',UPDATE_URL);
      UPDATE_PACKAGE_NAME:=ReadString('base','update_package_name',UPDATE_PACKAGE_NAME);
    finally
      Free;
    end;
end;

procedure SetFMDdirectory(const ADir: String);
begin
  FMD_DIRECTORY := CleanAndExpandDirectory(ADir);
  FMD_EXENAME := ExtractFileNameOnly(Application.ExeName);

  CONFIG_FOLDER := FMD_DIRECTORY + 'config' + PathDelim;
  BASE_FILE := CONFIG_FOLDER + 'base.json';

  IMAGE_FOLDER := FMD_DIRECTORY + 'images' + PathDelim;
  CHANGELOG_FILE := FMD_DIRECTORY + 'changelog.txt';
  README_FILE := FMD_DIRECTORY + 'readme.rtf';
  DEFAULT_LOG_FILE := FMD_EXENAME + '.log';
  CURRENT_UPDATER_EXE := FMD_DIRECTORY + UPDATER_EXE;
  OLD_CURRENT_UPDATER_EXE := FMD_DIRECTORY + OLD_UPDATER_EXE;
  CURRENT_ZIP_EXE := FMD_DIRECTORY + ZIP_EXE;

  BACKUP_FOLDER := FMD_DIRECTORY + 'backup' + PathDelim;

  ReadBaseFile;
end;

procedure SetAppDataDirectory(const ADir: String);
begin
  APPDATA_DIRECTORY := CleanAndExpandDirectory(ADir);

  DEFAULT_PATH := 'downloads' + PathDelim;

  CONFIG_FOLDER := APPDATA_DIRECTORY + 'config' + PathDelim;
  DATA_FOLDER := APPDATA_DIRECTORY + 'data' + PathDelim;
  USERDATA_FOLDER := APPDATA_DIRECTORY + 'userdata' + PathDelim;

  SETTINGS_FILE := USERDATA_FOLDER + 'settings.json';
  ACCOUNTS_FILE := USERDATA_FOLDER + 'accounts.db';
  MODULES_FILE := USERDATA_FOLDER + 'modules.json';
  LUA_REPO_FILE := USERDATA_FOLDER + 'lua.json';
  LUA_REPO_WORK_FILE := USERDATA_FOLDER + 'lua_repo.json';
  DOWNLOADSDB_FILE := USERDATA_FOLDER + 'downloads.db';
  DOWNLOADEDCHAPTERSDB_FILE := USERDATA_FOLDER + 'downloadedchapters.db';
  FAVORITESDB_FILE := USERDATA_FOLDER + 'favorites.db';

  LUA_WEBSITEMODULE_FOLDER := FMD_DIRECTORY + 'lua' + PathDelim + 'modules' + PathDelim;
  LUA_REPO_FOLDER := FMD_DIRECTORY + 'lua' + PathDelim;

  SetIniFiles;
end;

procedure RestartFMD;
begin
  OptionRestartFMD := True;
  Application.MainForm.Close;
end;

procedure DoRestartFMD;
var
  p: TProcessUTF8;
begin
  p := TProcessUTF8.Create(nil);
  try
    p.InheritHandles := False;
    p.CurrentDirectory := FMD_DIRECTORY;
    p.Executable := Application.ExeName;
    p.Options := [];
    p.InheritHandles := False;
    p.Parameters.AddStrings(AppParams);
    {$ifdef windows}
    p.Parameters.Add('--dorestart-handle=' + IntToStr(Integer(Application.Handle)));
    {$ifend}
    p.Execute;
  finally
    p.Free;
  end;
end;

procedure doInitialization;
begin
  AppParams:=TStringList.Create;
  AppParams.NameValueSeparator:='=';
  GetProgramVersion(FMD_VERSION_NUMBER);
  FMD_VERSION_STRING := ProgramversionToStr(FMD_VERSION_NUMBER);
  AvailableWebsites := TStringList.Create;
  AvailableWebsites.Sorted := False;
  SetFMDdirectory(ExtractFilePath(Application.ExeName));
  SetAppDataDirectory(FMD_DIRECTORY);
end;

procedure doFinalization;
begin
  FreeIniFiles;
  AvailableWebsites.Free;
  AppParams.Free;
end;

initialization
  doInitialization;

finalization
  doFinalization;

end.
