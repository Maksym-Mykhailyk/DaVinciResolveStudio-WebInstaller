!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "Util.nsh"
!include "x64.nsh"
!insertmacro GetRoot
!insertmacro DriveSpace
!insertmacro GetSize
!define RESOLVE_VERSION  "21.1.1"
!define INSTALLER_VERSION "1.1"
!define DLID_STUDIO_WIN  "2cc28475f6f44183a923d0f44d1efa2e"
!define DLID_FREE_WIN    "1da0b14a2d19465ba8e214222b383b8f"
!define REG_FIRSTNAME "Resolve"
!define REG_LASTNAME  "User"
!define REG_EMAIL     "resolve.user@example.com"
!define REG_PHONE     "202-555-0194"
!define REG_COUNTRY   "us"
!define REG_STATE     "New York"
!define REG_CITY      "New York"
!define REG_PRODUCT   "DaVinci Resolve"
!define BMD_REGISTER_API "https://www.blackmagicdesign.com/api/register/us/download"
!define SETUP_SILENT_ARGS "/i /q /noreboot"
Unicode true
RequestExecutionLevel admin
CRCCheck on
SetCompressor /SOLID lzma
ShowInstDetails show
Name "Davinci Resolve Studio v${RESOLVE_VERSION}.10"
OutFile "DaVinciResolve_${RESOLVE_VERSION}_WebInstaller_${INSTALLER_VERSION}_NoCDN.exe"
BrandingText " "
VIProductVersion "1.1.0.0"
VIAddVersionKey "CompanyName" "Blackmagic Design"
VIAddVersionKey "FileDescription" "Davinci Resolve Studio v21.1.1.10 installer 1.1 NoCDN"
VIAddVersionKey "FileVersion" "1.1.0.0"
VIAddVersionKey "LegalCopyright" "c Blackmagic Design"
VIAddVersionKey "ProductName" "Davinci Resolve Studio v21.1.1.10"
VIAddVersionKey "ProductVersion" "1.1.0.0"
!define MUI_ICON "Resurs\ResolveStudioInstaller.ico"
!define MUI_UNICON "Resurs\ResolveStudioInstaller.ico"
Var SetupDir
Var DownloadId
Var EditionTitle
Var CdnUrl
Var ZipPath
Var SetupExe
Var HelperPowerShell
!insertmacro MUI_PAGE_WELCOME
!define MUI_LICENSEPAGE_CHECKBOX
!insertmacro MUI_PAGE_LICENSE "notice.txt"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"
LangString SEC_INSTALL     1033 "Install"
LangString TXT_ADMIN       1033 "Administrator rights are required."
LangString TXT_DISK_LOW    1033 "Not enough disk space: at least ~22 GB free is required."
LangString TXT_DISK_WARN  1033 "Less than 33 GB free — the setup may not fit (archive ~10 GB + extraction + install ~12 GB).$\n$\nContinue?"
LangString TXT_API         1033 "Requesting a signed download link from the Blackmagic Design server..."
LangString TXT_API_FAIL   1033 "The server did not return a download link."
LangString TXT_NET_HINT    1033 "For SSL/TLS errors: check the Windows date, time and time zone, disable HTTPS scanning in your antivirus or proxy, and install Windows root certificate updates."
LangString TXT_API_BAD     1033 "Unexpected server response. Check your connection and try again later."
LangString TXT_DL_START    1033 "Downloading the official archive (~9.6 GB)..."
LangString TXT_DL_FAIL     1033 "Download failed."
LangString TXT_DL_SMALL    1033 "The downloaded file is corrupt or incomplete. Try again."
LangString TXT_EXTRACT      1033 "Extracting the archive (this may take several minutes)..."
LangString TXT_EXTRACT_FAIL 1033 "Failed to extract the archive."
LangString TXT_NO_EXE      1033 "The Blackmagic installer was not found in the archive."
LangString TXT_RUN_UI      1033 "Launching the official Blackmagic Design installer..."
LangString TXT_RUN_SILENT  1033 "Silent installation with the official installer..."
LangString TXT_SETUP_RC    1033 "The official installer exited with code $0.$\n$\nFiles are kept at:$\n$SetupDir"
LangString TXT_DONE        1033 "Installation finished. On first launch Resolve will offer activation (for Studio)."
LangString TXT_CLEANUP     1033 "Cleaning up temporary files..."
Section "$(SEC_INSTALL)" SEC_MAIN
  Call PerformInstall
