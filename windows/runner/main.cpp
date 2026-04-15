#include <algorithm>

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kSkipParentConsoleArg[] = L"--skip-parent-console";
constexpr char kSkipParentConsoleArgUtf8[] = "--skip-parent-console";

bool HasSkipParentConsoleFlag() {
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return false;
  }

  bool found = false;
  for (int i = 1; i < argc; ++i) {
    if (wcscmp(argv[i], kSkipParentConsoleArg) == 0) {
      found = true;
      break;
    }
  }

  ::LocalFree(argv);
  return found;
}

void RemoveInternalArguments(std::vector<std::string>& arguments) {
  arguments.erase(
      std::remove(arguments.begin(), arguments.end(), kSkipParentConsoleArgUtf8),
      arguments.end());
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  const bool skip_parent_console = HasSkipParentConsoleFlag();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!skip_parent_console &&
      !::AttachConsole(ATTACH_PARENT_PROCESS) &&
      ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  RemoveInternalArguments(command_line_arguments);

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"oasx", origin, size)) {
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
