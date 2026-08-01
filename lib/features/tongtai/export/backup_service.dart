library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../database/database.dart';
import '../profile/business_profile.dart';
import '../profile/business_profile_repository.dart';
import '../journey/journey.dart';
import '../journey/journey_repository.dart';
import '../consumer/customer.dart';
import '../consumer/customer_repository.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_transaction.dart';
import '../inventory/product.dart';
import '../inventory/product_repository.dart';
import '../journey/business_goal.dart';
import '../journey/business_goal_repository.dart';
import '../opportunity/opportunity.dart';
import '../opportunity/opportunity_reaction_repository.dart';
import '../orders/order.dart';
import '../orders/order_repository.dart';
import '../producer/supplier_favorite.dart';
import '../producer/supplier_favorites_store.dart';
import 'backup_codec.dart';
import 'backup_crypto.dart';
import 'backup_format.dart';

/// Creating, validating and **restoring** a `.ttbk` v2 backup (WTM-164,
/// ADR-TON-018).
///
/// Restore is **Replace only** (Founder decision, 2026-07-31): one complete,
/// internally consistent snapshot goes in, and the business becomes exactly
/// that snapshot. Merge is a different capability with its own reconciliation
/// rules and is deliberately not smuggled in here.
///
/// The order of operations is the whole design:
///
/// ```text
/// parse → validate EVERYTHING → build + verify safety backup
///       → one transaction { wipe → write → verify } → commit
/// ```
///
/// Nothing touches the database until the file has been fully validated, and
/// nothing is discarded until a verified safety backup exists. Any failure at
/// any step leaves the current database exactly as it was.

/// Everything a backup covers. One bundle so a new dataset is a compile error
/// here rather than a silently missing table in someone's restore.
@immutable
class TongtaiBackupRepositories {
  const TongtaiBackupRepositories({
    required this.database,
    required this.customers,
    required this.products,
    required this.orders,
    required this.goals,
    required this.finance,
    required this.favourites,
    this.businessProfile,
    this.journeys,
    this.opportunityReactions,
  });

  /// Needed for the single transaction that makes Replace atomic — the one
  /// place in the app that legitimately spans repositories.
  final AppDatabase database;

  final CustomerRepository customers;
  final ProductRepository products;
  final OrderRepository orders;
  final BusinessGoalRepository goals;
  final FinanceRepository finance;
  final SupplierFavoritesStore favourites;

  /// AI Business Profile (WTM-177). Nullable so the many existing call sites
  /// that build this bundle keep compiling; a `null` repository simply means
  /// no profile is backed up or restored.
  final BusinessProfileRepository? businessProfile;

  /// Business Journey tree (WTM-185). Nullable for the same reason as
  /// [businessProfile]: existing call sites keep compiling, and a `null`
  /// repository simply means journeys are neither backed up nor restored.
  final JourneyRepository? journeys;

  /// Opportunity reactions (WTM-190). Nullable for the same reason as
  /// [journeys]; `null` means reactions are neither backed up nor restored.
  final OpportunityReactionRepository? opportunityReactions;
}

/// The decoded, type-checked contents of a backup.
@immutable
class BackupContents {
  const BackupContents({
    required this.customers,
    required this.products,
    required this.orders,
    required this.goals,
    required this.transactions,
    required this.favourites,
    this.businessProfile,
    this.journeys = const [],
    this.opportunityReactions = const {},
  });

  final List<Customer> customers;
  final List<Product> products;
  final List<CustomerOrder> orders;
  final List<BusinessGoal> goals;
  final List<FinanceTransaction> transactions;
  final List<SupplierFavorite> favourites;

  /// AI Business Profile (WTM-177). Optional: `null` means the package carries
  /// no profile — either it predates the feature, or the seller never answered.
  /// Both read the same way and neither blocks a restore.
  final BusinessProfile? businessProfile;

  /// Business Journey tree (WTM-185). Empty means the package carries none —
  /// either it predates the feature or the seller never opened a journey.
  final List<Journey> journeys;

