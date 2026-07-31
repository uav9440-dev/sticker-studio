/// Generic bounded undo/redo stack over immutable snapshots.
/// Because layers/projects are immutable, snapshots are just references —
/// undo is O(1) and memory cost is shared structure.
class History<T> {
  History(this._present, {this.capacity = 100});

  final int capacity;
  final List<T> _past = [];
  final List<T> _future = [];
  T _present;

  T get present => _present;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  void push(T next) {
    _past.add(_present);
    if (_past.length > capacity) _past.removeAt(0);
    _present = next;
    _future.clear();
  }

  /// Replace the present without creating an undo step — used while a
  /// gesture is in flight so dragging a layer is one undoable action.
  void replace(T next) => _present = next;

  T undo() {
    if (!canUndo) return _present;
    _future.add(_present);
    _present = _past.removeLast();
    return _present;
  }

  T redo() {
    if (!canRedo) return _present;
    _past.add(_present);
    _present = _future.removeLast();
    return _present;
  }
}
