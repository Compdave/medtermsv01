// lib/core/services/customer_service.dart

import 'package:medtermsv01/models/models.dart';
import 'supabase_service.dart';

/// Handles LemonSqueezy customer record operations.
/// The customers table is primarily written to by the lemonsqueezy-webhook
/// Edge Function on purchase. This service provides read access and
/// the upsert for cases where the client needs to sync customer data.
/// Errors are thrown — callers are responsible for try/catch.
class CustomerService {
  CustomerService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the customer record for the given [userId].
  /// Returns null if no customer record exists (user has never purchased).
  static Future<CustomerModel?> fetchCustomer(String userId) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return CustomerModel.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Upsert
  // ---------------------------------------------------------------------------

  /// Insert or update a customer record.
  /// If a record with [lsCustomerId] already exists it is updated.
  /// If not, a new record is inserted.
  /// Typically called by the LemonSqueezy webhook — only use client-side
  /// if you need to manually sync a customer record.
  /// Calls: upsert_customer(pls_customer_id, puser_id, pemail)
  static Future<void> upsertCustomer({
    required String lsCustomerId,
    required String userId,
    required String email,
  }) async {
    await _client.rpc(
      'upsert_customer',
      params: {
        'pls_customer_id': lsCustomerId,
        'puser_id': userId,
        'pemail': email,
      },
    );
  }
}
