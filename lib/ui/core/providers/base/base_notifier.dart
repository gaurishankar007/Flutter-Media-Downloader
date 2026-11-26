import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_flow.dart';
import 'package:media_tool/core/errors/error_recorders/app_error_recorder.dart';

part 'base_state.dart';
part 'error_tracking.dart';

abstract class BaseNotifier<T> extends Notifier<T> with ErrorTracking;

abstract class BaseAsyncNotifier<T> extends AsyncNotifier<T> with ErrorTracking;

abstract class BaseStreamNotifier<T> extends StreamNotifier<T> with ErrorTracking;
