// Browser Web Locks, scoped to this origin and an owner-specific queue name.
import 'dart:async';
import 'dart:js_interop';

@JS('navigator.locks.request')
external JSPromise<JSAny?> _request(JSString name, JSFunction callback);
Future<T> crossTabQueueLock<T>(String name, Future<T> Function() action) async {
  late T result;
  Object? failure;
  StackTrace? trace;
  await _request(
    name.toJS,
    ((JSAny? _) {
      return (() async {
        try {
          result = await action();
        } catch (e, s) {
          failure = e;
          trace = s;
        }
        return null;
      })().toJS;
    }).toJS,
  ).toDart;
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return result;
}
