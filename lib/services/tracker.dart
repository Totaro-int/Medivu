// lib/services/tracker.dart
import 'dart:math';

class Track {
  int id;
  List<double> box; // [x,y,w,h]
  int age;
  Track(this.id, this.box, this.age);
}

class IouTracker {
  final double iouThresh;
  final int maxAge;
  int _nextId = 1;
  List<Track> _tracks = [];

  IouTracker({this.iouThresh = 0.5, this.maxAge = 10});

  List<Track> update(List<List<double>> detections) {
    // detections: [[x,y,w,h,score], ...]
    // Age all tracks
    for (final t in _tracks) { t.age += 1; }

    // Greedy IOU match
    final usedDet = Set<int>();
    for (final t in _tracks) {
      double bestIou = 0.0;
      int bestJ = -1;
      for (int j=0;j<detections.length;j++) {
        if (usedDet.contains(j)) continue;
        final i = _iou(t.box, detections[j].sublist(0,4));
        if (i > bestIou) { bestIou = i; bestJ = j; }
      }
      if (bestIou >= iouThresh && bestJ >= 0) {
        t.box = detections[bestJ].sublist(0,4);
        t.age = 0;
        usedDet.add(bestJ);
      }
    }

    // New tracks for unmatched detections
    for (int j=0;j<detections.length;j++) {
      if (!usedDet.contains(j)) {
        _tracks.add(Track(_nextId++, detections[j].sublist(0,4), 0));
      }
    }

    // Remove old tracks
    _tracks = _tracks.where((t)=> t.age <= maxAge).toList();
    return _tracks;
  }

  double _iou(List<double> a, List<double> b) {
    final ax1=a[0], ay1=a[1], ax2=a[0]+a[2], ay2=a[1]+a[3];
    final bx1=b[0], by1=b[1], bx2=b[0]+b[2], by2=b[1]+b[3];
    final ix1 = max(ax1, bx1), iy1 = max(ay1, by1);
    final ix2 = min(ax2, bx2), iy2 = min(ay2, by2);
    final iw = max(0.0, ix2 - ix1), ih = max(0.0, iy2 - iy1);
    final inter = iw * ih;
    final uni = (ax2-ax1)*(ay2-ay1) + (bx2-bx1)*(by2-by1) - inter;
    if (uni <= 0) return 0.0;
    return inter/uni;
  }
}
