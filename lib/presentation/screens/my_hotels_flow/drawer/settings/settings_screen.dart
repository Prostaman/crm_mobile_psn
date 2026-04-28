import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/settings/settings_cubit.dart';
import 'package:psn.hotels.hub/blocks/settings/settings_state.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: BlocBuilder<SettingsCubit, BaseCubitState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();

          // Приводим состояние к SettingsState.
          // Если это ErrorState или другое, используем значения по умолчанию,
          // но в идеале SettingsCubit всегда держит SettingsState.
          final settingsState = state is SettingsState
              ? state
              : SettingsState(
                  wifiEnabled: cubit.state is SettingsState
                      ? (cubit.state as SettingsState).wifiEnabled
                      : false,
                  qualityIndex: cubit.state is SettingsState
                      ? (cubit.state as SettingsState).qualityIndex
                      : 0,
                );

          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Настройки',
                    style: textStyle(size: 22, weight: Semibold6),
                  ),
                  centerTitle: true,
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Divider(color: ColorDivider),
                      Row(
                        children: [
                          Text(
                            "Загрузка только по WI-FI",
                            style: textStyle(),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Switch(
                                  value: settingsState.wifiEnabled,
                                  activeThumbColor: ColorGreen,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor:
                                      const Color.fromRGBO(217, 217, 217, 1),
                                  trackOutlineColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (settingsState.wifiEnabled) {
                                      return applyOpacity(Colors.green, 0.5);
                                    } else {
                                      return const Color.fromRGBO(
                                          217, 217, 217, 1);
                                    }
                                  }),
                                  onChanged: (newValue) =>
                                      cubit.toggleWifi(newValue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: ColorDivider),
                      Text("Качество фото:", style: textStyle(size: 16.0)),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color.fromRGBO(245, 245, 245, 1),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              _buildQualityButton(
                                  context, 0, '720p', settingsState),
                              _buildQualityButton(
                                  context, 1, '1080p', settingsState),
                              _buildQualityButton(
                                  context, 2, '2160p', settingsState),
                              _buildQualityButton(
                                  context, 3, 'max', settingsState),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      InkWell(
                        onTap: () => _showDeleteDialog(context, cubit),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              IMG.icons.iconDelete,
                              fit: BoxFit.scaleDown,
                              width: 18,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.red, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Удалить все медиафайлы",
                              style: textStyle(
                                  size: 16,
                                  weight: Regular4,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQualityButton(
      BuildContext context, int index, String text, SettingsState state) {
    final bool isSelected = state.qualityIndex == index;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: isSelected ? ColorTextOrange : null,
        ),
        child: TextButton(
          onPressed: () => context.read<SettingsCubit>().setQuality(index),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : ColorTextOrange,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SettingsCubit cubit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(28),
          title: Text(
            "Будут удалены все медиафайлы, которые отгрузились на сервер.\n\nВы уверены что хотите их удалить?\n",
            style: textStyle(
                size: 18,
                weight: FontWeight.w300,
                color: ColorTextBlackAlertDialog),
          ),
          surfaceTintColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Отменить",
                style: textStyle(
                    size: 18,
                    weight: FontWeight.w400,
                    color: ColorTextBlackAlertDialog),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cubit.clearSyncedMedia();
              },
              child: Text(
                "Да, удалить",
                style: textStyle(
                    size: 18, weight: FontWeight.w400, color: ColorTextOrange),
              ),
            ),
          ],
        );
      },
    );
  }
}
