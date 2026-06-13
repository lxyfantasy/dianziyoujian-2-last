import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/setting_widgets.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../common.dart';
import '../../common/widgets/dialog.dart';
import '../../common/widgets/login.dart';
import '../../consts.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';
import '../widgets/dialog.dart';
import 'home_page.dart';
import 'scan_page.dart';

class SettingsPage extends StatefulWidget implements PageShape {
  @override
  final title = "";// 2、去掉标题

  @override
  final icon = Icon(Icons.settings);

  @override
  final appBarActions = []; // 2、去掉二维码UI

  @override
  State<SettingsPage> createState() => _SettingsState();
}

const url = 'https://rustdesk.com/';

enum KeepScreenOn {
  never,
  duringControlled,
  serviceOn,
}

String _keepScreenOnToOption(KeepScreenOn value) {
  switch (value) {
    case KeepScreenOn.never:
      return 'never';
    case KeepScreenOn.duringControlled:
      return 'during-controlled';
    case KeepScreenOn.serviceOn:
      return 'service-on';
  }
}

KeepScreenOn optionToKeepScreenOn(String value) {
  switch (value) {
    case 'never':
      return KeepScreenOn.never;
    case 'service-on':
      return KeepScreenOn.serviceOn;
    default:
      return KeepScreenOn.duringControlled;
  }
}

class _SettingsState extends State<SettingsPage> with WidgetsBindingObserver {
  final _hasIgnoreBattery = false;
  var _ignoreBatteryOpt = false;
  var _enableStartOnBoot = true; // 4、开机自启默认打开
  var _checkUpdateOnStartup = false; // 5、更新检查默认关闭
  var _showTerminalExtraKeys = false;
  var _floatingWindowDisabled = true; // 6、悬浮窗默认关闭
  var _keepScreenOn = KeepScreenOn.duringControlled; // 7、默认被控期间
  var _enableAbr = false;
  var _denyLANDiscovery = false;
  var _onlyWhiteList = false;
  var _enableDirectIPAccess = true; // 3、IP直接访问默认打开
  var _enableRecordSession = false;
  var _enableHardwareCodec = false;
  var _allowWebSocket = false;
  var _autoRecordIncomingSession = false;
  var _autoRecordOutgoingSession = false;
  var _allowAutoDisconnect = false;
  var _localIP = "";
  var _directAccessPort = "";
  var _fingerprint = "";
  var _buildDate = "";
  var _autoDisconnectTimeout = "";
  var _hideServer = false;
  var _hideProxy = false;
  var _hideNetwork = false;
  var _hideWebSocket = false;
  var _enableTrustedDevices = false;
  var _enableUdpPunch = false;
  var _allowInsecureTlsFallback = false;
  var _disableUdp = false;
  var _enableIpv6Punch = false;
  var _isUsingPublicServer = false;
  var _allowAskForNoteAtEndOfConnection = false;
  var _preventSleepWhileConnected = true;

