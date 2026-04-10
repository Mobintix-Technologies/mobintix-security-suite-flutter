import 'package:equatable/equatable.dart';

import '../models/security_flow_step_id.dart';
import '../models/security_step_config.dart';

class SecurityFlowResponse extends Equatable {
  const SecurityFlowResponse({
    required this.schemaVersion,
    this.flowId,
    required this.step,
    required this.config,
    this.themeJson,
  });

  final int schemaVersion;
  final String? flowId;
  final SecurityFlowStepId step;
  final SecurityStepConfig config;
  final Map<String, dynamic>? themeJson;

  factory SecurityFlowResponse.fromJson(Map<String, dynamic> json) {
    final raw =
        json['step'] as String? ?? json['currentStep'] as String? ?? '';
    final step = SecurityFlowStepId.parse(raw);
    final params = Map<String, dynamic>.from(json['params'] as Map? ?? {});
    return SecurityFlowResponse(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      flowId: json['flowId'] as String?,
      step: step,
      config: SecurityStepConfig.fromJson(step, params),
      themeJson: json['theme'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (flowId != null) 'flowId': flowId,
        'step': step.toApiValue(),
        'params': config.toJson(),
        if (themeJson != null) 'theme': themeJson,
      };

  @override
  List<Object?> get props => [schemaVersion, flowId, step, config, themeJson];
}