SectionEnd
Function PerformInstall
  System::Call 'kernel32::SetEnvironmentVariable(t "NSIS_HWND", t "$HWNDPARENT")'
  StrCpy $DownloadId "${DLID_STUDIO_WIN}"
  StrCpy $EditionTitle "DaVinci Resolve Studio ${RESOLVE_VERSION}"
  StrCpy $ZipPath "$SetupDir\resolve_setup.zip"
  CreateDirectory "$SetupDir"
  InitPluginsDir
  Call WriteHelperScript
  DetailPrint "$(TXT_API)"
  StrCpy $1 'api "${BMD_REGISTER_API}/$DownloadId" "$PLUGINSDIR\cdn_url.txt"'
  Call RunHelper
  ${If} $3 != 0
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_API_FAIL) (exit $3)$\n$\n$0$\n$\n$(TXT_NET_HINT)" /SD IDOK
    Abort
  ${EndIf}
  ClearErrors
  FileOpen $0 "$PLUGINSDIR\cdn_url.txt" r
  ${If} ${Errors}
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_API_FAIL)" /SD IDOK
    Abort
  ${EndIf}
  FileRead $0 $CdnUrl 2048
  FileClose $0
  StrCpy $0 $CdnUrl
  Call TrimCRLF
  StrCpy $CdnUrl $0
  StrCpy $1 $CdnUrl 8
  ${If} $1 != "https://"
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_API_BAD)" /SD IDOK
    Abort
  ${EndIf}
  DetailPrint "$(TXT_DL_START)"
  StrCpy $1 'download "$CdnUrl" "$ZipPath"'
  Call RunHelper
  ${If} $3 != 0
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_DL_FAIL) (exit $3)$\n$\n$0$\n$\n$(TXT_NET_HINT)" /SD IDOK
    Abort
  ${EndIf}
  StrCpy $1 'checksize "$ZipPath" "$ZipPath"'
  Call RunHelper
  ${If} $3 != 0
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_DL_SMALL)$\n$\n$0" /SD IDOK
    Abort
  ${EndIf}
  DetailPrint "$(TXT_EXTRACT)"
  RMDir /r "$SetupDir\payload"
  StrCpy $1 'extract "$ZipPath" "$SetupDir\payload"'
  Call RunHelper
  ${If} $3 != 0
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_EXTRACT_FAIL) (exit $3)$\n$\n$0" /SD IDOK
    Abort
  ${EndIf}
  FindFirst $0 $1 "$SetupDir\payload\*Resolve*.exe"
  ${If} $1 == ""
    FindClose $0
    FindFirst $0 $1 "$SetupDir\payload\*.exe"
  ${EndIf}
  ${If} $1 == ""
    FindClose $0
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_NO_EXE)" /SD IDOK
    Abort
  ${EndIf}
  StrCpy $SetupExe "$SetupDir\payload\$1"
  FindClose $0
  ${If} ${Silent}
    DetailPrint "$(TXT_RUN_SILENT)"
    ExecWait '"$SetupExe" ${SETUP_SILENT_ARGS}' $0
  ${Else}
    DetailPrint "$(TXT_RUN_UI)"
    ExecWait '"$SetupExe"' $0
  ${EndIf}
  ${If} $0 == 3010
  ${OrIf} $0 == 1641
    StrCpy $0 0
  ${EndIf}
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(TXT_SETUP_RC)" /SD IDOK
    Abort
  ${EndIf}
  DetailPrint "$(TXT_CLEANUP)"
  Delete "$ZipPath"
  RMDir /r "$SetupDir\payload"
  RMDir "$SetupDir"
  DetailPrint "$(TXT_DONE)"
FunctionEnd
Function RunHelper
  Delete "$PLUGINSDIR\error.txt"
  ${If} ${IsWow64}
    StrCpy $HelperPowerShell "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  ${Else}
    StrCpy $HelperPowerShell "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe"
  ${EndIf}
  nsExec::ExecToLog '"$HelperPowerShell" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\setup.ps1" $1 "$PLUGINSDIR\error.txt"'
  Pop $3
  ${If} $3 == "error"
  ${OrIf} $3 == "timeout"
    StrCpy $3 1
  ${EndIf}
  StrCpy $0 ""
  ${If} $3 != 0
    ClearErrors
    FileOpen $4 "$PLUGINSDIR\error.txt" r
    ${IfNot} ${Errors}
      FileRead $4 $0 900
      FileClose $4
      Call TrimCRLF
    ${EndIf}
  ${EndIf}
