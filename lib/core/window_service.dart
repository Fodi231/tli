// Picks the real implementation on platforms that have dart:io (mobile and
// desktop) and a no-op stub on the web. The window itself is only touched on
// desktop operating systems (see WinService.isDesktop).
export 'window_stub.dart' if (dart.library.io) 'window_desktop.dart';
