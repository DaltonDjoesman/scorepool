import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void navigateBack(BuildContext context, {required String fallback}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}
