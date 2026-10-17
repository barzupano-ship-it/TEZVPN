#include "vpn_win.h"

#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shellapi.h>
#include <tlhelp32.h>
#include <netioapi.h>
#include <iphlpapi.h>

#include <string>

namespace {

constexpr wchar_t kTunnelName[] = L"TEZVPN";
constexpr wchar_t kServiceName[] = L"AmneziaWGTunnel$TEZVPN";

std::wstring ProgramDataDir() {
  wchar_t buf[MAX_PATH];
  DWORD n = GetEnvironmentVariableW(L"ProgramData", buf, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) {
    return L"C:\\ProgramData\\TEZVPN";
  }
  return std::wstring(buf) + L"\\TEZVPN";
}

std::wstring ResultPath() { return ProgramDataDir() + L"\\result.txt"; }

std::wstring ExePath() {
  wchar_t buf[MAX_PATH];
  DWORD n = GetModuleFileNameW(nullptr, buf, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) {
    return L"";
  }
  return std::wstring(buf, n);
}

std::wstring DirOf(const std::wstring& path) {
  const auto slash = path.find_last_of(L"\\/");
  if (slash == std::wstring::npos) {
    return L"";
  }
  return path.substr(0, slash);
}

bool EnsureDir(const std::wstring& dir) {
  if (CreateDirectoryW(dir.c_str(), nullptr)) {
    return true;
  }
  return GetLastError() == ERROR_ALREADY_EXISTS;
}

void WriteResult(const std::string& text) {
  const std::wstring path = ResultPath();
  HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ,
                            nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL,
                            nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  DWORD written = 0;
  WriteFile(file, text.data(), static_cast<DWORD>(text.size()), &written,
            nullptr);
  CloseHandle(file);
}

std::string ReadResult() {
  const std::wstring path = ResultPath();
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                            nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                            nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return "";
  }
  char buf[1024];
  DWORD read = 0;
  std::string out;
  while (ReadFile(file, buf, sizeof(buf), &read, nullptr) && read > 0) {
    out.append(buf, buf + read);
  }
  CloseHandle(file);
  return out;
}

bool WriteUtf8(const std::wstring& path, const std::string& text) {
  HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
                            CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }
  DWORD written = 0;
  const BOOL ok =
      WriteFile(file, text.data(), static_cast<DWORD>(text.size()), &written,
                nullptr);
  CloseHandle(file);
  return ok && written == text.size();
}

bool IsAdmin() {
  BOOL admin = FALSE;
  SID_IDENTIFIER_AUTHORITY nt = SECURITY_NT_AUTHORITY;
  PSID sid = nullptr;
  if (!AllocateAndInitializeSid(&nt, 2, SECURITY_BUILTIN_DOMAIN_RID,
                                DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                                &sid)) {
    return false;
  }
  CheckTokenMembership(nullptr, sid, &admin);
  FreeSid(sid);
  return admin == TRUE;
}

DWORD RunHidden(const std::wstring& command, const std::wstring& work_dir) {
  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;
  PROCESS_INFORMATION pi;
  ZeroMemory(&pi, sizeof(pi));
  std::wstring mutable_cmd = command;
  if (!CreateProcessW(nullptr, mutable_cmd.data(), nullptr, nullptr, FALSE,
                      CREATE_NO_WINDOW, nullptr,
                      work_dir.empty() ? nullptr : work_dir.c_str(), &si,
                      &pi)) {
    return GetLastError();
  }
  WaitForSingleObject(pi.hProcess, 90000);
  DWORD code = 1;
  GetExitCodeProcess(pi.hProcess, &code);
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  return code;
}

bool CopyEngineTo(const std::wstring& dest) {
  const std::wstring source = DirOf(ExePath()) + L"\\engine";
  if (!EnsureDir(dest)) {
    return false;
  }
  const wchar_t* names[] = {L"amneziawg.exe", L"awg.exe", L"wintun.dll"};
  for (const wchar_t* name : names) {
    const std::wstring from = source + L"\\" + name;
    const std::wstring to = dest + L"\\" + name;
    if (!CopyFileW(from.c_str(), to.c_str(), FALSE)) {
      // The tunnel may already be running and holding this file.
      if (GetFileAttributesW(to.c_str()) == INVALID_FILE_ATTRIBUTES) {
        return false;
      }
    }
  }
  return true;
}

