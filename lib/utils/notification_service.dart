import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../services/report_service.dart';

// Keys untuk tracking notifikasi yang sudah dikirim
const _kNotifiedStock = 'notified_stock_ids';
const _kNotifiedOrders = 'notified_order_ids';

const _stockChannelId = 'bengkelku_stock';
const _stockChannelName = 'Stok Produk';
const _orderChannelId = 'bengkelku_order';
const _orderChannelName = 'Order Bengkel';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Inisialisasi ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // request manual saat login
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  // ── Minta izin notifikasi ─────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // ── Cek & kirim notifikasi baru saja ─────────────────────────────────────
  // Hanya mengirim notifikasi untuk item/order yang BELUM pernah dinotifikasi.
  // Jika item sudah resolved (stok naik / order diproses), hapus dari tracking.

  static Future<void> checkAndNotify({
    required List<StockReport> lowStock,
    required List<OrderModel> pendingOrders,
  }) async {
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    // Tracking IDs yang sudah pernah dinotifikasi
    final notifiedStock =
        Set<String>.from(jsonDecode(prefs.getString(_kNotifiedStock) ?? '[]') as List);
    final notifiedOrders =
        Set<String>.from(jsonDecode(prefs.getString(_kNotifiedOrders) ?? '[]') as List);

    // IDs saat ini yang masih bermasalah
    final currentLowIds = lowStock.map((s) => s.itemId).toSet();
    final currentPendingIds = pendingOrders.map((o) => o.orderId.toString()).toSet();

    // Hapus yang sudah resolved dari tracking
    notifiedStock.removeWhere((id) => !currentLowIds.contains(id));
    notifiedOrders.removeWhere((id) => !currentPendingIds.contains(id));

    // Kirim notifikasi untuk yang BARU (belum pernah dinotifikasi)
    int notifId = 1000;
    for (final s in lowStock) {
      if (!notifiedStock.contains(s.itemId)) {
        final isCritical = s.stock == 0;
        await _show(
          id: notifId++,
          channelId: _stockChannelId,
          channelName: _stockChannelName,
          title: isCritical ? '⚠️ Stok Habis!' : '📦 Stok Menipis',
          body: isCritical
              ? '${s.itemName} sudah habis, segera restok!'
              : '${s.itemName} tinggal ${s.stock} unit',
          importance: isCritical ? Importance.max : Importance.high,
        );
        notifiedStock.add(s.itemId);
      }
    }

    for (final o in pendingOrders) {
      final orderId = o.orderId.toString();
      if (!notifiedOrders.contains(orderId)) {
        await _show(
          id: notifId++,
          channelId: _orderChannelId,
          channelName: _orderChannelName,
          title: '🔔 Order Menunggu',
          body:
              'Order ${o.orderCode} dari ${o.customer?.customerName ?? o.customerId ?? '-'} belum diproses',
          importance: Importance.high,
        );
        notifiedOrders.add(orderId);
      }
    }

    // Simpan tracking terbaru
    await prefs.setString(_kNotifiedStock, jsonEncode(notifiedStock.toList()));
    await prefs.setString(_kNotifiedOrders, jsonEncode(notifiedOrders.toList()));
  }

  // ── Internal: tampilkan satu notifikasi ───────────────────────────────────

  static Future<void> _show({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    Importance importance = Importance.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // ── Reset tracking (panggil saat logout) ──────────────────────────────────

  static Future<void> clearTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotifiedStock);
    await prefs.remove(_kNotifiedOrders);
  }
}
