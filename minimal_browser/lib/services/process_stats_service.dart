// ignore_for_file: camel_case_types, non_constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class ResourceStats {
  final int ramBytes;
  final double cpuPercent;

  ResourceStats({required this.ramBytes, required this.cpuPercent});
}

class ProcessStatsService {
  final _controller = StreamController<ResourceStats>.broadcast();
  Stream<ResourceStats> get statsStream => _controller.stream;
  Timer? _timer;

  int _lastSystemTime = 0;
  int _lastProcessTime = 0;
  int _processorCount = 1;

  late final DynamicLibrary _psapi;
  late final int Function(int, Pointer<PROCESS_MEMORY_COUNTERS>, int)
  _getProcessMemoryInfo;

  ProcessStatsService() {
    _initProcessorCount();
    try {
      // Load Psapi.dll or Kernel32.dll (Psapi functions are in Kernel32 on newer Windows, but Psapi.dll forwarding works)
      _psapi = DynamicLibrary.open('psapi.dll');
      _getProcessMemoryInfo = _psapi
          .lookupFunction<
            Int32 Function(IntPtr, Pointer<PROCESS_MEMORY_COUNTERS>, Uint32),
            int Function(int, Pointer<PROCESS_MEMORY_COUNTERS>, int)
          >('GetProcessMemoryInfo');
    } catch (e) {
      print('ProcessStatsService: Failed to load GetProcessMemoryInfo: $e');
    }
  }

  void _initProcessorCount() {
    final Pointer<SYSTEM_INFO> sysInfo = calloc<SYSTEM_INFO>();
    GetSystemInfo(sysInfo);
    _processorCount = sysInfo.ref.dwNumberOfProcessors;
    if (_processorCount <= 0) _processorCount = 1;
    free(sysInfo);
  }

  void startMonitoring({Duration interval = const Duration(seconds: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _fetchStats());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  void _fetchStats() {
    final hProcess = GetCurrentProcess();

    // RAM
    final Pointer<PROCESS_MEMORY_COUNTERS> pmc =
        calloc<PROCESS_MEMORY_COUNTERS>();
    int ram = 0;
    try {
      // cb must be set to the size of the structure
      pmc.ref.cb = sizeOf<PROCESS_MEMORY_COUNTERS>();

      // We use our manually loaded function
      // Using 0 as success check (BOOL returns non-zero for success, actually)
      // GetProcessMemoryInfo returns BOOL (int), non-zero involves success.
      if (_getProcessMemoryInfo(
            hProcess,
            pmc,
            sizeOf<PROCESS_MEMORY_COUNTERS>(),
          ) !=
          0) {
        ram = pmc.ref.WorkingSetSize;
      }
    } catch (e) {
      // Ignore errors if function is not loaded or fails
    }
    free(pmc);

    // CPU
    double cpu = 0.0;
    final Pointer<FILETIME> ftCreation = calloc<FILETIME>();
    final Pointer<FILETIME> ftExit = calloc<FILETIME>();
    final Pointer<FILETIME> ftKernel = calloc<FILETIME>();
    final Pointer<FILETIME> ftUser = calloc<FILETIME>();

    int currentProcessTime = 0;
    // GetProcessTimes is standard in kernel32, win32 package should handle it fine.
    if (GetProcessTimes(hProcess, ftCreation, ftExit, ftKernel, ftUser) != 0) {
      final kernel =
          (ftKernel.ref.dwHighDateTime << 32) | ftKernel.ref.dwLowDateTime;
      final user = (ftUser.ref.dwHighDateTime << 32) | ftUser.ref.dwLowDateTime;
      currentProcessTime = kernel + user;
    }
    free(ftCreation);
    free(ftExit);
    free(ftKernel);
    free(ftUser);

    final currentSystemTime = DateTime.now().microsecondsSinceEpoch * 10;

    if (_lastSystemTime > 0 && _lastProcessTime > 0) {
      final systemDelta = currentSystemTime - _lastSystemTime;
      final processDelta = currentProcessTime - _lastProcessTime;

      if (systemDelta > 0) {
        cpu = (processDelta / systemDelta) / _processorCount * 100;
        if (cpu < 0) cpu = 0;
        if (cpu > 100) cpu = 100;
      }
    }

    _lastProcessTime = currentProcessTime;
    _lastSystemTime = currentSystemTime;

    _controller.add(ResourceStats(ramBytes: ram, cpuPercent: cpu));
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

// Manually define the struct as it seems missing or problematic in recent win32 versions for easy access
final class PROCESS_MEMORY_COUNTERS extends Struct {
  @Uint32()
  external int cb;

  @Uint32()
  external int PageFaultCount;

  @IntPtr()
  external int PeakWorkingSetSize;

  @IntPtr()
  external int WorkingSetSize;

  @IntPtr()
  external int QuotaPeakPagedPoolUsage;

  @IntPtr()
  external int QuotaPagedPoolUsage;

  @IntPtr()
  external int QuotaPeakNonPagedPoolUsage;

  @IntPtr()
  external int QuotaNonPagedPoolUsage;

  @IntPtr()
  external int PagefileUsage;

  @IntPtr()
  external int PeakPagefileUsage;
}
