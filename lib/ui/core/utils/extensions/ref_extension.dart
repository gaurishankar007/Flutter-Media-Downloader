import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show ProviderListenable;
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/core/utils/toast_util.dart';

extension WidgetRefMessages on WidgetRef {
  /// Shows [provider]'s [BaseState.message] as a toast whenever it's set.
  /// Takes any listenable (`.select`, family providers). Call it at the top of
  /// the build method that owns this `ref`.
  void listenMessages<StateT extends BaseState>(ProviderListenable<StateT> provider, BuildContext context) =>
      listen(provider, (previous, next) {
        if (next.message != null && next.message != previous?.message) {
          ToastUtil.showStateMessage(context, next.message);
        }
      });
}
