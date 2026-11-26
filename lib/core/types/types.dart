import 'dart:async';

import 'package:media_downloader/core/data/states/data_state.dart';

/// An asynchronous operation that completes with a [DataState] containing [T].
typedef FutureData<T> = Future<DataState<T>>;

/// An asynchronous operation that completes with a [DataState] containing a [List] of [T].
typedef FutureList<T> = Future<DataState<List<T>>>;

/// A stream of [DataState] events containing [T].
typedef StreamData<T> = Stream<DataState<T>>;

/// An asynchronous operation with no result payload.
typedef FutureVoid = Future<DataState<void>>;

/// A decoded JSON object.
typedef JsonMap = Map<String, dynamic>;
