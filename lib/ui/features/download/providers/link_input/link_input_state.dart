part of 'link_input_notifier.dart';

enum LinkStatus { empty, notALink, unsupported, recognised }

final class const LinkInputState({
  final String text = '',
  final Uri? url,
  final Site? site,
  final LinkStatus linkStatus = .empty,
  super.status,
  super.message,
}) extends BaseState {
  LinkInputState copyWith({StateMessage? message}) =>
      LinkInputState(text: text, url: url, site: site, linkStatus: linkStatus, status: status, message: message);

  @override
  List<Object?> get props => [text, url, site, linkStatus, ...super.props];
}
