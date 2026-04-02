// ===========================================================================
// medtermsv01 — Dart Data Models
// Generated from Supabase public schema
// All DateTime fields serialized as toIso8601String()
// Views (leaders, quiz_user) are read-only — fromJson() only
// ===========================================================================

// ---------------------------------------------------------------------------
// CategoryModel
// ---------------------------------------------------------------------------
class CategoryModel {
  final int catId;
  final DateTime createdAt;
  final String? category;
  final String? apptype;

  const CategoryModel({
    required this.catId,
    required this.createdAt,
    this.category,
    this.apptype,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      catId: json['cat_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] as String?,
      apptype: json['apptype'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cat_id': catId,
        'created_at': createdAt.toIso8601String(),
        'category': category,
        'apptype': apptype,
      };

  CategoryModel copyWith({
    int? catId,
    DateTime? createdAt,
    String? category,
    String? apptype,
  }) {
    return CategoryModel(
      catId: catId ?? this.catId,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      apptype: apptype ?? this.apptype,
    );
  }
}

// ---------------------------------------------------------------------------
// CountryModel
// ---------------------------------------------------------------------------
class CountryModel {
  final int id;
  final String? name;
  final String? iso2;
  final String? iso3;

  const CountryModel({
    required this.id,
    this.name,
    this.iso2,
    this.iso3,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      iso2: json['iso2'] as String?,
      iso3: json['iso3'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iso2': iso2,
        'iso3': iso3,
      };

  CountryModel copyWith({
    int? id,
    String? name,
    String? iso2,
    String? iso3,
  }) {
    return CountryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iso2: iso2 ?? this.iso2,
      iso3: iso3 ?? this.iso3,
    );
  }
}

// ---------------------------------------------------------------------------
// CustomerModel
// ---------------------------------------------------------------------------
class CustomerModel {
  final String? userId;
  final String lsCustomerId;
  final String email;

  const CustomerModel({
    this.userId,
    required this.lsCustomerId,
    required this.email,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      userId: json['user_id'] as String?,
      lsCustomerId: json['ls_customer_id'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'ls_customer_id': lsCustomerId,
        'email': email,
      };

  CustomerModel copyWith({
    String? userId,
    String? lsCustomerId,
    String? email,
  }) {
    return CustomerModel(
      userId: userId ?? this.userId,
      lsCustomerId: lsCustomerId ?? this.lsCustomerId,
      email: email ?? this.email,
    );
  }
}

// ---------------------------------------------------------------------------
// LeaderboardModel  (table — read/write)
// ---------------------------------------------------------------------------
class LeaderboardModel {
  final int id;
  final DateTime createdAt;
  final String displayName;
  final double secPerItem;
  final int noOfItems;
  final int noCorrect;
  final String? userId;

  const LeaderboardModel({
    required this.id,
    required this.createdAt,
    required this.displayName,
    required this.secPerItem,
    required this.noOfItems,
    required this.noCorrect,
    this.userId,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayName: json['display_name'] as String? ?? '',
      secPerItem: (json['sec_per_item'] as num?)?.toDouble() ?? 0.0,
      noOfItems: json['no_of_items'] as int? ?? 0,
      noCorrect: json['no_correct'] as int? ?? 0,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'display_name': displayName,
        'sec_per_item': secPerItem,
        'no_of_items': noOfItems,
        'no_correct': noCorrect,
        'user_id': userId,
      };

  LeaderboardModel copyWith({
    int? id,
    DateTime? createdAt,
    String? displayName,
    double? secPerItem,
    int? noOfItems,
    int? noCorrect,
    String? userId,
  }) {
    return LeaderboardModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      secPerItem: secPerItem ?? this.secPerItem,
      noOfItems: noOfItems ?? this.noOfItems,
      noCorrect: noCorrect ?? this.noCorrect,
      userId: userId ?? this.userId,
    );
  }
}

// ---------------------------------------------------------------------------
// LeadersModel  (VIEW — read-only, no toJson / copyWith)
// ---------------------------------------------------------------------------
class LeadersModel {
  final int? id;
  final DateTime? createdAt;
  final String? displayName;
  final double? secPerItem;
  final int? noOfItems;
  final int? noCorrect;
  final String? userId; // uuid as String — used to highlight current user

  const LeadersModel({
    this.id,
    this.createdAt,
    this.displayName,
    this.secPerItem,
    this.noOfItems,
    this.noCorrect,
    this.userId,
  });

  factory LeadersModel.fromJson(Map<String, dynamic> json) {
    return LeadersModel(
      id: json['id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      displayName: json['display_name'] as String?,
      secPerItem: (json['sec_per_item'] as num?)?.toDouble(),
      noOfItems: json['no_of_items'] as int?,
      noCorrect: json['no_correct'] as int?,
      userId: json['user_id'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// ModuleModel
// ---------------------------------------------------------------------------
class ModuleModel {
  final int modulesId;
  final DateTime createdAt;
  final int quizId;
  final String userId;
  final String? apptype;

  const ModuleModel({
    required this.modulesId,
    required this.createdAt,
    required this.quizId,
    required this.userId,
    this.apptype,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      modulesId: json['modules_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      quizId: json['quiz_id'] as int,
      userId: json['user_id'] as String,
      apptype: json['apptype'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'modules_id': modulesId,
        'created_at': createdAt.toIso8601String(),
        'quiz_id': quizId,
        'user_id': userId,
        'apptype': apptype,
      };

  ModuleModel copyWith({
    int? modulesId,
    DateTime? createdAt,
    int? quizId,
    String? userId,
    String? apptype,
  }) {
    return ModuleModel(
      modulesId: modulesId ?? this.modulesId,
      createdAt: createdAt ?? this.createdAt,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      apptype: apptype ?? this.apptype,
    );
  }
}

// ---------------------------------------------------------------------------
// OrderModel
// ---------------------------------------------------------------------------
class OrderModel {
  final int orderNumber;
  final String? userId;
  final String appSlug;
  final int? productId;
  final DateTime? createdAt;
  final String id; // uuid

  const OrderModel({
    required this.orderNumber,
    this.userId,
    required this.appSlug,
    this.productId,
    this.createdAt,
    required this.id,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNumber: json['order_number'] as int,
      userId: json['user_id'] as String?,
      appSlug: json['app_slug'] as String,
      productId: json['product_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_number': orderNumber,
        'user_id': userId,
        'app_slug': appSlug,
        'product_id': productId,
        'created_at': createdAt?.toIso8601String(),
        'id': id,
      };

  OrderModel copyWith({
    int? orderNumber,
    String? userId,
    String? appSlug,
    int? productId,
    DateTime? createdAt,
    String? id,
  }) {
    return OrderModel(
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      appSlug: appSlug ?? this.appSlug,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      id: id ?? this.id,
    );
  }
}

// ---------------------------------------------------------------------------
// ProductModel
// ---------------------------------------------------------------------------
class ProductModel {
  final String appSlug;
  final String productId;
  final String variantId;
  final String name;
  final String interval;
  final int? priceCents;
  final String? appType;

  const ProductModel({
    required this.appSlug,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.interval,
    this.priceCents,
    this.appType,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      appSlug: json['app_slug'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String,
      name: json['name'] as String,
      interval: json['interval'] as String,
      priceCents: json['price_cents'] as int?,
      appType: json['app_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'app_slug': appSlug,
        'product_id': productId,
        'variant_id': variantId,
        'name': name,
        'interval': interval,
        'price_cents': priceCents,
        'app_type': appType,
      };

  ProductModel copyWith({
    String? appSlug,
    String? productId,
    String? variantId,
    String? name,
    String? interval,
    int? priceCents,
    String? appType,
  }) {
    return ProductModel(
      appSlug: appSlug ?? this.appSlug,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      name: name ?? this.name,
      interval: interval ?? this.interval,
      priceCents: priceCents ?? this.priceCents,
      appType: appType ?? this.appType,
    );
  }
}

// ---------------------------------------------------------------------------
// QuizModel
// ---------------------------------------------------------------------------
class QuizModel {
  final int quizId;
  final DateTime createdAt;
  final String quizName;
  final int quizCount;
  final String? apptype;
  final bool sample;
  final String? price;
  final bool isRationale;
  final int? appId; // FK to app_id — used to filter modules per app flavor

  const QuizModel({
    required this.quizId,
    required this.createdAt,
    required this.quizName,
    required this.quizCount,
    this.apptype,
    required this.sample,
    this.price,
    required this.isRationale,
    this.appId,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quiz_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      quizName: json['quiz_name'] as String? ?? '',
      quizCount: json['quiz_count'] as int? ?? 0,
      apptype: json['apptype'] as String?,
      sample: json['sample'] as bool? ?? false,
      price: json['price'] as String?,
      isRationale: json['isRationale'] as bool? ?? false,
      appId: json['app_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'quiz_id': quizId,
        'created_at': createdAt.toIso8601String(),
        'quiz_name': quizName,
        'quiz_count': quizCount,
        'apptype': apptype,
        'sample': sample,
        'price': price,
        'isRationale': isRationale,
        'app_id': appId,
      };

  QuizModel copyWith({
    int? quizId,
    DateTime? createdAt,
    String? quizName,
    int? quizCount,
    String? apptype,
    bool? sample,
    String? price,
    bool? isRationale,
    int? appId,
  }) {
    return QuizModel(
      quizId: quizId ?? this.quizId,
      createdAt: createdAt ?? this.createdAt,
      quizName: quizName ?? this.quizName,
      quizCount: quizCount ?? this.quizCount,
      apptype: apptype ?? this.apptype,
      sample: sample ?? this.sample,
      price: price ?? this.price,
      isRationale: isRationale ?? this.isRationale,
      appId: appId ?? this.appId,
    );
  }
}

// ---------------------------------------------------------------------------
// QuizQuestModel
// ---------------------------------------------------------------------------
class QuizQuestModel {
  final int questId;
  final String? answer1;
  final String? answer2;
  final String? answer3;
  final String? answer4;
  final int? corrAns;
  final int? questNo;
  final String? questText;
  final int? quizId;
  final String? rationale;
  final String? category;

  const QuizQuestModel({
    required this.questId,
    this.answer1,
    this.answer2,
    this.answer3,
    this.answer4,
    this.corrAns,
    this.questNo,
    this.questText,
    this.quizId,
    this.rationale,
    this.category,
  });

  factory QuizQuestModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestModel(
      questId: json['quest_id'] as int,
      answer1: json['answer1'] as String?,
      answer2: json['answer2'] as String?,
      answer3: json['answer3'] as String?,
      answer4: json['answer4'] as String?,
      corrAns: json['corr_ans'] as int?,
      questNo: json['quest_no'] as int?,
      questText: json['quest_text'] as String?,
      quizId: json['quiz_id'] as int?,
      rationale: json['rationale'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'quest_id': questId,
        'answer1': answer1,
        'answer2': answer2,
        'answer3': answer3,
        'answer4': answer4,
        'corr_ans': corrAns,
        'quest_no': questNo,
        'quest_text': questText,
        'quiz_id': quizId,
        'rationale': rationale,
        'category': category,
      };

  QuizQuestModel copyWith({
    int? questId,
    String? answer1,
    String? answer2,
    String? answer3,
    String? answer4,
    int? corrAns,
    int? questNo,
    String? questText,
    int? quizId,
    String? rationale,
    String? category,
  }) {
    return QuizQuestModel(
      questId: questId ?? this.questId,
      answer1: answer1 ?? this.answer1,
      answer2: answer2 ?? this.answer2,
      answer3: answer3 ?? this.answer3,
      answer4: answer4 ?? this.answer4,
      corrAns: corrAns ?? this.corrAns,
      questNo: questNo ?? this.questNo,
      questText: questText ?? this.questText,
      quizId: quizId ?? this.quizId,
      rationale: rationale ?? this.rationale,
      category: category ?? this.category,
    );
  }
}

// ---------------------------------------------------------------------------
// QuizUserModel  (VIEW — read-only, no toJson / copyWith)
// ---------------------------------------------------------------------------
class QuizUserModel {
  final String? answer1;
  final String? answer2;
  final String? answer3;
  final String? answer4;
  final String? category;
  final int? corrAns;
  final int? questNo;
  final String? questText;
  final int? quizId;
  final bool? isComplete;
  final bool? isCorrect;
  final bool? isExpired;
  final int? userAnswer;
  final String? userId;
  final String? apptype;
  final String? rationale;

  const QuizUserModel({
    this.answer1,
    this.answer2,
    this.answer3,
    this.answer4,
    this.category,
    this.corrAns,
    this.questNo,
    this.questText,
    this.quizId,
    this.isComplete,
    this.isCorrect,
    this.isExpired,
    this.userAnswer,
    this.userId,
    this.apptype,
    this.rationale,
  });

  factory QuizUserModel.fromJson(Map<String, dynamic> json) {
    return QuizUserModel(
      answer1: json['answer1'] as String?,
      answer2: json['answer2'] as String?,
      answer3: json['answer3'] as String?,
      answer4: json['answer4'] as String?,
      category: json['category'] as String?,
      corrAns: json['corr_ans'] as int?,
      questNo: json['quest_no'] as int?,
      questText: json['quest_text'] as String?,
      quizId: json['quiz_id'] as int?,
      isComplete: json['is_complete'] as bool?,
      isCorrect: json['is_correct'] as bool?,
      isExpired: json['is_expired'] as bool?,
      userAnswer: json['user_answer'] as int?,
      userId: json['user_id'] as String?,
      apptype: json['apptype'] as String?,
      rationale: json['rationale'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// UserAnswerModel
// ---------------------------------------------------------------------------
class UserAnswerModel {
  final int usrAnsId;
  final int? corrAns;
  final bool isComplete;
  final bool isCorrect;
  final bool isExpired;
  final int? questNo;
  final int? quizId;
  final int userAnswer;
  final String? userId;
  final String? apptype;

  const UserAnswerModel({
    required this.usrAnsId,
    this.corrAns,
    required this.isComplete,
    required this.isCorrect,
    required this.isExpired,
    this.questNo,
    this.quizId,
    required this.userAnswer,
    this.userId,
    this.apptype,
  });

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) {
    return UserAnswerModel(
      usrAnsId: json['usr_ans_id'] as int,
      corrAns: json['corr_ans'] as int?,
      isComplete: json['is_complete'] as bool? ?? false,
      isCorrect: json['is_correct'] as bool? ?? false,
      isExpired: json['is_expired'] as bool? ?? false,
      questNo: json['quest_no'] as int?,
      quizId: json['quiz_id'] as int?,
      userAnswer: json['user_answer'] as int? ?? 0,
      userId: json['user_id'] as String?,
      apptype: json['apptype'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'usr_ans_id': usrAnsId,
        'corr_ans': corrAns,
        'is_complete': isComplete,
        'is_correct': isCorrect,
        'is_expired': isExpired,
        'quest_no': questNo,
        'quiz_id': quizId,
        'user_answer': userAnswer,
        'user_id': userId,
        'apptype': apptype,
      };

  UserAnswerModel copyWith({
    int? usrAnsId,
    int? corrAns,
    bool? isComplete,
    bool? isCorrect,
    bool? isExpired,
    int? questNo,
    int? quizId,
    int? userAnswer,
    String? userId,
    String? apptype,
  }) {
    return UserAnswerModel(
      usrAnsId: usrAnsId ?? this.usrAnsId,
      corrAns: corrAns ?? this.corrAns,
      isComplete: isComplete ?? this.isComplete,
      isCorrect: isCorrect ?? this.isCorrect,
      isExpired: isExpired ?? this.isExpired,
      questNo: questNo ?? this.questNo,
      quizId: quizId ?? this.quizId,
      userAnswer: userAnswer ?? this.userAnswer,
      userId: userId ?? this.userId,
      apptype: apptype ?? this.apptype,
    );
  }
}

// ---------------------------------------------------------------------------
// UserSummaryModel
// ---------------------------------------------------------------------------
class UserSummaryModel {
  final int summaryId;
  final DateTime createdAt;
  final String userId;
  final int quizId;
  final int noCompleted;
  final int noCorrect;
  final int noInQuiz;
  final int noExpired;
  final DateTime? lastAccessed;
  final int noPresent;
  final double durationSeconds;

  const UserSummaryModel({
    required this.summaryId,
    required this.createdAt,
    required this.userId,
    required this.quizId,
    required this.noCompleted,
    required this.noCorrect,
    required this.noInQuiz,
    required this.noExpired,
    this.lastAccessed,
    required this.noPresent,
    required this.durationSeconds,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      summaryId: json['summary_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      quizId: json['quiz_id'] as int,
      noCompleted: json['no_completed'] as int? ?? 0,
      noCorrect: json['no_correct'] as int? ?? 0,
      noInQuiz: json['no_in_quiz'] as int? ?? 500,
      noExpired: json['no_expired'] as int? ?? 0,
      lastAccessed: json['last_accessed'] != null
          ? DateTime.parse(json['last_accessed'] as String)
          : null,
      noPresent: json['no_present'] as int? ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'summary_id': summaryId,
        'created_at': createdAt.toIso8601String(),
        'user_id': userId,
        'quiz_id': quizId,
        'no_completed': noCompleted,
        'no_correct': noCorrect,
        'no_in_quiz': noInQuiz,
        'no_expired': noExpired,
        'last_accessed': lastAccessed?.toIso8601String(),
        'no_present': noPresent,
        'duration_seconds': durationSeconds,
      };

  UserSummaryModel copyWith({
    int? summaryId,
    DateTime? createdAt,
    String? userId,
    int? quizId,
    int? noCompleted,
    int? noCorrect,
    int? noInQuiz,
    int? noExpired,
    DateTime? lastAccessed,
    int? noPresent,
    double? durationSeconds,
  }) {
    return UserSummaryModel(
      summaryId: summaryId ?? this.summaryId,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      noCompleted: noCompleted ?? this.noCompleted,
      noCorrect: noCorrect ?? this.noCorrect,
      noInQuiz: noInQuiz ?? this.noInQuiz,
      noExpired: noExpired ?? this.noExpired,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      noPresent: noPresent ?? this.noPresent,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

// ---------------------------------------------------------------------------
// UserModel  (public.users — mirror of auth.users via trigger)
// ---------------------------------------------------------------------------
class UserModel {
  final DateTime createdAt;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final bool isPremium;
  final String userId; // uuid — FK to auth.users(id)
  final int lastQuestion;

  const UserModel({
    required this.createdAt,
    this.email,
    this.displayName,
    this.phoneNumber,
    required this.isPremium,
    required this.userId,
    required this.lastQuestion,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      createdAt: DateTime.parse(json['created_at'] as String),
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      userId: json['user_id'] as String,
      lastQuestion: json['lastquestion'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'email': email,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'is_premium': isPremium,
        'user_id': userId,
        'lastquestion': lastQuestion,
      };

  /// True if this user is the shared guest account.
  /// Guest users are limited to sample/free quizzes only.
  bool get isGuest => email == 'guest@rr.com';

  UserModel copyWith({
    DateTime? createdAt,
    String? email,
    String? displayName,
    String? phoneNumber,
    bool? isPremium,
    String? userId,
    int? lastQuestion,
  }) {
    return UserModel(
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPremium: isPremium ?? this.isPremium,
      userId: userId ?? this.userId,
      lastQuestion: lastQuestion ?? this.lastQuestion,
    );
  }
}

// ---------------------------------------------------------------------------
// VersionModel
// Simple two-column table. One row in DB stores the current live version.
// App compares stored version string against this to detect updates.
// ---------------------------------------------------------------------------
class VersionModel {
  final int id;
  final String version;

  const VersionModel({
    required this.id,
    required this.version,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      id: json['id'] as int,
      version: json['version'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
      };

  VersionModel copyWith({
    int? id,
    String? version,
  }) {
    return VersionModel(
      id: id ?? this.id,
      version: version ?? this.version,
    );
  }
}
