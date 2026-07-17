// ============================================================
//  lib/config.dart  —  Backend connection settings.
//  Goes in:  hissa_mobile/lib/config.dart   (replace all)
// ============================================================

const bool useMock = false;

// ---- Pick the ONE that matches how you're running --------------------
//
//  Real Android PHONE (this PC's Wi-Fi IP):  http://192.168.100.159:3000   <-- ACTIVE
//  Chrome (web) on this PC:                  http://localhost:3000
//  Android EMULATOR:                         http://10.0.2.2:3000
//
//  Phone and PC must be on the SAME Wi-Fi.
//  If your PC's IP changes (new network/reboot), re-run `ipconfig`
//  and update this line AND network_security_config.xml.
// ---------------------------------------------------------------------

const String apiBaseUrl = 'http://192.168.100.159:3000';