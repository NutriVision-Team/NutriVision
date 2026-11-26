Future<T> crossTabQueueLock<T>(String name, Future<T> Function() action) =>
    action();
