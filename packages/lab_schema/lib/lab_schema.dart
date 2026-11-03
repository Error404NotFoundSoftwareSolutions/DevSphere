// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
// Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
// Implemented here: manifest validation: the app uses it before opening a lab (FR-CAT-002/003); labcheck mirrors it in Python

library lab_schema;

import 'dart:convert';
import 'package:json_schema/json_schema.dart';

class ValidationResult {
  final bool ok;
  final List<String> errors;

  const ValidationResult._({required this.ok, required this.errors});

  factory ValidationResult.success() => const ValidationResult._(ok: true, errors: []);
  factory ValidationResult.failure(List<String> errors) =>
      ValidationResult._(ok: false, errors: errors);
}

JsonSchema? _cachedSchema;

JsonSchema getManifestJsonSchema(String schemaJson) {
  _cachedSchema ??= JsonSchema.create(jsonDecode(schemaJson));
  return _cachedSchema!;
}

ValidationResult validateManifest(dynamic manifest, {String? schemaContent}) {
  if (manifest is! Map<String, dynamic>) {
    return ValidationResult.failure(['Manifest must be a JSON object']);
  }

  // Unsupported versions get a clear message instead of a silent failure (FR-CAT-003).
  final v = manifest['schema_version'];
  if (v != 1) {
    return ValidationResult.failure([
      'This lab needs a newer app version (schema_version $v). Please update the app.',
    ]);
  }

  if (schemaContent != null) {
    final schema = getManifestJsonSchema(schemaContent);
    final result = schema.validate(manifest);
    if (!result.isValid) {
      final errors = result.errors.map((e) => '${e.instancePath} ${e.message}').toList();
      return ValidationResult.failure(errors);
    }
  }

  return ValidationResult.success();
}

// Rubric weights must add up to max_points (FR-CONT-002).
bool checkPointsTotal(Map<String, dynamic> manifest) {
  final evaluation = manifest['evaluation'];
  if (evaluation is! Map<String, dynamic>) return false;
  final maxPoints = evaluation['max_points'];
  final checks = evaluation['checks'];
  if (maxPoints is! num || checks is! List) return false;

  num sum = 0;
  for (final check in checks) {
    if (check is Map<String, dynamic> && check['points'] is num) {
      sum += check['points'] as num;
    }
  }
  return sum == maxPoints;
}

