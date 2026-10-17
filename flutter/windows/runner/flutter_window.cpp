#include "flutter_window.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "vpn_win.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter::MethodChannel<flutter::EncodableValue> channel(
      flutter_controller_->engine()->messenger(), "ru.tezvpn.app/vpn",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "prepare") {
          result->Success(flutter::EncodableValue(true));
          return;
        }
        if (method == "isUp") {
          result->Success(flutter::EncodableValue(TezVpnIsUp()));
          return;
        }
        if (method == "connect") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          std::string conf;
          if (args != nullptr) {
            const auto it = args->find(flutter::EncodableValue("conf"));
            if (it != args->end()) {
              const auto* value = std::get_if<std::string>(&it->second);
              if (value != nullptr) {
                conf = *value;
              }
            }
          }
          const std::string error = TezVpnConnect(conf);
          if (!error.empty()) {
            result->Error("vpn", error);
            return;
          }
          result->Success();
          return;
        }
        if (method == "disconnect") {
          const std::string error = TezVpnDisconnect();
          if (!error.empty()) {
            result->Error("vpn", error);
            return;
          }
          result->Success();
          return;
        }
        if (method == "traffic") {
          unsigned long long upload = 0;
          unsigned long long download = 0;
          TezVpnTraffic(&upload, &download);
          flutter::EncodableMap totals;
          totals[flutter::EncodableValue("up")] =
              flutter::EncodableValue(static_cast<int64_t>(upload));
          totals[flutter::EncodableValue("down")] =
              flutter::EncodableValue(static_cast<int64_t>(download));
          result->Success(flutter::EncodableValue(totals));
          return;
        }
        result->NotImplemented();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