  _SettingsState() {
    _enableAbr = option2bool(kOptionEnableAbr, bind.mainGetOptionSync(key: kOptionEnableAbr));
    _denyLANDiscovery = !option2bool(kOptionEnableLanDiscovery, bind.mainGetOptionSync(key: kOptionEnableLanDiscovery));
    _onlyWhiteList = whitelistNotEmpty();
    _enableDirectIPAccess = true;
    _enableRecordSession = option2bool(kOptionEnableRecordSession, bind.mainGetOptionSync(key: kOptionEnableRecordSession));
    _enableHardwareCodec = option2bool(kOptionEnableHwcodec, bind.mainGetOptionSync(key: kOptionEnableHwcodec));
    _allowWebSocket = mainGetBoolOptionSync(kOptionAllowWebSocket);
    _allowInsecureTlsFallback = mainGetBoolOptionSync(kOptionAllowInsecureTLSFallback);
    _disableUdp = bind.mainGetOptionSync(key: kOptionDisableUdp) == 'Y';
    _autoRecordIncomingSession = option2bool(kOptionAllowAutoRecordIncoming, bind.mainGetOptionSync(key: kOptionAllowAutoRecordIncoming));
    _autoRecordOutgoingSession = option2bool(kOptionAllowAutoRecordOutgoing, bind.mainGetLocalOption(key: kOptionAllowAutoRecordOutgoing));
    _localIP = bind.mainGetOptionSync(key: 'local-ip-addr');
    _directAccessPort = bind.mainGetOptionSync(key: kOptionDirectAccessPort);
    _allowAutoDisconnect = option2bool(kOptionAllowAutoDisconnect, bind.mainGetOptionSync(key: kOptionAllowAutoDisconnect));
    _autoDisconnectTimeout = bind.mainGetOptionSync(key: kOptionAutoDisconnectTimeout);
    _hideServer = bind.mainGetBuildinOption(key: kOptionHideServerSetting) == 'Y';
    _hideProxy = bind.mainGetBuildinOption(key: kOptionHideProxySetting) == 'Y';
    _hideNetwork = bind.mainGetBuildinOption(key: kOptionHideNetworkSetting) == 'Y';
    _hideWebSocket = bind.mainGetBuildinOption(key: kOptionHideWebSocketSetting) == 'Y' || isWeb;
    _enableTrustedDevices = mainGetBoolOptionSync(kOptionEnableTrustedDevices);
    _enableUdpPunch = mainGetLocalBoolOptionSync(kOptionEnableUdpPunch);
    _enableIpv6Punch = mainGetLocalBoolOptionSync(kOptionEnableIpv6Punch);
    _allowAskForNoteAtEndOfConnection = mainGetLocalBoolOptionSync(kOptionAllowAskForNoteAtEndOfConnection);
    _preventSleepWhileConnected = mainGetLocalBoolOptionSync(kOptionKeepAwakeDuringOutgoingSessions);
    _showTerminalExtraKeys = mainGetLocalBoolOptionSync(kOptionEnableShowTerminalExtraKeys);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<bool> checkAndUpdateIgnoreBatteryStatus() async {
    return false;
  }

  Future<bool> checkAndUpdateStartOnBoot() async {
    return false;
  }

  // 只保留 登录/账户 UI，其余全部删除
  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    final settings = SettingsList(
      sections: [
        // 1、只保留账户分项
        SettingsSection(
          title: Text(translate('Account')),
          tiles: [
            SettingsTile(
              title: Obx(() => Text(gFFI.userModel.userName.value.isEmpty
                  ? translate('Login')
                  : '${translate('Logout')} (${gFFI.userModel.accountLabelWithHandle})')),
              leading: Obx(() {
                final avatar = bind.mainResolveAvatarUrl(avatar: gFFI.userModel.avatar.value);
                return buildAvatarWidget(avatar: avatar, size: 40) ?? Icon(Icons.person);
              }),
              onPressed: (context) {
                if (gFFI.userModel.userName.value.isEmpty) {
                  loginDialog();
                } else {
                  logOutConfirmDialog();
                }
              },
            ),
          ],
        ),
        // 新增：ID/中继服务器 单独一项，无其他网络/代理条目
        SettingsSection(
          title: Text(translate("Settings")),
          tiles: [
            if (!_hideNetwork && !_hideServer)
              SettingsTile(
                  title: Text(translate('ID/Relay Server')),
                  leading: Icon(Icons.cloud),
                  onPressed: (context) {
                    showServerSettings(gFFI.dialogManager, (callback) async {
                      _isUsingPublicServer = await bind.mainIsUsingPublicServer();
                      setState(callback);
                    });
                  }),
          ],
        ),
      ],
    );
  return settings;
}

  Future<bool> canStartOnBoot() async {
    return true;
  }

  defaultDisplaySection() {
    return Container();
  }
}

void showLanguageSettings(OverlayDialogManager dialogManager) async {}
void showThemeSettings(OverlayDialogManager dialogManager) async {}
void showAbout(OverlayDialogManager dialogManager) {}

class ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _DisplayPage extends StatefulWidget {
  const _DisplayPage();
  @override
  State<_DisplayPage> createState() => __DisplayPageState();
}
class __DisplayPageState extends State<_DisplayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Container());
  }
}

class _ManageTrustedDevices extends StatefulWidget {
  const _ManageTrustedDevices();
  @override
  State<_ManageTrustedDevices> createState() => __ManageTrustedDevicesState();
}
class __ManageTrustedDevicesState extends State<_ManageTrustedDevices> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Container());
  }
}

class _RadioEntry {
  final String label;
  final String value;
  _RadioEntry(this.label, this.value);
}

typedef _RadioEntryGetter = String Function();
typedef _RadioEntrySetter = Future<void> Function(String);

SettingsTile _getPopupDialogRadioEntry({
  required String title,
  required List<_RadioEntry> list,
  required _RadioEntryGetter getter,
  required _RadioEntrySetter? asyncSetter,
  Widget? tail,
  RxBool? showTail,
  String? notCloseValue,
}) {
  return SettingsTile(title: Text(""));
}