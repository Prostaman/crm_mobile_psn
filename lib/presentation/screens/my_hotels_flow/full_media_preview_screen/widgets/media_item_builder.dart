import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/presentation/items/loading_indicator.dart';
import 'package:video_player/video_player.dart';

Widget buildMediaItem(FileModel fileModel) {
  final file = File(fileModel.localPath);

  final key = ValueKey(
    fileModel.localId > 0 ? "${fileModel.localId}" : "${fileModel.localPath}",
  );

  if (!file.existsSync()) {
    return const SizedBox();
  }

  if (fileModel.type == FileModelType.Image) {
    return Image.file(file, key: key);
  } else {
    return ChewieDemo(file: fileModel, key: key);
  }
}

class ChewieDemo extends StatefulWidget {
  final FileModel file;

  ChewieDemo({required this.file, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _controller = VideoPlayerController.file(File(widget.file.localPath));

    await _controller?.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      aspectRatio: _controller?.value.aspectRatio,
      autoPlay: true,
      looping: false,
      placeholder: Center(
        child: Container(
          height: 40,
          width: 40,
          child: LoadingIndicatorWidget(),
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(
                controller: _chewieController!,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading'),
                ],
              ),
      ),
    );
  }
}
