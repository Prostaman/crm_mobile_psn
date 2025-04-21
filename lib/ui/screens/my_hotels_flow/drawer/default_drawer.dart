import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/helpers/webview_helper.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/routes/hotel_routes.dart';

import 'web_view/web_view_page.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback setStateCallback;
  final ChromeSafariBrowser browser = MyChromeSafariBrowser(MyInAppBrowser());
  AppDrawer({required this.setStateCallback});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      color: Colors.white,
      child: Drawer(
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 32),
              _createHeader(context),
              Divider(color: ColorDivider),

              _createDrawerItemWithCustomIcon(
                icon: IMG.icons.drawerMyHotelPNG,
                text: 'Мои отели',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _createDrawerItemWithCustomIcon(
                icon: IMG.icons.iconSettings,
                text: 'Настройки',
                onTap: () {
                  pushToHotelSettings(context: context, setStateCallback: setStateCallback);
                },
              ),

              // must be on the bottom
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end, // Align children to the bottom
                      children: [
                    Divider(color: ColorDivider),
                    _createDrawerItemWithCustomIcon(
                      icon: IMG.icons.drawerTermsPNG,
                      text: 'Условия использования',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await browser.open(
                              url: WebUri('https://www.poehalisnami.ua/user_agreement'),
                              settings: ChromeSafariBrowserSettings(
                                shareState: CustomTabsShareState.SHARE_STATE_ON,
                                barCollapsingEnabled: true,
                              ));
                        } catch (e) {
                          debugPrint("Failed to open Chrome Custom Tabs. Opening WebView instead.");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: "https://www.poehalisnami.ua/user_agreement",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _createDrawerItemWithCustomIcon(
                      icon: IMG.icons.drawerPolicyPNG,
                      text: 'Политика конфиденциальности',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await browser.open(
                              url: WebUri("https://www.poehalisnami.ua/privacy"),
                              settings: ChromeSafariBrowserSettings(
                                shareState: CustomTabsShareState.SHARE_STATE_OFF,
                                barCollapsingEnabled: true,
                              ));
                        } catch (e) {
                          //print("Failed to open Chrome Custom Tabs. Opening WebView instead.");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: "https://www.poehalisnami.ua/privacy",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _createDrawerLogout(
                      icon: IMG.icons.drawerLogoutPNG,
                      text: 'Выход',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              surfaceTintColor: Colors.white,
                              insetPadding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              content: Container(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 16),
                                    Text(
                                      "Вы уверенны что хотите выйти?",
                                      style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 26),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("Нет", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ServiceContainer().sinkService.connectivity.cancel();
                                              ServiceContainer().authService.logout();
                                            },
                                            child: Text("Да", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 32),
                      child: Text(
                        "v. ${ServiceContainer().settingsService.version}",
                        textAlign: TextAlign.start,
                        style: textStyle(
                          color: Color.fromRGBO(108, 106, 106, 1),
                          size: 12,
                        ),
                      ),
                    )
                  ]))
            ],
          ),
        ),
      ),
    );
  }

  Widget _createHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          IMG.icons.noAvatarPNG,
          width: 29,
          height: 29,
          fit: BoxFit.scaleDown,
        ),
        SizedBox(width: 8),
        Text(
          ServiceContainer().authService.user?.userName ?? "No name",
          style: textStyle(weight: Medium5, size: 16),
        ),
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: SvgPicture.asset(IMG.icons.iconClose, fit: BoxFit.scaleDown),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(width: 16)
          ],
        ))
      ],
    )
        // ),
        ;
  }

  Widget _createDrawerItemWithCustomIcon({required String icon, String? text, GestureTapCallback? onTap}) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Row(
            children: <Widget>[
              SvgPicture.asset(icon, width: 24, height: 24, fit: BoxFit.scaleDown),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    text ?? "Empty",
                    style: textStyle(),
                  ),
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
        Divider(color: ColorDivider),
      ],
    );
  }

  Widget _createDrawerLogout({required String icon, String? text, GestureTapCallback? onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          SvgPicture.asset(icon, width: 24, height: 24, fit: BoxFit.scaleDown),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              text ?? "Empty",
              style: textStyle(
                color: ColorOrange,
              ),
            ),
          )
        ],
      ),
      onTap: onTap,
    );
  }
}
