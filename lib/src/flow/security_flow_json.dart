import 'dart:convert';

import 'security_flow_response.dart';

SecurityFlowResponse securityFlowResponseFromJsonString(String source) {
  final map = jsonDecode(source) as Map<String, dynamic>;
  return SecurityFlowResponse.fromJson(map);
}
