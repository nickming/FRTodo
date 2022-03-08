import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//国际化
//引入intl包并开启flutter generate功能
//配置l10n.yaml路径和模板代码，配置arb文件
//build生成flutter_gen文件下的localizations文件
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
