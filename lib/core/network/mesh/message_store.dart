import 'dart:collection';
import 'mesh_message.dart';
import '../../utils/app_logger.dart';

class MessageStore {
  // Pending messages (not yet delivered)
  final Queue<MeshMessage> _pendingQueue = Queue();

  // Message deduplication cache (message ID → timestamp)
  final Map<String, DateTime> _seenMessages = {};

  // Failed messages (for retry)
  final Queue<MeshMessage> _failedQueue = Queue();

  static const int maxPendingMessages = 1000;
  static const int maxSeenMessages = 5000;
  static const Duration messageExpiry = Duration(hours: 24);
  static const Duration seenExpiry = Duration(hours: 2);

  /// Add message to pending queue (M3.1)
  bool addPending(MeshMessage message) {
    // Check if already seen
    if (isDuplicate(message.id)) {
      AppLogger.debug('⚠️ Duplicate message rejected: ${message.id}');
      return false;
    }

    // Check queue capacity
    if (_pendingQueue.length >= maxPendingMessages) {
      AppLogger.warning('📦 Pending queue full, dropping oldest message');
      _pendingQueue.removeFirst();
    }

    _pendingQueue.add(message);
    _markAsSeen(message.id);

    AppLogger.debug('📥 Message queued: ${message.id} (queue size: ${_pendingQueue.length})');
    return true;
  }

  /// Get next message to relay
  MeshMessage? getNextPending() {
    if (_pendingQueue.isEmpty) return null;

    final message = _pendingQueue.removeFirst();

    // Check if message expired
    if (_isExpired(message)) {
      AppLogger.debug('⏰ Message expired: ${message.id}');
      return getNextPending(); // Try next
    }

    return message;
  }

  /// Mark message as seen (deduplication)
  void _markAsSeen(String messageId) {
    _seenMessages[messageId] = DateTime.now();

    // Cleanup old entries
    if (_seenMessages.length > maxSeenMessages) {
      _cleanupSeenMessages();
    }
  }

  /// Check if message was already seen
  bool isDuplicate(String messageId) {
    return _seenMessages.containsKey(messageId);
  }

  /// Check if message is expired
  bool _isExpired(MeshMessage message) {
    return DateTime.now().difference(message.timestamp) > messageExpiry;
  }

  /// Add to failed queue for retry
  void markAsFailed(MeshMessage message) {
    if (_failedQueue.length < 100) {
      _failedQueue.add(message);
      AppLogger.warning('❌ Message marked as failed: ${message.id}');
    }
  }

  /// Retry failed messages
  List<MeshMessage> getFailedMessages() {
    final failed = _failedQueue.toList();
    _failedQueue.clear();
    return failed;
  }

  /// Cleanup expired seen messages
  void _cleanupSeenMessages() {
    final now = DateTime.now();
    _seenMessages.removeWhere((id, timestamp) {
      return now.difference(timestamp) > seenExpiry;
    });
    AppLogger.debug('🧹 Cleanup: ${_seenMessages.length} messages in seen cache');
  }

  /// Get statistics
  Map<String, int> getStats() {
    return {
      'pending': _pendingQueue.length,
      'failed': _failedQueue.length,
      'seen': _seenMessages.length,
    };
  }

  /// Clear all queues
  void clear() {
    _pendingQueue.clear();
    _failedQueue.clear();
    _seenMessages.clear();
    AppLogger.info('🧹 Message store cleared');
  }

  int get pendingCount => _pendingQueue.length;
  int get failedCount => _failedQueue.length;
}