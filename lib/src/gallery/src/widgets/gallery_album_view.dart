import 'dart:typed_data';

import 'package:likk_picker/likk_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../controllers/gallery_repository.dart';
import '../gallery_view.dart';
import 'gallery_permission_view.dart';

///
class GalleryAlbumView extends StatelessWidget {
  ///
  const GalleryAlbumView({
    Key? key,
    required this.controller,
    required this.onAlbumChange,
    required this.albumsNotifier,
  }) : super(key: key);

  ///
  final GalleryController controller;

  ///
  final ValueSetter<AssetPathEntity> onAlbumChange;

  ///
  final ValueNotifier<AlbumsType> albumsNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AlbumsType>(
      valueListenable: albumsNotifier,
      builder: (context, state, child) {
        // Loading
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error
        if (state.hasError) {
          if (!state.hasPermission) {
            return const GalleryPermissionView();
          }
          return Container(
            alignment: Alignment.center,
            color: Colors.black,
            child: Text(
              state.error ?? 'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        if (state.data?.isEmpty ?? true) {
          return Container(
            alignment: Alignment.center,
            color: Colors.black,
            child: const Text(
              'No data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        // Album list
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: controller.setting.albumBackground,
            ),
            CupertinoScrollbar(
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).padding.top + controller.headerSetting.headerMaxHeight),
                itemCount: state.data!.length,
                itemBuilder: (context, index) {
                  final entity = state.data![index];
                  return Album(
                    panelSetting: controller.panelSetting,
                    setting: controller.setting,
                    entity: entity,
                    onPressed: onAlbumChange,
                    color: controller.setting.albumColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class Album extends StatefulWidget {
  final AssetPathEntity entity;
  final PanelSetting panelSetting;
  final GallerySetting setting;
  final Color color;
  final Function(AssetPathEntity album)? onPressed;
  const Album({
    Key? key,
    required this.entity,
    required this.panelSetting,
    required this.setting,
    this.onPressed,
    this.color = Colors.grey,
  }) : super(key: key);

  @override
  State<Album> createState() => _AlbumState();
}

class _AlbumState extends State<Album> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    getAssetCount();
  }

  void getAssetCount() async {
    var count = await widget.entity.assetCountAsync;
    setState(() {
      _count = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: omit_local_variable_types
    final int imageSize = widget.setting.albumImageSize ?? 48;
    return ColoredBox(
      color: widget.color,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onPressed: () {
          widget.onPressed?.call(widget.entity);
        },
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: widget.setting.albumBorderRadius ?? BorderRadius.circular(8),
              child: Container(
                height: imageSize.toDouble(),
                width: imageSize.toDouble(),
                color: Colors.grey,
                child: FutureBuilder<List<AssetEntity>>(
                  future: widget.entity.getAssetListPaged(page: 0, size: 1),
                  builder: (context, listSnapshot) {
                    if (listSnapshot.connectionState == ConnectionState.done && (listSnapshot.data?.isNotEmpty ?? false)) {
                      return FutureBuilder<Uint8List?>(
                        future: listSnapshot.data!.first.thumbnailDataWithSize(ThumbnailSize(imageSize.toInt() * 5, imageSize.toInt() * 5)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }

                          return const SizedBox();
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),

            const SizedBox(width: 16.0),

            // Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album name
                  Text(
                    widget.entity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ).merge(widget.setting.albumTitleStyle),
                  ),
                  const SizedBox(height: 4.0),
                  // Total photos
                  Text(
                    _count.toString(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13.0,
                    ).merge(widget.setting.albumSubTitleStyle),
                  ),
                ],
              ),
            ),

            //
          ],
        ),
      ),
    );
  }
}