void RenameService() {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    return;
  }
  SC_HANDLE svc =
      OpenServiceW(scm, kServiceName, SERVICE_CHANGE_CONFIG | SERVICE_QUERY_STATUS);
  if (!svc) {
    CloseServiceHandle(scm);
    return;
  }
  ChangeServiceConfigW(svc, SERVICE_NO_CHANGE, SERVICE_NO_CHANGE,
                       SERVICE_NO_CHANGE, nullptr, nullptr, nullptr, nullptr,
                       nullptr, nullptr, L"SULTAN VPN");
  SERVICE_DESCRIPTIONW desc;
  desc.lpDescription = const_cast<LPWSTR>(L"SULTAN VPN");
  ChangeServiceConfig2W(svc, SERVICE_CONFIG_DESCRIPTION, &desc);
  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
}

std::wstring EngineExe(const std::wstring& engine_dir) {
  return engine_dir + L"\\amneziawg.exe";
}

bool TunnelServiceExists() {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    return false;
  }
  SC_HANDLE svc = OpenServiceW(scm, kServiceName, SERVICE_QUERY_STATUS);
  const bool exists = svc != nullptr;
  if (svc) {
    CloseServiceHandle(svc);
  }
  CloseServiceHandle(scm);
  return exists;
}

bool StopTunnelService() {
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    return false;
  }
  SC_HANDLE svc = OpenServiceW(scm, kServiceName, SERVICE_STOP | SERVICE_QUERY_STATUS);
  if (!svc) {
    const DWORD missing = GetLastError();
    CloseServiceHandle(scm);
    return missing == ERROR_SERVICE_DOES_NOT_EXIST;
  }
  const DWORD began = GetTickCount();
  bool stopped = false;
  while (GetTickCount() - began < 15000) {
    SERVICE_STATUS_PROCESS status;
    DWORD bytes = 0;
    ZeroMemory(&status, sizeof(status));
    if (!QueryServiceStatusEx(svc, SC_STATUS_PROCESS_INFO,
                              reinterpret_cast<LPBYTE>(&status), sizeof(status),
                              &bytes)) {
      break;
    }
    if (status.dwCurrentState == SERVICE_STOPPED) {
      stopped = true;
      break;
    }
    if (status.dwCurrentState != SERVICE_STOP_PENDING &&
        status.dwCurrentState != SERVICE_START_PENDING) {
      SERVICE_STATUS ignored;
      ZeroMemory(&ignored, sizeof(ignored));
      ControlService(svc, SERVICE_CONTROL_STOP, &ignored);
    }
    Sleep(200);
  }
  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
  return stopped;
}

bool ProcessRunning(const wchar_t* name) {
  HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snap == INVALID_HANDLE_VALUE) {
    return false;
  }
  PROCESSENTRY32W entry;
  entry.dwSize = sizeof(entry);
  bool found = false;
  if (Process32FirstW(snap, &entry)) {
    do {
      if (_wcsicmp(entry.szExeFile, name) == 0) {
        found = true;
        break;
      }
    } while (Process32NextW(snap, &entry));
  }
  CloseHandle(snap);
  return found;
}

void KillStack() {
  if (!ProcessRunning(L"sing-box.exe")) {
    return;
  }
  RunHidden(L"C:\\Windows\\System32\\taskkill.exe /F /IM sing-box.exe", L"");
  Sleep(400);
}

void WriteProto(const char* proto) {
  EnsureDir(ProgramDataDir());
  WriteUtf8(ProgramDataDir() + L"\\proto.txt", proto);
}

std::string ReadProto() {
  const std::wstring path = ProgramDataDir() + L"\\proto.txt";
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return "";
  }
  char buf[32];
  DWORD read = 0;
  std::string out;
  if (ReadFile(file, buf, sizeof(buf), &read, nullptr) && read > 0) {
    out.assign(buf, buf + read);
  }
  CloseHandle(file);
  while (!out.empty() && (out.back() == '\n' || out.back() == '\r' || out.back() == ' ')) {
    out.pop_back();
  }
  return out;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) {
    return "";
  }
  const int size = WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 1) {
    return "";
  }
  std::string out(static_cast<size_t>(size - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1, out.data(), size, nullptr, nullptr);
  return out;
}

std::string ReadWhole(const std::wstring& path) {
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return "";
  }
  std::string out;
  char buf[4096];
  DWORD read = 0;
  while (ReadFile(file, buf, sizeof(buf), &read, nullptr) && read > 0) {
    out.append(buf, buf + read);
  }
  CloseHandle(file);
  return out;
}

