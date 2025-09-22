import 'package:flutter/material.dart';

class VideoDetailScreen extends StatelessWidget {
  final String videoId;

  const VideoDetailScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('비디오 상세 ($videoId)'),
      ),
      body: Center(
        child: Text(
          '이곳은 비디오 상세 페이지입니다.\n비디오 ID: $videoId',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
