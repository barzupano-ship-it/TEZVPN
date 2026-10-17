#ifndef RUNNER_VPN_WIN_H_
#define RUNNER_VPN_WIN_H_

#include <string>

// Runs inside an already elevated process. Returns 0 on success.
int TezInstallTunnel(const wchar_t* conf_path);
int TezRemoveTunnel();
int TezStartStack(const wchar_t* config_path, const wchar_t* protocol);

// Called from the TEZVPN window. Empty string means success.
std::string TezVpnConnect(const std::string& conf);
std::string TezVpnConnectStack(const std::string& json, const std::string& protocol);
std::string TezVpnDisconnect();
bool TezVpnIsUp();
void TezVpnTraffic(unsigned long long* upload, unsigned long long* download);

#endif  // RUNNER_VPN_WIN_H_