bool BadTunName(const std::wstring& name) {
  std::wstring lower = name;
  for (wchar_t& ch : lower) {
    ch = static_cast<wchar_t>(towlower(ch));
  }
  return lower.find(L"tez") != std::wstring::npos ||
         lower.find(L"wintun") != std::wstring::npos ||
         lower.find(L"sing-box") != std::wstring::npos ||
         lower.find(L"loopback") != std::wstring::npos;
}

std::string DefaultInterfaceUtf8() {
  PMIB_IPFORWARD_TABLE2 table = nullptr;
  if (GetIpForwardTable2(AF_INET, &table) != NO_ERROR || table == nullptr) {
    return "";
  }
  const MIB_IPFORWARD_ROW2* best = nullptr;
  for (ULONG i = 0; i < table->NumEntries; ++i) {
    const MIB_IPFORWARD_ROW2& row = table->Table[i];
    if (row.DestinationPrefix.Prefix.si_family != AF_INET) {
      continue;
    }
    if (row.DestinationPrefix.PrefixLength != 0) {
      continue;
    }
    WCHAR alias[IF_MAX_STRING_SIZE + 1];
    if (ConvertInterfaceLuidToAlias(const_cast<NET_LUID*>(&row.InterfaceLuid), alias,
                                    IF_MAX_STRING_SIZE + 1) != NO_ERROR) {
      continue;
    }
    if (BadTunName(alias)) {
      continue;
    }
    const bool hop = row.NextHop.Ipv4.sin_addr.S_un.S_addr != 0;
    const bool best_hop =
        best != nullptr && best->NextHop.Ipv4.sin_addr.S_un.S_addr != 0;
    if (best == nullptr || (hop && !best_hop) ||
        (hop == best_hop && row.Metric < best->Metric)) {
      best = &row;
    }
  }
  std::string name;
  if (best != nullptr) {
    WCHAR alias[IF_MAX_STRING_SIZE + 1];
    if (ConvertInterfaceLuidToAlias(const_cast<NET_LUID*>(&best->InterfaceLuid), alias,
                                    IF_MAX_STRING_SIZE + 1) == NO_ERROR) {
      name = WideToUtf8(alias);
    }
  }
  FreeMibTable(table);
  if (name.find('"') != std::string::npos || name.find('\\') != std::string::npos) {
    return "";
  }
  return name;
}

void ApplyInterface(const std::wstring& config) {
  std::string json = ReadWhole(config);
  const std::string iface = DefaultInterfaceUtf8();
  const std::string token = "TEZ_IFACE";
  if (iface.empty()) {
    const std::string drop1 = "\"default_interface\": \"TEZ_IFACE\",";
    const std::string drop2 = "\"bind_interface\": \"TEZ_IFACE\",";
    for (const std::string& drop : {drop1, drop2}) {
      const auto pos = json.find(drop);
      if (pos != std::string::npos) {
        json.erase(pos, drop.size());
      }
    }
  } else {
    for (auto pos = json.find(token); pos != std::string::npos; pos = json.find(token, pos)) {
      json.replace(pos, token.size(), iface);
      pos += iface.size();
    }
  }
  WriteUtf8(config, json);
}

