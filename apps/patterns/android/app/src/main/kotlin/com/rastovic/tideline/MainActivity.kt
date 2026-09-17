package com.rastovic.tideline

import io.flutter.embedding.android.FlutterFragmentActivity

// A FragmentActivity because local_auth shows the system biometric prompt,
// which is a fragment and cannot attach to a plain FlutterActivity.
class MainActivity : FlutterFragmentActivity()