  /// The seller's decisions about opportunities (WTM-190), keyed by
  /// opportunity id. Empty means the package carries none — either it predates
  /// the feature or the seller never saved or dismissed anything.
  final Map<String, OpportunityReaction> opportunityReactions;

  Map<String, int> get counts => {
    BackupDatasets.customers: customers.length,
    BackupDatasets.products: products.length,
    BackupDatasets.orders: orders.length,
    BackupDatasets.goals: goals.length,
    BackupDatasets.transactions: transactions.length,
    BackupDatasets.favourites: favourites.length,
  };

  int get totalRecords =>
      customers.length +
      products.length +
      orders.length +
      goals.length +
      transactions.length +
      favourites.length;
}

/// Why a backup was rejected. Every value is a *blocking* problem: v2 has no
/// best-effort partial import, so there are no warnings to weigh — a file is
/// restorable or it is not.
enum BackupProblem {
  /// Not a Tổng Tài v2 backup (wrong header, unparseable envelope). A v1
  /// `.ttbk` lands here too, on purpose.
  notABackup,

  /// Written by a newer app/schema than this build understands.
  tooNew,

  /// A version this build has no migration for.
  unsupportedVersion,

  /// Stored payload is shorter than the manifest declares.
  truncated,

  /// SHA-256 of the payload does not match the manifest.
  checksumMismatch,

  /// Encrypted, and no passphrase was supplied.
  passphraseRequired,

  /// Encrypted, and the passphrase did not decrypt it (or the ciphertext was
  /// tampered with — AES-GCM cannot tell those apart, and neither will we).
  wrongPassphrase,

  /// Payload decrypted but is not a valid v2 payload document.
  malformedPayload,

  /// One of the six datasets is absent. A partial package is a legitimate
  /// *package* (WTM-165) — it is just not a **restorable** one, so this is
  /// raised against the restore contract, not against the format.
  missingDataset,

  /// The package declares itself as something other than a backup (clone,
  /// demo dataset, support bundle…). Reserved kinds are identified, never
  /// guessed at: honouring one without its rules is how a "clone" becomes a
  /// data-loss event.
  notRestorableKind,

  /// Personal data was stripped before the package was written. Restoring it
  /// would write blanks over real customers.
  redactedPackage,

  /// A row could not be decoded: missing field, wrong type, or an enum code
  /// this build does not know.
  invalidRecord,

  /// Two records in the same dataset share an id.
  duplicateId,

  /// An order points at a customer id the backup does not contain.
  brokenForeignKey,

  /// The counts the writer declared disagree with the rows actually present.
  countMismatch;

  String get code => name;
}

/// One rejected-file finding, with enough detail to fix the file — but never
/// the file's *contents*.
@immutable
class BackupIssue {
  const BackupIssue(this.problem, {this.dataset, this.detail});

  final BackupProblem problem;
  final String? dataset;

  /// Technical detail for the person holding the phone (a row index, a code).
  /// Never business content, and never sent anywhere.
  final String? detail;

  @override
  String toString() =>
      '${problem.code}${dataset == null ? '' : '/$dataset'}'
      '${detail == null ? '' : ' ($detail)'}';
}

/// The result of inspecting a file **without touching the database**.
@immutable
class BackupValidation {
  const BackupValidation({
    required this.issues,
    this.manifest,
    this.compatibility,
    this.contents,
  });

  final List<BackupIssue> issues;

  /// Present as soon as the envelope parsed — so a preview can still show
  /// "written by app 0.2.0" even when the file is rejected as too new.
  final BackupManifest? manifest;

  final BackupCompatibility? compatibility;

  /// Present only when the file is fully valid.
  final BackupContents? contents;

  bool get isRestorable => issues.isEmpty && contents != null;

  BackupProblem? get firstProblem =>
      issues.isEmpty ? null : issues.first.problem;
}

/// Where the automatic pre-restore safety backup is written.
///
/// A seam because it is the one part of restore that touches the filesystem:
/// production uses the app's documents directory, tests use a temp dir — and
/// one test uses an implementation that always fails, to prove the restore
/// really does refuse to continue.
abstract interface class BackupVault {
  /// Persists [armored] under a name derived from [label]; returns the path.
  Future<String> write(String label, String armored);

