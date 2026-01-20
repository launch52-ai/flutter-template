// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: DTO with Custom JSON Converters
// When API uses non-standard formats (uppercase enums, unix timestamps).

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
abstract class OrderModel with _$OrderModel {
  const OrderModel._();

  const factory OrderModel({
    required String id,
    @JsonKey(name: 'total_cents') required int totalCents,
    @JsonKey(name: 'status') @OrderStatusConverter() required OrderStatus status,
    @JsonKey(name: 'created_at') @UnixDateTimeConverter() required DateTime createdAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Order toEntity() => Order(
        id: id,
        totalCents: totalCents,
        status: status,
        createdAt: createdAt,
      );

  factory OrderModel.fromEntity(Order entity) => OrderModel(
        id: entity.id,
        totalCents: entity.totalCents,
        status: entity.status,
        createdAt: entity.createdAt,
      );
}

/// Converts API status strings (UPPERCASE) to enum.
final class OrderStatusConverter implements JsonConverter<OrderStatus, String> {
  const OrderStatusConverter();

  @override
  OrderStatus fromJson(String json) {
    return switch (json) {
      'PENDING' => OrderStatus.pending,
      'CONFIRMED' => OrderStatus.confirmed,
      'PROCESSING' => OrderStatus.processing,
      'SHIPPED' => OrderStatus.shipped,
      'DELIVERED' => OrderStatus.delivered,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  @override
  String toJson(OrderStatus object) => object.name.toUpperCase();
}

/// Converts Unix timestamp (seconds) to DateTime.
final class UnixDateTimeConverter implements JsonConverter<DateTime, int> {
  const UnixDateTimeConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json * 1000);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch ~/ 1000;
}
