import 'dart:math' as math;

/// 기하학적 형태를 나타내는 모델들
class RectF {
  final double x, y, w, h;
  
  const RectF(this.x, this.y, this.w, this.h);
  
  /// 왼쪽 상단 좌표
  double get left => x;
  double get top => y;
  
  /// 오른쪽 하단 좌표
  double get right => x + w;
  double get bottom => y + h;
  
  /// 중심점
  double get centerX => x + w / 2;
  double get centerY => y + h / 2;
  
  /// 면적
  double get area => w * h;
  
  /// 다른 사각형과의 교집합
  RectF? intersect(RectF other) {
    final left = math.max(this.left, other.left);
    final top = math.max(this.top, other.top);
    final right = math.min(this.right, other.right);
    final bottom = math.min(this.bottom, other.bottom);
    
    if (left >= right || top >= bottom) {
      return null;
    }
    
    return RectF(left, top, right - left, bottom - top);
  }
  
  /// IoU (Intersection over Union) 계산
  double iou(RectF other) {
    final intersection = intersect(other);
    if (intersection == null) return 0.0;
    
    final unionArea = area + other.area - intersection.area;
    return unionArea > 0 ? intersection.area / unionArea : 0.0;
  }
  
  /// 정규화 (0~1 범위로)
  RectF normalize(double width, double height) {
    return RectF(
      x / width,
      y / height,
      w / width,
      h / height,
    );
  }
  
  /// 비정규화 (실제 픽셀 좌표로)
  RectF denormalize(double width, double height) {
    return RectF(
      x * width,
      y * height,
      w * width,
      h * height,
    );
  }
  
  /// 사각형 확장
  RectF expand(double padding) {
    return RectF(
      x - padding,
      y - padding,
      w + padding * 2,
      h + padding * 2,
    );
  }
  
  /// 사각형이 유효한지 확인
  bool get isValid => w > 0 && h > 0;
  
  @override
  String toString() {
    return 'RectF(x: $x, y: $y, w: $w, h: $h)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RectF &&
        other.x == x &&
        other.y == y &&
        other.w == w &&
        other.h == h;
  }
  
  @override
  int get hashCode => Object.hash(x, y, w, h);
}

/// 2D 점을 나타내는 클래스
class PointF {
  final double x, y;
  
  const PointF(this.x, this.y);
  
  /// 원점으로부터의 거리
  double get distance => math.sqrt(x * x + y * y);
  
  /// 다른 점과의 거리
  double distanceTo(PointF other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// 점 이동
  PointF translate(double dx, double dy) {
    return PointF(x + dx, y + dy);
  }
  
  /// 스케일링
  PointF scale(double factor) {
    return PointF(x * factor, y * factor);
  }
  
  @override
  String toString() {
    return 'PointF(x: $x, y: $y)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointF && other.x == x && other.y == y;
  }
  
  @override
  int get hashCode => Object.hash(x, y);
}

/// 크기를 나타내는 클래스
class SizeF {
  final double width, height;
  
  const SizeF(this.width, this.height);
  
  /// 면적
  double get area => width * height;
  
  /// 종횡비
  double get aspectRatio => width / height;
  
  /// 유효한 크기인지 확인
  bool get isValid => width > 0 && height > 0;
  
  /// 스케일링
  SizeF scale(double factor) {
    return SizeF(width * factor, height * factor);
  }
  
  @override
  String toString() {
    return 'SizeF(width: $width, height: $height)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SizeF && other.width == width && other.height == height;
  }
  
  @override
  int get hashCode => Object.hash(width, height);
}