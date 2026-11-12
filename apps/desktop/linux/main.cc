#include "my_application.h"
#include <webview_cef/webview_cef_plugin.h>

int main(int argc, char** argv) {
  // The in-app video player is Chromium (CEF) drawing into a Flutter texture. Chromium starts helper processes from
  // this same program; this line runs them and returns their exit code. -1 means "this is the app itself".
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
