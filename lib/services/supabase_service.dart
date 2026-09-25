import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/invoice_model.dart';
import '../models/ledger_entry_model.dart';

/// Central Supabase client wrapper.
/// Handles initialization, auth, and all DB operations.
/// Falls back gracefully when offline — callers catch [SupabaseException].
class SupabaseService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  // ── Initialization ───────────────────────────────────────────────────────
  /// Call once from main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('[Supabase] Initialized → ${AppConfig.supabaseUrl}');
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  /// Sign in with email + password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Sign up a new user.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) =>
      _client.auth.signUp(email: email, password: password, data: data);

  /// Send OTP to email for Customer Portal login.
  Future<void> sendOtp(String email) =>
      _client.auth.signInWithOtp(email: email);

  /// Verify OTP entered by user.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) =>
      _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

  /// Sign out current session.
  Future<void> signOut() => _client.auth.signOut();

  // ── Invoices ──────────────────────────────────────────────────────────────
  /// Upsert a single invoice to Supabase (insert or update if exists).
  Future<void> upsertInvoice(InvoiceModel invoice) async {
    await _client.from('invoices').upsert(invoice.toJson());
    debugPrint('[Supabase] Invoice upserted: ${invoice.invoiceNumber}');
  }

  /// Upsert a batch of invoices (offline queue replay).
  Future<void> upsertInvoiceBatch(List<InvoiceModel> invoices) async {
    if (invoices.isEmpty) return;
    final rows = invoices.map((inv) => inv.toJson()).toList();
    await _client.from('invoices').upsert(rows);
    debugPrint('[Supabase] Batch upserted: ${invoices.length} invoices');
  }

  /// Fetch recent invoices for the current company.
  Future<List<Map<String, dynamic>>> fetchRecentInvoices({
    required String companyId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('invoices')
        .select()
        .eq('companyId', companyId)
        .order('timestamp', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── Ledger entries ────────────────────────────────────────────────────────
  Future<void> upsertLedgerEntry(LedgerEntryModel entry) async {
    await _client.from('ledger_entries').upsert(entry.toJson());
  }

  Future<void> upsertLedgerBatch(List<LedgerEntryModel> entries) async {
    if (entries.isEmpty) return;
    await _client
        .from('ledger_entries')
        .upsert(entries.map((e) => e.toJson()).toList());
  }

  // ── Products & Batches ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchProducts(String companyId) async {
    final response = await _client
        .from('products')
        .select('*, batches(*)')
        .eq('companyId', companyId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> upsertProduct(Map<String, dynamic> product) async {
    await _client.from('products').upsert(product);
  }

  // ── Restricted Drug Log ───────────────────────────────────────────────────
  Future<void> insertRestrictedDrugLog(Map<String, dynamic> log) async {
    await _client.from('restricted_drug_logs').insert(log);
  }

  Future<List<Map<String, dynamic>>> fetchRestrictedDrugLogs(
      String companyId) async {
    final response = await _client
        .from('restricted_drug_logs')
        .select()
        .eq('companyId', companyId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── Companies / Tenants ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAllTenants() async {
    final response =
        await _client.from('companies').select().order('createdAt');
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> upsertCompany(Map<String, dynamic> company) async {
    await _client.from('companies').upsert(company);
  }

  Future<void> updateCompanyStatus({
    required String companyId,
    required bool isActive,
  }) async {
    await _client
        .from('companies')
        .update({'isActive': isActive}).eq('id', companyId);
  }

  // ── Stock Transfers ───────────────────────────────────────────────────────
  Future<void> upsertStockTransfer(Map<String, dynamic> transfer) async {
    await _client.from('stock_transfers').upsert(transfer);
  }

  Future<List<Map<String, dynamic>>> fetchStockTransfers(
      String companyId) async {
    final response = await _client
        .from('stock_transfers')
        .select()
        .or('sourceBranch.eq.$companyId,destinationBranch.eq.$companyId')
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── OTA Version Manifest ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchLatestVersionManifest() async {
    try {
      final response = await _client
          .from('ota_releases')
          .select()
          .order('releasedAt', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  // ── Realtime subscriptions ────────────────────────────────────────────────
  RealtimeChannel subscribeToInvoices({
    required String companyId,
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    return _client
        .channel('invoices:$companyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'companyId',
            value: companyId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }
}
