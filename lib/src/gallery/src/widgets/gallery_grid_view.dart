import 'dart:typed_data';

import 'package:likk_picker/likk_picker.dart';
import 'package:likk_picker/src/animations/animations.dart';
import 'package:likk_picker/src/slidable_panel/slidable_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../controllers/gallery_repository.dart';
import '../entities/gallery_value.dart';
import '../gallery_view.dart';
import 'gallery_permission_view.dart';

///
class GalleryGridView extends StatelessWidget {
  ///
  const GalleryGridView({
    Key? key,
    required this.controller,
    required this.onCameraRequest,
    required this.onSelect,
    required this.entitiesNotifier,
    required this.panelController,
  }) : super(key: key);

  ///
  final GalleryController controller;

  ///
  final ValueSetter<BuildContext> onCameraRequest;

  ///
  final void Function(LikkEntity, BuildContext) onSelect;

  ///
  final ValueNotifier<EntitiesType> entitiesNotifier;

  ///
  final PanelController panelController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: controller.panelSetting.background,
        ),
        ClipRRect(
          borderRadius: controller.setting.itemBorderRadius ?? BorderRadius.zero,
          child: ValueListenableBuilder<EntitiesType>(
            valueListenable: entitiesNotifier,
            builder: (context, state, child) {
              // Error
              if (state.hasError) {
                if (!state.hasPermission) {
                  return const GalleryPermissionView();
                }
              }

              // // No data
              // if (!state.isLoading && (state.data?.isEmpty ?? true)) {
              //   return const Center(
              //     child: Text(
              //       'No media available',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.w700,
              //       ),
              //     ),
              //   );
              // }

              final entities = state.isLoading ? <AssetEntity>[] : state.data!;

              final itemCount = state.isLoading
                  ? 20
                  : controller.setting.enableCamera
                      ? entities.length + 1
                      : entities.length;

              return CupertinoScrollbar(
                controller: panelController.scrollController,
                child: GridView.builder(
                  controller: panelController.scrollController,
                  padding: (controller.setting.padding ?? EdgeInsets.zero).add(EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  )),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: controller.setting.crossAxisCount ?? 3,
                    crossAxisSpacing: controller.setting.space ?? 4,
                    mainAxisSpacing: controller.setting.space ?? 4,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (controller.setting.enableCamera && index == 0) {
                      return ClipRRect(
                        borderRadius: controller.setting.itemBorderRadius ?? BorderRadius.zero,
                        child: GestureDetector(
                          onTap: () => onCameraRequest(context),
                          child: controller.setting.cameraItemWidget ??
                              const ColoredBox(
                                color: Color(0xFF16171B),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.photo_camera_solid,
                                      color: Color(0xFFAEB6BF),
                                      size: 36,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '카메라',
                                      style: TextStyle(
                                        color: Color(0xFFAEB6BF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        letterSpacing: -0.14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      );
                    }

                    final ind = controller.setting.enableCamera ? index - 1 : index;

                    final entity = state.isLoading ? null : entities[ind];

                    return ClipRRect(
                      borderRadius: controller.setting.itemBorderRadius ?? BorderRadius.zero,
                      child: _MediaTile(
                        controller: controller,
                        entity: entity,
                        onPressed: (entity) {
                          onSelect(entity, context);
                        },
                      ),
                    );
                  },
                ),
              );

              //
            },
          ),
        )
      ],
    );
  }
}

///
class _MediaTile extends StatelessWidget {
  ///
  const _MediaTile({
    Key? key,
    required this.entity,
    required this.controller,
    required this.onPressed,
  }) : super(key: key);

  ///
  final GalleryController controller;

  ///
  final AssetEntity? entity;

  ///
  final ValueSetter<LikkEntity> onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade800,
      child: FutureBuilder<Uint8List?>(
        future: Future<Uint8List?>.delayed(
          const Duration(milliseconds: 500),
          () => entity?.thumbnailDataWithSize(ThumbnailSize(400, 400)),
        ),
        builder: (context, snapshot) {
          final hasData = snapshot.connectionState == ConnectionState.done && snapshot.data != null;
          if (hasData) {
            final dEntity = LikkEntity(entity: entity!, bytes: snapshot.data!);
            return GestureDetector(
              onTap: () {
                onPressed(dEntity);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),

                  // Duration
                  if (entity!.type == AssetType.video)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _VideoDuration(duration: entity!.duration),
                    ),

                  // Image selection overlay
                  Positioned.fill(
                    child: _SelectionCount(controller: controller, entity: dEntity),
                  ),

                  //
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _VideoDuration extends StatelessWidget {
  const _VideoDuration({
    Key? key,
    required this.duration,
  }) : super(key: key);

  final int duration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          child: Text(
            duration.formatedDuration,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionCount extends StatelessWidget {
  const _SelectionCount({
    Key? key,
    required this.controller,
    required this.entity,
  }) : super(key: key);

  final GalleryController controller;
  final LikkEntity entity;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GalleryValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final isSelected = value.selectedEntities.contains(entity);
        // if (!isSelected) return const SizedBox();
        final index = value.selectedEntities.indexOf(entity);

        final crossFadeState = isSelected ? CrossFadeState.showFirst : CrossFadeState.showSecond;

        final selectionColor = controller.setting.selectionCountBackgroundColor ?? const Color(0xFF0079EE);
        final circleSize = (controller.setting.selectionCountBackgroundSize ?? 10) * 2;
        final margin = controller.setting.selectionCountMargin ?? const EdgeInsets.all(10);

        final Widget countBadge = Align(
          alignment: controller.setting.selectionCountAlignment,
          child: Padding(
            padding: margin,
            child: controller.setting.selectionCountBuilder != null
                ? controller.setting.selectionCountBuilder!(index)
                : Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: ShapeDecoration(
                      color: selectionColor,
                      shape: const OvalBorder(),
                    ),
                    alignment: Alignment.center,
                    child: controller.setting.maximum == 1
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: controller.setting.selectionCountTextStyle ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  letterSpacing: -0.24,
                                ),
                          ),
                  ),
          ),
        );

        final firstChild = index == -1
            ? const SizedBox.expand()
            : controller.setting.selectedStyle == SelectedStyle.border
                ? SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectionColor,
                          width: 2,
                        ),
                        borderRadius: controller.setting.itemBorderRadius ?? BorderRadius.zero,
                      ),
                      child: countBadge,
                    ),
                  )
                : SizedBox.expand(
                    child: ColoredBox(
                      color: selectionColor.withOpacity(0.2),
                      child: countBadge,
                    ),
                  );

        final unselectedChild = SizedBox.expand(
          child: Align(
            alignment: controller.setting.selectionCountAlignment,
            child: Padding(
              padding: margin,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const ShapeDecoration(
                  shape: OvalBorder(
                    side: BorderSide(width: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );

        return AppAnimatedCrossFade(
          firstChild: firstChild,
          secondChild: unselectedChild,
          crossFadeState: crossFadeState,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}

///
extension on int {
  String get formatedDuration {
    final duration = Duration(seconds: this);
    final min = duration.inMinutes.remainder(60).toString();
    final sec = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