  /// Reads back what [write] stored, so the safety copy can be *verified*
  /// rather than assumed.
  Future<String> read(String path);
}

/// Writes safety backups into the app's documents directory.
class DocumentsBackupVault implements BackupVault {
  const DocumentsBackupVault();

  @override
  Future<String> write(String label, String armored) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$label');
    await file.writeAsString(armored, flush: true);
    return file.path;
  }

  @override
  Future<String> read(String path) => File(path).readAsString();
}

/// What a completed restore did.
@immutable
class BackupRestoreReport {
  const BackupRestoreReport({
    required this.restored,
    required this.safetyBackupPath,
    required this.replacedCounts,
  });

  /// Counts now in the database.
  final Map<String, int> restored;

  /// Where the pre-restore state was saved. Shown to the user: the point of a
  /// destructive action is that the previous state is recoverable.
  final String safetyBackupPath;

  /// What was there before — so "replaced 412 customers with 380" is sayable.
  final Map<String, int> replacedCounts;
}

/// Thrown when a restore cannot proceed. Carries a [BackupProblem] so the UI
/// classifies it exactly like any other failure (ADR-TON-017).
class BackupRestoreException implements Exception {
  const BackupRestoreException(this.problem, [this.detail]);

  final BackupProblem? problem;
  final String? detail;

  @override
  String toString() =>
      'BackupRestoreException(${problem?.code ?? 'apply'})'
      '${detail == null ? '' : ': $detail'}';
}

/// Creates, validates and restores backups.
class TongtaiBackupService {
  const TongtaiBackupService({
    required this.repositories,
    this.crypto = const BackupCrypto(),
    this.vault = const DocumentsBackupVault(),
    this.clock = DateTime.now,
    this.randomId = _defaultRandomId,
  });

  final TongtaiBackupRepositories repositories;
  final BackupCrypto crypto;
  final BackupVault vault;
  final DateTime Function() clock;
  final String Function() randomId;