FunctionEnd
Function WriteHelperScript
  ClearErrors
  FileOpen $0 "$PLUGINSDIR\setup.ps1" w
  ${If} ${Errors}
    Abort
  ${EndIf}
  FileWrite $0 'param([string]$$Mode, [string]$$Source, [string]$$Target, [string]$$ErrFile)$\r$\n'
  FileWrite $0 '$$ErrorActionPreference = "Stop"$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Set-InstallBar([int]$$percent, [string]$$caption) {$\r$\n'
  FileWrite $0 '  if ($$script:BarFailed) { return }$\r$\n'
  FileWrite $0 '  try {$\r$\n'
  FileWrite $0 '    if (-not ("NsisUi" -as [type])) {$\r$\n'
  FileWrite $0 "      Add-Type -TypeDefinition @'$\r$\n"
  FileWrite $0 'using System;$\r$\n'
  FileWrite $0 'using System.Text;$\r$\n'
  FileWrite $0 'using System.Threading;$\r$\n'
  FileWrite $0 'using System.Runtime.InteropServices;$\r$\n'
  FileWrite $0 'public static class NsisUi {$\r$\n'
  FileWrite $0 '  delegate bool EnumProc(IntPtr h, IntPtr l);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll")] static extern IntPtr FindWindowEx(IntPtr p, IntPtr a, string c, string t);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll")] static extern IntPtr GetDlgItem(IntPtr d, int id);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll", EntryPoint="SendMessageW")] static extern IntPtr SendPtr(IntPtr h, int m, IntPtr w, IntPtr l);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll", EntryPoint="SendMessageW", CharSet=CharSet.Unicode)] static extern IntPtr SendStr(IntPtr h, int m, IntPtr w, string s);$\r$\n'
  FileWrite $0 '  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);$\r$\n'
  FileWrite $0 '  static IntPtr bar, label;$\r$\n'
  FileWrite $0 '  static int pct, range;$\r$\n'
  FileWrite $0 '  static string cap = "", title;$\r$\n'
  FileWrite $0 '  static Timer clock;$\r$\n'
  FileWrite $0 '  static IntPtr BarFrom(IntPtr root) {$\r$\n'
  FileWrite $0 '    if (root == IntPtr.Zero) return IntPtr.Zero;$\r$\n'
  FileWrite $0 '    IntPtr dlg = FindWindowEx(root, IntPtr.Zero, "#32770", null);$\r$\n'
  FileWrite $0 '    IntPtr b = GetDlgItem(dlg, 1004);$\r$\n'
  FileWrite $0 '    if (b != IntPtr.Zero) label = GetDlgItem(dlg, 1006);$\r$\n'
  FileWrite $0 '    return b;$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  static void Locate(IntPtr owner) {$\r$\n'
  FileWrite $0 '    bar = BarFrom(owner);$\r$\n'
  FileWrite $0 '    if (bar != IntPtr.Zero || string.IsNullOrEmpty(title)) return;$\r$\n'
  FileWrite $0 '    EnumWindows((h, l) => {$\r$\n'
  FileWrite $0 '      var s = new StringBuilder(180);$\r$\n'
  FileWrite $0 '      GetWindowText(h, s, 180);$\r$\n'
  FileWrite $0 '      if (!s.ToString().StartsWith(title)) return true;$\r$\n'
  FileWrite $0 '      IntPtr b = BarFrom(h);$\r$\n'
  FileWrite $0 '      if (b == IntPtr.Zero) return true;$\r$\n'
  FileWrite $0 '      bar = b;$\r$\n'
  FileWrite $0 '      return false;$\r$\n'
  FileWrite $0 '    }, IntPtr.Zero);$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  static void Tick(object state) {$\r$\n'
  FileWrite $0 '    try {$\r$\n'
  FileWrite $0 '      if (bar == IntPtr.Zero) Locate((IntPtr)state);$\r$\n'
  FileWrite $0 '      if (bar == IntPtr.Zero) return;$\r$\n'
  FileWrite $0 '      if (range < 1) {$\r$\n'
  FileWrite $0 '        int high = (int)SendPtr(bar, 1031, IntPtr.Zero, IntPtr.Zero);$\r$\n'
  FileWrite $0 '        range = high < 1 ? 30000 : high;$\r$\n'
  FileWrite $0 '      }$\r$\n'
  FileWrite $0 '      SendPtr(bar, 1026, (IntPtr)(range * pct / 100), IntPtr.Zero);$\r$\n'
  FileWrite $0 '      if (label != IntPtr.Zero && cap.Length > 0) SendStr(label, 12, IntPtr.Zero, cap);$\r$\n'
  FileWrite $0 '    } catch {} $\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  public static void Watch(IntPtr owner, string windowTitle) {$\r$\n'
  FileWrite $0 '    title = windowTitle ?? "";$\r$\n'
  FileWrite $0 '    if (clock == null) clock = new Timer(Tick, owner, 0, 100);$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  public static void Set(int percent, string caption) {$\r$\n'
  FileWrite $0 '    if (percent < 0) percent = 0;$\r$\n'
  FileWrite $0 '    if (percent > 100) percent = 100;$\r$\n'
  FileWrite $0 '    pct = percent;$\r$\n'
  FileWrite $0 '    if (!string.IsNullOrEmpty(caption)) cap = caption;$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 "'@$\r$\n"
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    if (-not $$script:NsisWatch) {$\r$\n'
  FileWrite $0 '      $$owner = [IntPtr]::Zero$\r$\n'
  FileWrite $0 '      if ($$env:NSIS_HWND) { $$owner = New-Object IntPtr ([int64]([int][uint32]$$env:NSIS_HWND)) }$\r$\n'
  FileWrite $0 '      [NsisUi]::Watch($$owner, "Davinci Resolve Studio v${RESOLVE_VERSION}.10 Setup")$\r$\n'
  FileWrite $0 '      $$script:NsisWatch = $$true$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    [NsisUi]::Set($$percent, $$caption)$\r$\n'
  FileWrite $0 '  } catch { $$script:BarFailed = $$true }$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Enable-BmdTls {$\r$\n'
  FileWrite $0 '  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12$\r$\n'
  FileWrite $0 "  Add-Type -TypeDefinition @'$\r$\n"
  FileWrite $0 'using System;$\r$\n'
  FileWrite $0 'using System.Net;$\r$\n'
  FileWrite $0 'using System.Net.Security;$\r$\n'
  FileWrite $0 'using System.Security.Cryptography.X509Certificates;$\r$\n'
  FileWrite $0 'public static class BmdTrust$\r$\n'
  FileWrite $0 '{$\r$\n'
  FileWrite $0 '  private const string PinnedRoot = "DF3C24F9BFD666761B268073FE06D1CC8D4F82A4";$\r$\n'
  FileWrite $0 '  private const string DigiCertGlobalRootG2 =$\r$\n'
  FileWrite $0 '    "MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBhMQswCQYDVQQG" +$\r$\n'
  FileWrite $0 '    "EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAw" +$\r$\n'
  FileWrite $0 '    "HgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUx" +$\r$\n'
  FileWrite $0 '    "MjAwMDBaMGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3" +$\r$\n'
  FileWrite $0 '    "dy5kaWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkq" +$\r$\n'
  FileWrite $0 '    "hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI2/Ou8jqJ" +$\r$\n'
  FileWrite $0 '    "kTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx1x7e/dfgy5SDN67sH0NO" +$\r$\n'
  FileWrite $0 '    "3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQq2EGnI/yuum06ZIya7XzV+hdG82MHauV" +$\r$\n'
  FileWrite $0 '    "BJVJ8zUtluNJbd134/tJS7SsVQepj5WztCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyM" +$\r$\n'
  FileWrite $0 '    "UNGPHgm+F6HmIcr9g+UQvIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQAB" +$\r$\n'
  FileWrite $0 '    "o0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV5uNu" +$\r$\n'
  FileWrite $0 '    "5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY1Yl9PMWLSn/pvtsr" +$\r$\n'
  FileWrite $0 '    "F9+wX3N3KjITOYFnQoQj8kVnNeyIv/iPsGEMNKSuIEyExtv4NeF22d+mQrvHRAiGfzZ0JFrabA0U" +$\r$\n'
  FileWrite $0 '    "WTW98kndth/Jsw1HKj2ZL7tcu7XUIOGZX1NGFdtom/DzMNU+MeKNhJ7jitralj41E6Vf8PlwUHBH" +$\r$\n'
  FileWrite $0 '    "QRFXGU7Aj64GxJUTFy8bJZ918rGOmaFvE7FBcf6IKshPECBV1/MUReXgRPTqh5Uykw7+U0b6LJ3/" +$\r$\n'
  FileWrite $0 '    "iyK5S9kJRaTepLiaWN0bfVKfjllDiIGknibVb63dDcY3fe0Dkhvld1927jyNxF1WW6LZZm6zNTfl" +$\r$\n'
  FileWrite $0 '    "MrY=";$\r$\n'
  FileWrite $0 '  private const string DigiCertGlobalG2TlsCa =$\r$\n'
  FileWrite $0 '    "MIIEyDCCA7CgAwIBAgIQDPW9BitWAvR6uFAsI8zwZjANBgkqhkiG9w0BAQsFADBhMQswCQYDVQQG" +$\r$\n'
  FileWrite $0 '    "EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAw" +$\r$\n'
  FileWrite $0 '    "HgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMjAeFw0yMTAzMzAwMDAwMDBaFw0zMTAzMjky" +$\r$\n'
  FileWrite $0 '    "MzU5NTlaMFkxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxMzAxBgNVBAMTKkRp" +$\r$\n'
  FileWrite $0 '    "Z2lDZXJ0IEdsb2JhbCBHMiBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTCCASIwDQYJKoZIhvcNAQEB" +$\r$\n'
  FileWrite $0 '    "BQADggEPADCCAQoCggEBAMz3EGJPprtjb+2QUlbFbSd7ehJWivH0+dbn4Y+9lavyYEEVcNsSAPon" +$\r$\n'
  FileWrite $0 '    "CrVXOFt9slGTcZUOakGUWzUb+nv6u8W+JDD+Vu/E832X4xT1FE3LpxDyFuqrIvAxIhFhaZAmunjZ" +$\r$\n'
  FileWrite $0 '    "lx/jfWardUSVc8is/+9dCopZQ+GssjoP80j812s3wWPc3kbW20X+fSP9kOhRBx5Ro1/tSUZUfyyI" +$\r$\n'
  FileWrite $0 '    "xfQTnJcVPAPooTncaQwywa8WV0yUR0J8osicfebUTVSvQpmowQTCd5zWSOTOEeAqgJnwQ3DPP3Zr" +$\r$\n'
  FileWrite $0 '    "0UxJqyRewg2C/Uaoq2yTzGJSQnWS+Jr6Xl6ysGHlHx+5fwmY6D36g39HaaECAwEAAaOCAYIwggF+" +$\r$\n'
  FileWrite $0 '    "MBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFHSFgMBmx9833s+9KTeqAx2+7c0XMB8GA1Ud" +$\r$\n'
  FileWrite $0 '    "IwQYMBaAFE4iVCAYlebjbuYP+vq5Eu0GF485MA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggr" +$\r$\n'
  FileWrite $0 '    "BgEFBQcDAQYIKwYBBQUHAwIwdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz" +$\r$\n'
  FileWrite $0 '    "cC5kaWdpY2VydC5jb20wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E" +$\r$\n'
  FileWrite $0 '    "aWdpQ2VydEdsb2JhbFJvb3RHMi5jcnQwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybDMuZGln" +$\r$\n'
  FileWrite $0 '    "aWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdEcyLmNybDA9BgNVHSAENjA0MAsGCWCGSAGG/WwC" +$\r$\n'
  FileWrite $0 '    "ATAHBgVngQwBATAIBgZngQwBAgEwCAYGZ4EMAQICMAgGBmeBDAECAzANBgkqhkiG9w0BAQsFAAOC" +$\r$\n'
  FileWrite $0 '    "AQEAkPFwyyiXaZd8dP3A+iZ7U6utzWX9upwGnIrXWkOH7U1MVl+twcW1BSAuWdH/SvWgKtiwla3J" +$\r$\n'
  FileWrite $0 '    "Lko716f2b4gp/DA/JIS7w7d7kwcsr4drdjPtAFVSslme5LnQ89/nD/7d+MS5EHKBCQRfz5eeLjJ1" +$\r$\n'
  FileWrite $0 '    "js+aWNJXMX43AYGyZm0pGrFmCW3RbpD0ufovARTFXFZkAdl9h6g4U5+LXUZtXMYnhIHUfoyMo5tS" +$\r$\n'
  FileWrite $0 '    "58aI7Dd8KvvwVVo4chDYABPPTHPbqjc1qCmBaZx2vN4Ye5DUys/vZwP9BFohFrH/6j/f3IL16/RZ" +$\r$\n'
  FileWrite $0 '    "kiMNJCqVJUzKoZHm1Lesh3Sz8W2jmdv51b2EQJ8HmA==";$\r$\n'
  FileWrite $0 '  private static readonly X509Certificate2Collection Embedded = new X509Certificate2Collection();$\r$\n'
  FileWrite $0 '  public static string LastFailure = "";$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 '  public static void Install()$\r$\n'
  FileWrite $0 '  {$\r$\n'
  FileWrite $0 '    Embedded.Add(new X509Certificate2(Convert.FromBase64String(DigiCertGlobalRootG2)));$\r$\n'
  FileWrite $0 '    Embedded.Add(new X509Certificate2(Convert.FromBase64String(DigiCertGlobalG2TlsCa)));$\r$\n'
  FileWrite $0 '    ServicePointManager.ServerCertificateValidationCallback = Validate;$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 '  private static bool Validate(object sender, X509Certificate certificate, X509Chain systemChain, SslPolicyErrors errors)$\r$\n'
  FileWrite $0 '  {$\r$\n'
  FileWrite $0 '    if (errors == SslPolicyErrors.None)$\r$\n'
  FileWrite $0 '      return true;$\r$\n'
  FileWrite $0 '    if (certificate == null || (errors & ~SslPolicyErrors.RemoteCertificateChainErrors) != SslPolicyErrors.None)$\r$\n'
  FileWrite $0 '    {$\r$\n'
  FileWrite $0 '      LastFailure = errors.ToString();$\r$\n'
  FileWrite $0 '      return false;$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 '    X509Chain chain = new X509Chain();$\r$\n'
  FileWrite $0 '    chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;$\r$\n'
  FileWrite $0 '    chain.ChainPolicy.VerificationFlags = X509VerificationFlags.AllowUnknownCertificateAuthority;$\r$\n'
  FileWrite $0 '    chain.ChainPolicy.ExtraStore.AddRange(Embedded);$\r$\n'
  FileWrite $0 '    if (systemChain != null)$\r$\n'
  FileWrite $0 '    {$\r$\n'
  FileWrite $0 '      foreach (X509ChainElement element in systemChain.ChainElements)$\r$\n'
  FileWrite $0 '        chain.ChainPolicy.ExtraStore.Add(element.Certificate);$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    chain.Build(new X509Certificate2(certificate));$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 '    X509Certificate2 top = chain.ChainElements[chain.ChainElements.Count - 1].Certificate;$\r$\n'
  FileWrite $0 '    if (!string.Equals(top.Thumbprint, PinnedRoot, StringComparison.OrdinalIgnoreCase))$\r$\n'
  FileWrite $0 '    {$\r$\n'
  FileWrite $0 '      LastFailure = "unexpected issuer: " + top.Subject;$\r$\n'
  FileWrite $0 '      return false;$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    foreach (X509ChainStatus status in chain.ChainStatus)$\r$\n'
  FileWrite $0 '    {$\r$\n'
  FileWrite $0 '      if (status.Status != X509ChainStatusFlags.NoError && status.Status != X509ChainStatusFlags.UntrustedRoot)$\r$\n'
  FileWrite $0 '      {$\r$\n'
  FileWrite $0 '        LastFailure = status.Status + ": " + status.StatusInformation.Trim();$\r$\n'
  FileWrite $0 '        return false;$\r$\n'
  FileWrite $0 '      }$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    return true;$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 "'@$\r$\n"
  FileWrite $0 '  [BmdTrust]::Install()$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Invoke-Api {$\r$\n'
  FileWrite $0 `  $$body = '{"firstname":"${REG_FIRSTNAME}","lastname":"${REG_LASTNAME}","email":"${REG_EMAIL}","phone":"${REG_PHONE}","country":"${REG_COUNTRY}","state":"${REG_STATE}","city":"${REG_CITY}","product":"${REG_PRODUCT}"}'$\r$\n`
  FileWrite $0 '  $$response = Invoke-WebRequest -Uri $$Source -Method Post -Body $$body -ContentType "application/json;charset=UTF-8" -UseBasicParsing -TimeoutSec 90$\r$\n'
  FileWrite $0 '  $$url = ([string]$$response.Content).Trim()$\r$\n'
  FileWrite $0 '  $$idx = $$url.IndexOf("https://")$\r$\n'
  FileWrite $0 '  if ($$idx -ge 0) { $$url = $$url.Substring($$idx).Split([char]34)[0].Split([char]32)[0].TrimEnd([char]44).TrimEnd([char]125) }$\r$\n'
  FileWrite $0 '  $$uri = [Uri]$$url$\r$\n'
  FileWrite $0 '  if ($$uri.Host -notmatch "(^|\.)blackmagicdesign\.com$$") { throw "Unexpected download host: $$url" }$\r$\n'
  FileWrite $0 '  [IO.File]::WriteAllText($$Target, $$uri.AbsoluteUri)$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Invoke-Download {$\r$\n'
  FileWrite $0 '  $$existing = 0L$\r$\n'
  FileWrite $0 '  if (Test-Path -LiteralPath $$Target) { $$existing = [IO.FileInfo]::new($$Target).Length }$\r$\n'
  FileWrite $0 '  $$request = [Net.HttpWebRequest]::Create($$Source)$\r$\n'
  FileWrite $0 '  $$request.AllowAutoRedirect = $$true$\r$\n'
  FileWrite $0 '  $$request.AllowWriteStreamBuffering = $$false$\r$\n'
  FileWrite $0 '  $$request.AutomaticDecompression = [Net.DecompressionMethods]::None$\r$\n'
  FileWrite $0 '  $$request.Timeout = 60000$\r$\n'
  FileWrite $0 '  $$request.ReadWriteTimeout = 300000$\r$\n'
  FileWrite $0 '  $$request.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"$\r$\n'
  FileWrite $0 '  if ($$existing -gt 0) { [void]$$request.AddRange($$existing) }$\r$\n'
  FileWrite $0 '  try {$\r$\n'
  FileWrite $0 '    $$response = $$request.GetResponse()$\r$\n'
  FileWrite $0 '  } catch [Net.WebException] {$\r$\n'
  FileWrite $0 '    $$web = $$_.Exception.Response$\r$\n'
  FileWrite $0 '    if ($$web -and [int]$$web.StatusCode -eq 416) {$\r$\n'
  FileWrite $0 '      $$web.Close()$\r$\n'
  FileWrite $0 '      if ($$existing -ge 500MB) { Set-InstallBar 100; Write-Output "Already complete"; return }$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    throw$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  $$status = [int]$$response.StatusCode$\r$\n'
  FileWrite $0 '  $$start = 0L$\r$\n'
  FileWrite $0 '  $$total = [int64]$$response.ContentLength$\r$\n'
  FileWrite $0 '  if ($$status -eq 206) {$\r$\n'
  FileWrite $0 '    $$cr = $$response.Headers["Content-Range"]$\r$\n'
  FileWrite $0 '    if ($$cr -match "bytes (\d+)-(\d+)/(\d+)") {$\r$\n'
  FileWrite $0 '      $$start = [int64]$$Matches[1]$\r$\n'
  FileWrite $0 '      $$total = [int64]$$Matches[3]$\r$\n'
  FileWrite $0 '    } else {$\r$\n'
  FileWrite $0 '      $$start = $$existing$\r$\n'
  FileWrite $0 '      $$total = $$existing + $$total$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '  } else {$\r$\n'
  FileWrite $0 '    $$start = 0L$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  if ($$start -eq 0 -and $$existing -eq $$total -and $$total -gt 0) {$\r$\n'
  FileWrite $0 '    $$response.Close()$\r$\n'
  FileWrite $0 '    Set-InstallBar 100$\r$\n'
  FileWrite $0 '    Write-Output ("Already complete: {0:N2} GB" -f ($$total / 1GB))$\r$\n'
  FileWrite $0 '    return$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  if ($$start -gt 0 -and $$total -ge 1GB) { Write-Output ("Resuming from {0:N2} / {1:N2} GB" -f ($$start / 1GB), ($$total / 1GB)) }$\r$\n'
  FileWrite $0 '  elseif ($$start -gt 0) { Write-Output ("Resuming from {0:N1} / {1:N1} MB" -f ($$start / 1MB), ($$total / 1MB)) }$\r$\n'
  FileWrite $0 '  elseif ($$total -ge 1GB) { Write-Output ("Downloading {0:N2} GB" -f ($$total / 1GB)) }$\r$\n'
  FileWrite $0 '  elseif ($$total -gt 0) { Write-Output ("Downloading {0:N1} MB" -f ($$total / 1MB)) }$\r$\n'
  FileWrite $0 '  $$mode = if ($$start -gt 0) { [IO.FileMode]::Append } else { [IO.FileMode]::Create }$\r$\n'
  FileWrite $0 '  $$inStream = $$response.GetResponseStream()$\r$\n'
  FileWrite $0 '  $$outStream = [IO.File]::Open($$Target, $$mode, [IO.FileAccess]::Write, [IO.FileShare]::Read)$\r$\n'
  FileWrite $0 '  if ($$start -gt 0) { $$outStream.Seek($$start, [IO.SeekOrigin]::Begin) | Out-Null }$\r$\n'
  FileWrite $0 '  try {$\r$\n'
  FileWrite $0 '    $$buffer = New-Object byte[] 1048576$\r$\n'
  FileWrite $0 '    $$done = $$start$\r$\n'
  FileWrite $0 '    $$reported = -1$\r$\n'
  FileWrite $0 '    $$sw = [Diagnostics.Stopwatch]::StartNew()$\r$\n'
  FileWrite $0 '    $$lastTick = 0L$\r$\n'
  FileWrite $0 '    while (($$read = $$inStream.Read($$buffer, 0, $$buffer.Length)) -gt 0) {$\r$\n'
  FileWrite $0 '      $$outStream.Write($$buffer, 0, $$read)$\r$\n'
  FileWrite $0 '      $$done += $$read$\r$\n'
  FileWrite $0 '      $$elapsed = [Math]::Max($$sw.Elapsed.TotalSeconds, 0.001)$\r$\n'
  FileWrite $0 '      $$percent = if ($$total -gt 0) { [int][Math]::Floor(100.0 * $$done / $$total) } else { 0 }$\r$\n'
  FileWrite $0 '      $$caption = $$null$\r$\n'
  FileWrite $0 '      if ($$percent -ne $$reported -or ($$sw.ElapsedMilliseconds - $$lastTick) -ge 10000) {$\r$\n'
  FileWrite $0 '        $$reported = $$percent$\r$\n'
  FileWrite $0 '        $$lastTick = $$sw.ElapsedMilliseconds$\r$\n'
  FileWrite $0 '        $$speed = (($$done - $$start) / $$elapsed) / 1MB$\r$\n'
  FileWrite $0 '        if ($$total -ge 1GB) { $$caption = "{0,3}%  {1:N2} / {2:N2} GB  {3:N1} MB/s" -f $$percent, ($$done / 1GB), ($$total / 1GB), $$speed }$\r$\n'
  FileWrite $0 '        else { $$caption = "{0,3}%  {1:N1} / {2:N1} MB  {3:N1} MB/s" -f $$percent, ($$done / 1MB), ($$total / 1MB), $$speed }$\r$\n'
  FileWrite $0 '        Write-Output $$caption$\r$\n'
  FileWrite $0 '      }$\r$\n'
  FileWrite $0 '      Set-InstallBar $$percent $$caption$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  finally {$\r$\n'
  FileWrite $0 '    $$outStream.Dispose()$\r$\n'
  FileWrite $0 '    $$inStream.Dispose()$\r$\n'
  FileWrite $0 '    $$response.Close()$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  if ($$total -gt 0 -and $$done -ne $$total) { throw "Incomplete download: $$done of $$total bytes" }$\r$\n'
  FileWrite $0 '  Set-InstallBar 100$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Expand-Payload {$\r$\n'
  FileWrite $0 '  Add-Type -AssemblyName System.IO.Compression.FileSystem$\r$\n'
  FileWrite $0 '  New-Item -ItemType Directory -Force -Path $$Target | Out-Null$\r$\n'
  FileWrite $0 '  $$root = [IO.Path]::GetFullPath($$Target)$\r$\n'
  FileWrite $0 '  if (-not $$root.EndsWith([IO.Path]::DirectorySeparatorChar.ToString())) { $$root += [IO.Path]::DirectorySeparatorChar }$\r$\n'
  FileWrite $0 '  $$zip = [IO.Compression.ZipFile]::OpenRead($$Source)$\r$\n'
  FileWrite $0 '  try {$\r$\n'
  FileWrite $0 '    $$bytesTotal = 0L$\r$\n'
  FileWrite $0 '    foreach ($$entry in $$zip.Entries) { if ($$entry.Name) { $$bytesTotal += $$entry.Length } }$\r$\n'
  FileWrite $0 '    $$bytesDone = 0L$\r$\n'
  FileWrite $0 '    $$reported = -1$\r$\n'
  FileWrite $0 '    foreach ($$entry in $$zip.Entries) {$\r$\n'
  FileWrite $0 '      if ([string]::IsNullOrEmpty($$entry.Name)) { continue }$\r$\n'
  FileWrite $0 '      $$dest = [IO.Path]::GetFullPath([IO.Path]::Combine($$Target, $$entry.FullName.Replace([char]47, [IO.Path]::DirectorySeparatorChar)))$\r$\n'
  FileWrite $0 '      if (-not $$dest.StartsWith($$root, [StringComparison]::OrdinalIgnoreCase)) { throw ("Bad zip path: " + $$entry.FullName) }$\r$\n'
  FileWrite $0 '      $$dir = [IO.Path]::GetDirectoryName($$dest)$\r$\n'
  FileWrite $0 '      if (-not [IO.Directory]::Exists($$dir)) { [IO.Directory]::CreateDirectory($$dir) | Out-Null }$\r$\n'
  FileWrite $0 '      $$zin = $$entry.Open()$\r$\n'
  FileWrite $0 '      $$zout = [IO.File]::Open($$dest, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::Read)$\r$\n'
  FileWrite $0 '      try {$\r$\n'
  FileWrite $0 '        $$buf = New-Object byte[] 1048576$\r$\n'
  FileWrite $0 '        while (($$n = $$zin.Read($$buf, 0, $$buf.Length)) -gt 0) {$\r$\n'
  FileWrite $0 '          $$zout.Write($$buf, 0, $$n)$\r$\n'
  FileWrite $0 '          $$bytesDone += $$n$\r$\n'
  FileWrite $0 '          $$percent = if ($$bytesTotal -gt 0) { [int][Math]::Floor(100.0 * $$bytesDone / $$bytesTotal) } else { 0 }$\r$\n'
  FileWrite $0 '          if ($$percent -ne $$reported) { $$reported = $$percent; Set-InstallBar $$percent ("Extracting {0}%" -f $$percent) }$\r$\n'
  FileWrite $0 '        }$\r$\n'
  FileWrite $0 '      } finally { $$zout.Dispose(); $$zin.Dispose() }$\r$\n'
  FileWrite $0 '      Write-Output $$entry.FullName$\r$\n'
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '    Set-InstallBar 100$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  finally {$\r$\n'
  FileWrite $0 '    $$zip.Dispose()$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'function Test-Payload {$\r$\n'
  FileWrite $0 '  $$len = [IO.FileInfo]::new($$Source).Length$\r$\n'
  FileWrite $0 '  Write-Output ("Payload size: {0:N0} bytes" -f $$len)$\r$\n'
  FileWrite $0 '  if ($$len -lt 500MB) { throw "Payload too small: $$len bytes" }$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 '$\r$\n'
  FileWrite $0 'try {$\r$\n'
  FileWrite $0 '  switch ($$Mode) {$\r$\n'
  FileWrite $0 '    "api"      { Enable-BmdTls; Invoke-Api }$\r$\n'
  FileWrite $0 '    "download" { Enable-BmdTls; Invoke-Download }$\r$\n'
  FileWrite $0 '    "checksize" { Test-Payload }$\r$\n'
  FileWrite $0 '    "extract"  { Expand-Payload }$\r$\n'
  FileWrite $0 '    default    { throw "Unknown mode: $$Mode" }$\r$\n'
  FileWrite $0 '  }$\r$\n'
  FileWrite $0 '  exit 0$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileWrite $0 'catch {$\r$\n'
  FileWrite $0 '  $$message = $$_.Exception.Message$\r$\n'
  FileWrite $0 '  if (("BmdTrust" -as [type]) -and [BmdTrust]::LastFailure) { $$message += " [" + [BmdTrust]::LastFailure + "]" }$\r$\n'
  FileWrite $0 '  [IO.File]::WriteAllText($$ErrFile, $$message, [Text.Encoding]::Default)$\r$\n'
  FileWrite $0 '  exit 1$\r$\n'
  FileWrite $0 '}$\r$\n'
  FileClose $0
FunctionEnd
Function TrimCRLF
  ${Do}
    StrCpy $1 $0 1 -1
    ${If} $1 == "$\r"
    ${OrIf} $1 == "$\n"
      StrCpy $0 $0 -1
    ${Else}
      ${Break}
    ${EndIf}
  ${Loop}
FunctionEnd
Function .onInit
  StrCpy $SetupDir "$TEMP\DaVinciResolveSetup"
  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}
  UserInfo::GetAccountType
  Pop $0
  ${If} $0 != "Admin"
    ${IfNot} ${Silent}
      MessageBox MB_OK|MB_ICONSTOP "$(TXT_ADMIN)" /SD IDOK
    ${EndIf}
    Abort
  ${EndIf}
  ${GetRoot} "$SetupDir" $1
  StrCpy $1 "$1\"
  ${DriveSpace} "$1" "/D=F /S=M" $0
  ${If} $0 < 22000
    MessageBox MB_OK|MB_ICONSTOP "$(TXT_DISK_LOW)" /SD IDOK
    Abort
  ${ElseIf} $0 < 33000
    ${IfNot} ${Silent}
      MessageBox MB_YESNO|MB_ICONEXCLAMATION|MB_DEFBUTTON2 "$(TXT_DISK_WARN)" /SD IDNO IDYES +2
      Abort
    ${EndIf}
  ${EndIf}
FunctionEnd