bool StartStack(const std::wstring& engine, const std::wstring& config) {
  const std::wstring exe = engine + L"\\sing-box.exe";
  if (GetFileAttributesW(exe.c_str()) == INVALID_FILE_ATTRIBUTES) {
    return false;
  }
  ApplyInterface(config);
  const std::wstring log_path = ProgramDataDir() + L"\\stack.log";
  SECURITY_ATTRIBUTES sa;
  ZeroMemory(&sa, sizeof(sa));
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = TRUE;
  HANDLE log = CreateFileW(log_path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, &sa,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  HANDLE nul = CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ, &sa, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;
  if (log != INVALID_HANDLE_VALUE && nul != INVALID_HANDLE_VALUE) {
    si.dwFlags |= STARTF_USESTDHANDLES;
    si.hStdInput = nul;
    si.hStdOutput = log;
    si.hStdError = log;
  }
  PROCESS_INFORMATION pi;
  ZeroMemory(&pi, sizeof(pi));
  std::wstring cmd = L"\"" + exe + L"\" run -c \"" + config + L"\"";
  DWORD flags = CREATE_NO_WINDOW | CREATE_NEW_PROCESS_GROUP | CREATE_BREAKAWAY_FROM_JOB;
  if (!CreateProcessW(nullptr, cmd.data(), nullptr, nullptr,
                      log != INVALID_HANDLE_VALUE, flags, nullptr, engine.c_str(), &si,
                      &pi)) {
    flags = CREATE_NO_WINDOW | CREATE_NEW_PROCESS_GROUP;
    if (!CreateProcessW(nullptr, cmd.data(), nullptr, nullptr,
                        log != INVALID_HANDLE_VALUE, flags, nullptr, engine.c_str(), &si,
                        &pi)) {
      if (log != INVALID_HANDLE_VALUE) CloseHandle(log);
      if (nul != INVALID_HANDLE_VALUE) CloseHandle(nul);
      return false;
    }
  }
  if (log != INVALID_HANDLE_VALUE) CloseHandle(log);
  if (nul != INVALID_HANDLE_VALUE) CloseHandle(nul);
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  return true;
}

int InstallFromEngine(const std::wstring& engine_dir, const std::wstring& conf) {
  const std::wstring exe = EngineExe(engine_dir);
  const std::wstring uninstall =
      L"\"" + exe + L"\" /uninstalltunnelservice " + kTunnelName;
  // Stop first. amneziawg.exe shows "Tunnel already installed and running"
  // and refuses to install over a service that is still started.
  for (int attempt = 0; attempt < 6; ++attempt) {
    StopTunnelService();
    if (!TunnelServiceExists()) {
      break;
    }
    RunHidden(uninstall, engine_dir);
    Sleep(400);
  }
  const std::wstring install =
      L"\"" + exe + L"\" /installtunnelservice \"" + conf + L"\"";
  DWORD code = RunHidden(install, engine_dir);
  if (code != 0) {
    StopTunnelService();
    RunHidden(uninstall, engine_dir);
    Sleep(600);
    code = RunHidden(install, engine_dir);
  }
  if (code != 0) {
    return static_cast<int>(code);
  }
  RenameService();
  return 0;
}

std::string Elevate(const std::wstring& params) {
  const std::wstring exe = ExePath();
  if (exe.empty()) {
    return "Не удалось найти TEZVPN.exe";
  }
  EnsureDir(ProgramDataDir());
  DeleteFileW(ResultPath().c_str());
  SHELLEXECUTEINFOW sei;
  ZeroMemory(&sei, sizeof(sei));
  sei.cbSize = sizeof(sei);
  sei.fMask = SEE_MASK_NOCLOSEPROCESS;
  sei.lpVerb = L"runas";
  sei.lpFile = exe.c_str();
  sei.lpParameters = params.c_str();
  sei.nShow = SW_HIDE;
  if (!ShellExecuteExW(&sei)) {
    if (GetLastError() == ERROR_CANCELLED) {
      return "Нужно разрешить запуск SULTAN VPN";
    }
    return "Не удалось запустить SULTAN VPN";
  }
  if (sei.hProcess) {
    WaitForSingleObject(sei.hProcess, 120000);
    CloseHandle(sei.hProcess);
  }
  const std::string result = ReadResult();
  if (result == "ok") {
    return "";
  }
  if (result.empty()) {
    return "SULTAN VPN не включился";
  }
  return result;
}

}  // namespace

int TezInstallTunnel(const wchar_t* conf_path) {
  KillStack();
  const std::wstring dir = ProgramDataDir();
  const std::wstring engine = dir + L"\\engine";
  if (!conf_path || !EnsureDir(dir) || !CopyEngineTo(engine)) {
    WriteResult("Не найдены файлы SULTAN VPN");
    return 1;
  }
  const int code = InstallFromEngine(engine, conf_path);
  if (code != 0) {
    WriteResult("Не удалось включить SULTAN VPN");
    return code;
  }
  WriteProto("awg");
  WriteResult("ok");
  return 0;
}

int TezStartStack(const wchar_t* config_path, const wchar_t* protocol) {
  const std::wstring dir = ProgramDataDir();
  const std::wstring engine = dir + L"\\engine";
  KillStack();
  if (!config_path || !EnsureDir(dir) || !CopyEngineTo(engine)) {
    WriteResult("Не найдены файлы SULTAN VPN");
    return 1;
  }
  StopTunnelService();
  if (TunnelServiceExists()) {
    const std::wstring uninstall =
        L"\"" + EngineExe(engine) + L"\" /uninstalltunnelservice " + kTunnelName;
    RunHidden(uninstall, engine);
    Sleep(400);
  }
  if (!StartStack(engine, config_path)) {
    WriteResult("Не удалось включить выбранный протокол");
    return 1;
  }
  Sleep(1200);
  if (!ProcessRunning(L"sing-box.exe")) {
    WriteResult("Не удалось включить выбранный протокол");
    return 1;
  }
  WriteProto(protocol != nullptr && lstrcmpW(protocol, L"hy2") == 0 ? "hy2" : "xray");
  WriteResult("ok");
  return 0;
}

