import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';

/// Persists the offline invoice queue to SharedPreferences so it
/// survives app restarts. Uses JSON serialization on InvoiceModel.
class OfflineQueueService {
  static const String _key = 'billsprout_offline_queue_v1';

  /// Load persisted queue from SharedPreferences.
  /// Returns an empty list if nothing is stored or on parse error.
  static Future<List<InvoiceModel>> loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OfflineQueue] Load error: $e');
      return [];
    }
  }

  /// Persist the entire queue to SharedPreferences.
  static Future<void> saveQueue(List<InvoiceModel> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(queue.map((inv) => inv.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('[OfflineQueue] Save error: $e');
    }
  }

  /// Append a single invoice to the persisted queue.
  static Future<void> enqueue(InvoiceModel invoice) async {
    final current = await loadQueue();
    // Avoid duplicates
    if (!current.any((i) => i.id == invoice.id)) {
      current.add(invoice);
      await saveQueue(current);
    }
  }

  /// Remove a single invoice from the persisted queue by id.
  static Future<void> dequeue(String invoiceId) async {
    final current = await loadQueue();
    current.removeWhere((i) => i.id == invoiceId);
    await saveQueue(current);
  }

  /// Clear the entire persisted queue (after successful cloud sync).
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns the count of pending items without loading all objects.
  static Future<int> pendingCount() async {
    final queue = await loadQueue();
    return queue.length;
  }
}
