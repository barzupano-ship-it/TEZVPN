#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"
#include "vpn_win.h"

#include <shellapi.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  int argc = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  if (argv != nullptr && argc >= 2) {
    if (lstrcmpW(argv[1], L"--install-tunnel") == 0 && argc >= 3) {
      const int code = TezInstallTunnel(argv[2]);
      LocalFree(argv);
      return code;
    }
    if (lstrcmpW(argv[1], L"--remove-tunnel") == 0) {
      const int code = TezRemoveTunnel();
      LocalFree(argv);
      return code;
    }
    if (lstrcmpW(argv[1], L"--start-stack") == 0 && argc >= 4) {
      const int code = TezStartStack(argv[2], argv[3]);
      LocalFree(argv);
      return code;
    }
  }
  if (argv != nullptr) {
    LocalFree(argv);
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"TEZVPN", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