int TezRemoveTunnel() {
  KillStack();
  StopTunnelService();
  if (!TunnelServiceExists()) {
    WriteProto("off");
    WriteResult("ok");
    return 0;
  }
  const std::wstring engine = ProgramDataDir() + L"\\engine";
  const std::wstring exe = EngineExe(engine);
  const std::wstring command =
      L"\"" + exe + L"\" /uninstalltunnelservice " + kTunnelName;
  const DWORD code = RunHidden(command, engine);
  if (code != 0 && TunnelServiceExists()) {
    WriteResult("Не удалось выключить SULTAN VPN");
    return static_cast<int>(code);
  }
  WriteProto("off");
  WriteResult("ok");
  return 0;
}

std::string TezVpnConnect(const std::string& conf) {
  if (conf.empty()) {
    return "Нет конфигурации SULTAN VPN";
  }
  const std::wstring dir = ProgramDataDir();
  if (!EnsureDir(dir)) {
    return "Не удалось подготовить SULTAN VPN";
  }
  const std::wstring conf_path = dir + L"\\TEZVPN.conf";
  if (!WriteUtf8(conf_path, conf)) {
    return "Не удалось сохранить конфигурацию SULTAN VPN";
  }
  if (IsAdmin()) {
    const int code = TezInstallTunnel(conf_path.c_str());
    return code == 0 ? std::string() : ReadResult();
  }
  return Elevate(L"--install-tunnel \"" + conf_path + L"\"");
}

std::string TezVpnConnectStack(const std::string& json, const std::string& protocol) {
  if (json.empty()) {
    return "Нет конфигурации SULTAN VPN";
  }
  const std::wstring dir = ProgramDataDir();
  if (!EnsureDir(dir)) {
    return "Не удалось подготовить SULTAN VPN";
  }
  const std::wstring path = dir + L"\\stack.json";
  if (!WriteUtf8(path, json)) {
    return "Не удалось сохранить конфигурацию SULTAN VPN";
  }
  const std::wstring proto = protocol == "hy2" ? L"hy2" : L"xray";
  if (IsAdmin()) {
    const int code = TezStartStack(path.c_str(), proto.c_str());
    return code == 0 ? std::string() : ReadResult();
  }
  return Elevate(L"--start-stack \"" + path + L"\" " + proto);
}

std::string TezVpnDisconnect() {
  if (IsAdmin()) {
    const int code = TezRemoveTunnel();
    return code == 0 ? std::string() : ReadResult();
  }
  return Elevate(L"--remove-tunnel");
}

bool TezVpnIsUp() {
  const std::string proto = ReadProto();
  if (proto == "off" || proto == "xray" || proto == "hy2") {
    return false;
  }
  SC_HANDLE scm = OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT);
  if (!scm) {
    return false;
  }
  SC_HANDLE svc = OpenServiceW(scm, kServiceName, SERVICE_QUERY_STATUS);
  if (!svc) {
    CloseServiceHandle(scm);
    return false;
  }
  SERVICE_STATUS status;
  ZeroMemory(&status, sizeof(status));
  const BOOL ok = QueryServiceStatus(svc, &status);
  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
  return ok && status.dwCurrentState == SERVICE_RUNNING;
}

void TezVpnTraffic(unsigned long long* upload, unsigned long long* download) {
  if (upload) *upload = 0;
  if (download) *download = 0;
  PMIB_IF_TABLE2 table = nullptr;
  if (GetIfTable2(&table) != NO_ERROR || table == nullptr) {
    return;
  }
  unsigned long long sent = 0;
  unsigned long long received = 0;
  bool exact = false;
  for (ULONG i = 0; i < table->NumEntries; ++i) {
    const MIB_IF_ROW2& row = table->Table[i];
    const bool named = wcsstr(row.Alias, L"TEZVPN") != nullptr;
    const bool tunnel = wcsstr(row.Description, L"Amnezia") != nullptr ||
                        wcsstr(row.Description, L"Wintun") != nullptr;
    if (!named && !tunnel) {
      continue;
    }
    if (exact && !named) {
      continue;
    }
    sent = row.OutOctets;
    received = row.InOctets;
    if (named) {
      exact = true;
    }
  }
  FreeMibTable(table);
  if (upload) *upload = sent;
  if (download) *download = received;
}