  static String _defaultRandomId() {
    final rnd = Random.secure();
    return List.generate(
      16,
      (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  // ── create ───────────────────────────────────────────────────────────────

  /// Reads every repository and builds an armored v2 document.
  ///
  /// A passphrase turns on AES-256-GCM. Without one the payload is plaintext
  /// JSON — still checksummed, because corruption is possible either way.
  Future<String> createBackup({String? passphrase}) async {
    final contents = await _readCurrentContents();
    return encodeContents(contents, passphrase: passphrase);
  }

  /// Serialises [contents] into an armored document. Split out from
  /// [createBackup] so the safety backup and tests share one encoder.
  Future<String> encodeContents(
    BackupContents contents, {
    String? passphrase,
  }) async {
    final payload = BackupPayload(
      declaredCounts: contents.counts,
      datasets: {
        BackupDatasets.customers: [
          for (final c in contents.customers) BackupCodec.encodeCustomer(c),
        ],
        BackupDatasets.products: [
          for (final p in contents.products) BackupCodec.encodeProduct(p),
        ],
        BackupDatasets.orders: [
          for (final o in contents.orders) BackupCodec.encodeOrder(o),
        ],
        BackupDatasets.goals: [
          for (final g in contents.goals) BackupCodec.encodeGoal(g),
        ],
        BackupDatasets.transactions: [
          for (final t in contents.transactions)
            BackupCodec.encodeTransaction(t),
        ],
        if (contents.businessProfile?.isNotEmpty ?? false)
          BackupDatasets.businessProfile: [contents.businessProfile!.toJson()],
        if (contents.journeys.isNotEmpty)
          BackupDatasets.journeys: [
            for (final j in contents.journeys) BackupCodec.encodeJourney(j),
          ],
        if (contents.opportunityReactions.isNotEmpty)
          BackupDatasets.opportunityReactions: [
            for (final e in contents.opportunityReactions.entries)
              BackupCodec.encodeOpportunityReaction(e.key, e.value),
          ],
        BackupDatasets.favourites: [
          for (final f in contents.favourites) BackupCodec.encodeFavourite(f),
        ],
      },
    );
    final plaintext = jsonEncode(payload.toJson());
    final encrypted = passphrase != null && passphrase.isNotEmpty;
    final stored = encrypted
        ? utf8.encode(await crypto.encryptArmored(plaintext, passphrase))
        : utf8.encode(plaintext);
    final manifest = BackupManifest(
      formatVersion: kBackupFormatVersion,
      contentSchemaVersion: kBackupContentSchemaVersion,
      appVersion: kTongtaiAppVersion,
      databaseSchemaVersion: currentDatabaseSchemaVersion,
      backupId: randomId(),
      createdAt: clock(),
      encryption: encrypted ? BackupEncryption.aesGcm : BackupEncryption.none,
      compression: 'none',
      checksumAlgorithm: 'SHA-256',
      payloadSha256: backupSha256Hex(stored),
      payloadBytes: stored.length,
      // WTM-165: a package says what it is and what it holds. Today the app
      // only writes complete, unredacted backups — but it says so explicitly
      // rather than leaving a future reader to assume it.
      packageKind: PackageKind.backup,
      datasets: [
        ...BackupDatasets.all,
        if (contents.businessProfile?.isNotEmpty ?? false)
          BackupDatasets.businessProfile,
        if (contents.journeys.isNotEmpty) BackupDatasets.journeys,
        if (contents.opportunityReactions.isNotEmpty)
          BackupDatasets.opportunityReactions,
      ],
      redaction: BackupRedaction.none,
    );
    return encodeBackupDocument(manifest, stored);
  }

  Future<BackupContents> _readCurrentContents() async => BackupContents(
    customers: await repositories.customers.loadAll(),
    products: await repositories.products.loadAll(),
    orders: await repositories.orders.loadAll(),
    goals: await repositories.goals.loadAll(),
    transactions: await repositories.finance.loadAll(),
    favourites: await repositories.favourites.loadAll(),
    businessProfile: await repositories.businessProfile?.load(),
    journeys: await repositories.journeys?.loadAll() ?? const [],
    opportunityReactions:
        await repositories.opportunityReactions?.loadAll() ?? const {},
  );

  // ── validate ─────────────────────────────────────────────────────────────

  /// Inspects [armored] end to end **without touching the database**.
  ///
  /// Returns on the first blocking problem in each stage: there is no value in
  /// listing row errors for a file whose checksum already failed.
  Future<BackupValidation> validate(
    String armored, {
    String? passphrase,
  }) async {
    final envelope = decodeBackupDocument(armored);
    if (envelope == null) {
      return const BackupValidation(
        issues: [BackupIssue(BackupProblem.notABackup)],
      );
    }
    final manifest = envelope.manifest;
    final compatibility = backupCompatibilityOf(manifest);
    BackupValidation reject(BackupIssue issue) => BackupValidation(
      issues: [issue],
      manifest: manifest,
      compatibility: compatibility,
    );

    if (!compatibility.canRestore) {
      return reject(
        BackupIssue(
          compatibility == BackupCompatibility.tooNew
              ? BackupProblem.tooNew
              : BackupProblem.unsupportedVersion,
          detail:
              'format ${manifest.formatVersion}'
              '/content ${manifest.contentSchemaVersion}',
        ),
      );
    }

    // Cheap structural checks first: a truncated file should not cost a hash.
    if (envelope.payloadBytes.length != manifest.payloadBytes) {
      return reject(
        BackupIssue(
          BackupProblem.truncated,
          detail:
              '${envelope.payloadBytes.length} of ${manifest.payloadBytes} '
              'bytes',
        ),
      );
    }
    final digest = backupSha256Hex(envelope.payloadBytes);
    if (digest != manifest.payloadSha256) {
      return reject(const BackupIssue(BackupProblem.checksumMismatch));
    }

    final String plaintext;
    if (manifest.encryption == BackupEncryption.aesGcm) {
      if (passphrase == null || passphrase.isEmpty) {
        return reject(const BackupIssue(BackupProblem.passphraseRequired));
      }
      try {
        plaintext = await crypto.decryptArmored(
          utf8.decode(envelope.payloadBytes),
          passphrase,
        );
      } on Object {
        // A wrong passphrase and a tampered ciphertext are the same GCM
        // failure; we do not pretend to distinguish them.
        return reject(const BackupIssue(BackupProblem.wrongPassphrase));
      }
    } else {
      try {
        plaintext = utf8.decode(envelope.payloadBytes);
      } on FormatException {
        return reject(const BackupIssue(BackupProblem.malformedPayload));
      }
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(plaintext);
    } on FormatException {
      return reject(const BackupIssue(BackupProblem.malformedPayload));
    }
    final payload = BackupPayload.tryParse(decoded);
    if (payload == null) {
      return reject(const BackupIssue(BackupProblem.malformedPayload));
    }

    final issues = <BackupIssue>[];

    // ── restore contract (WTM-165) ──────────────────────────────────────────
    // These are not format errors. The package parsed fine; it is simply not
    // something that may be written over a live business.
    if (!manifest.packageKind.isRestorable) {
      issues.add(
        BackupIssue(
          BackupProblem.notRestorableKind,
          detail: manifest.packageKind.code,
        ),
      );
    }
    if (manifest.redaction != BackupRedaction.none) {
      issues.add(
        BackupIssue(
          BackupProblem.redactedPackage,
          detail: manifest.redaction.code,
        ),
      );
    }

    // A restorable package must carry the whole business. A package missing a
    // dataset is still a valid package — it just cannot be restored.
    for (final dataset in BackupDatasets.all) {
      if (!payload.datasets.containsKey(dataset)) {
        issues.add(BackupIssue(BackupProblem.missingDataset, dataset: dataset));
      }
    }
    if (issues.isNotEmpty) {
      return BackupValidation(
        issues: issues,
        manifest: manifest,
        compatibility: compatibility,
      );
    }

    final contents = _decodeContents(payload, issues);
    if (issues.isNotEmpty) {
      return BackupValidation(
        issues: issues,
        manifest: manifest,
        compatibility: compatibility,
      );
    }

    _checkIntegrity(contents!, payload.declaredCounts, issues);
    return BackupValidation(
      issues: issues,
      manifest: manifest,
      compatibility: compatibility,
      contents: issues.isEmpty ? contents : null,
    );
  }

  BackupContents? _decodeContents(
    BackupPayload payload,
    List<BackupIssue> issues,
  ) {
    List<T>? decode<T>(
      String dataset,
      T? Function(Map<String, Object?>) decoder,
    ) {
      final rows = payload.datasets[dataset]!;
      final out = <T>[];
      for (var i = 0; i < rows.length; i++) {
        final value = decoder(rows[i]);
        if (value == null) {
          issues.add(
            BackupIssue(
              BackupProblem.invalidRecord,
              dataset: dataset,
              detail: 'row $i',
            ),
          );
          return null;
        }
        out.add(value);
      }
      return out;
    }

    final customers = decode(
      BackupDatasets.customers,
      BackupCodec.decodeCustomer,
    );
    final products = decode(BackupDatasets.products, BackupCodec.decodeProduct);
    final orders = decode(BackupDatasets.orders, BackupCodec.decodeOrder);
    final goals = decode(BackupDatasets.goals, BackupCodec.decodeGoal);
    final transactions = decode(
      BackupDatasets.transactions,
      BackupCodec.decodeTransaction,
    );
    final favourites = decode(
      BackupDatasets.favourites,
      BackupCodec.decodeFavourite,
    );
    if (customers == null ||
        products == null ||
        orders == null ||
        goals == null ||
        transactions == null ||
        favourites == null) {
      return null;
    }
    // Optional dataset (WTM-177): absent is normal — every `.ttbk` written
    // before the profile existed lacks it, and those files must still restore.
    // A malformed profile is dropped rather than failing the whole package,
    // because losing four categorical answers must never cost a seller their
    // orders.
    final profileRows = payload.datasets[BackupDatasets.businessProfile];
    BusinessProfile? profile;
    if (profileRows != null && profileRows.isNotEmpty) {
      try {
        profile = BusinessProfile.fromJson(
          Map<String, dynamic>.from(profileRows.first),
        );
      } on Object {
        profile = null;
      }
    }
    // Optional dataset (WTM-185): absent is normal — every `.ttbk` written
    // before journeys existed lacks it, and those files must still restore.
    // A malformed journey is dropped rather than failing the package: losing a
    // plan must never cost a seller their orders.
    final journeyRows = payload.datasets[BackupDatasets.journeys];
    final journeys = <Journey>[
      for (final raw in (journeyRows ?? const []))
        ?BackupCodec.decodeJourney(Map<String, Object?>.from(raw)),
    ];
    // Optional dataset (WTM-190): absent is normal. An unrecognised reaction
    // code is dropped, not defaulted — defaulting would either resurrect
    // something the seller dismissed or hide something they saved.
    final reactionRows = payload.datasets[BackupDatasets.opportunityReactions];
    final reactions = Map<String, OpportunityReaction>.fromEntries([
      for (final raw in (reactionRows ?? const []))
        ?BackupCodec.decodeOpportunityReaction(Map<String, Object?>.from(raw)),
    ]);
    return BackupContents(
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      transactions: transactions,
      favourites: favourites,
      businessProfile: profile,
      journeys: journeys,
      opportunityReactions: reactions,
    );
  }

  /// Duplicate ids, foreign keys and declared-vs-parsed counts.
  ///
  /// The foreign-key check matters more here than anywhere else in the app: on
  /// the real database `orders.customer_id` is enforced, so an order pointing
  /// at a missing customer would abort the restore transaction **after** the
  /// wipe. Catching it up front turns a scary rollback into a clean refusal.
  void _checkIntegrity(
    BackupContents contents,
    Map<String, int> declared,
    List<BackupIssue> issues,
  ) {
    void duplicates<T>(String dataset, List<T> rows, String Function(T) idOf) {
      final seen = <String>{};
      for (final row in rows) {
        if (!seen.add(idOf(row))) {
          issues.add(
            BackupIssue(
              BackupProblem.duplicateId,
              dataset: dataset,
              detail: 'id repeated',
            ),
          );
          return;
        }
      }
    }

    duplicates(BackupDatasets.customers, contents.customers, (c) => c.id);
    duplicates(BackupDatasets.products, contents.products, (p) => p.id);
    duplicates(BackupDatasets.orders, contents.orders, (o) => o.id);
    duplicates(BackupDatasets.goals, contents.goals, (g) => g.id);
    duplicates(BackupDatasets.transactions, contents.transactions, (t) => t.id);
    duplicates(
      BackupDatasets.favourites,
      contents.favourites,
      (f) => f.supplierId,
    );

    final customerIds = {for (final c in contents.customers) c.id};
    for (final order in contents.orders) {
      if (!customerIds.contains(order.customerId)) {
        issues.add(
          const BackupIssue(
            BackupProblem.brokenForeignKey,
            dataset: BackupDatasets.orders,
            detail: 'order references a customer the backup does not contain',
          ),
        );
        break;
      }
    }

    final parsed = contents.counts;
    for (final entry in parsed.entries) {
      final declaredCount = declared[entry.key];
      if (declaredCount != entry.value) {
        issues.add(
          BackupIssue(
            BackupProblem.countMismatch,
            dataset: entry.key,
            detail: 'declared $declaredCount, parsed ${entry.value}',
          ),
        );
      }
    }
  }

  // ── restore ──────────────────────────────────────────────────────────────

  /// Replaces the business with [validation]'s snapshot, atomically.
  ///
  /// Refuses unless the file already validated. Builds and **verifies** a
  /// safety backup of the current state first: if that cannot be written and
  /// read back as a restorable backup, nothing is deleted (Founder rule).
  Future<BackupRestoreReport> restore(BackupValidation validation) async {
    final contents = validation.contents;
    if (!validation.isRestorable || contents == null) {
      throw BackupRestoreException(
        validation.firstProblem,
        'refusing to restore a file that did not validate',
      );
    }

    final before = await _readCurrentContents();
    final safetyPath = await _writeVerifiedSafetyBackup(before);

    try {
      await repositories.database.transaction(() async {
        // Orders first: `orders.customer_id` is a foreign key, so customers
        // cannot be deleted while their orders exist (SqliteException 787 —
        // the same constraint that once crashed "Reset sample data").
        await repositories.orders.deleteAll();
        await repositories.customers.deleteAll();
        await repositories.products.deleteAll();
        await repositories.goals.deleteAll();
        await repositories.finance.deleteAll();
        await repositories.favourites.deleteAll();
        // Replace means replace (ADR-TON-018): the incoming business's profile
        // wins, and a package without one leaves the profile empty rather than
        // keeping the previous business's answers — otherwise a restored
        // business would carry the old owner's trade and channels.
        await repositories.businessProfile?.deleteAll();
        await repositories.journeys?.deleteAll();
        await repositories.opportunityReactions?.deleteAll();

        // …and back in dependency order: a customer must exist before an order
        // may reference it.
        await repositories.customers.upsertAll(contents.customers);
        await repositories.products.upsertAll(contents.products);
        await repositories.orders.upsertAll(contents.orders);
        await repositories.goals.upsertAll(contents.goals);
        await repositories.finance.addAll(contents.transactions);
        for (final favourite in contents.favourites) {
          await repositories.favourites.add(
            favourite.supplierId,
            addedAt: favourite.addedAt,
          );
        }
        for (final journey in contents.journeys) {
          await repositories.journeys?.save(journey);
        }
        await repositories.opportunityReactions?.replaceAll(
          contents.opportunityReactions,
        );
        final profile = contents.businessProfile;
        if (profile != null && profile.isNotEmpty) {
          await repositories.businessProfile?.save(
            profile,
            now: profile.updatedAt,
          );
        }

        // Verify INSIDE the transaction: a count that does not match means the
        // write did not land, and throwing here rolls the whole thing back
        // instead of leaving a half-restored business.
        final applied = await _readCurrentContents();
        final expected = contents.counts;
        final actual = applied.counts;
        for (final entry in expected.entries) {
          if (actual[entry.key] != entry.value) {
            throw BackupRestoreException(
              null,
              'verification failed for ${entry.key}: '
              'expected ${entry.value}, found ${actual[entry.key]}',
            );
          }
        }
        final restoredCustomerIds = {for (final c in applied.customers) c.id};
        for (final order in applied.orders) {
          if (!restoredCustomerIds.contains(order.customerId)) {
            throw const BackupRestoreException(
              BackupProblem.brokenForeignKey,
              'restored order lost its customer',
            );
          }
        }
      });
    } on Object {
      // The transaction rolled back; the database is exactly as it was. Let
      // the failure travel — the caller classifies it through ADR-TON-017.
      rethrow;
    }

    return BackupRestoreReport(
      restored: contents.counts,
      safetyBackupPath: safetyPath,
      replacedCounts: before.counts,
    );
  }

  /// Writes the pre-restore snapshot and reads it back through the **same
  /// validator a user's file goes through**. A safety backup nobody can
  /// restore is not a safety backup.
  Future<String> _writeVerifiedSafetyBackup(BackupContents before) async {
    final String armored;
    final String path;
    try {
      armored = await encodeContents(before);
      path = await vault.write(_safetyBackupName(), armored);
    } on Object catch (error) {
      throw BackupRestoreException(
        null,
        'safety backup could not be created ($error)',
      );
    }
    final String readBack;
    try {
      readBack = await vault.read(path);
    } on Object catch (error) {
      throw BackupRestoreException(
        null,
        'safety backup could not be read back ($error)',
      );
    }
    final check = await validate(readBack);
    if (!check.isRestorable ||
        !mapEquals(check.contents!.counts, before.counts)) {
      throw const BackupRestoreException(
        null,
        'safety backup did not verify — refusing to replace anything',
      );
    }
    return path;
  }

  String _safetyBackupName() {
    final now = clock();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'tongtai-truoc-khi-khoi-phuc-'
        '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.ttbk';
  }
}
