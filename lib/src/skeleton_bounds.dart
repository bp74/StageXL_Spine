/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class SkeletonBounds {
  final List<BoundingBoxAttachment> boundingBoxes = [];
  final List<Float32List> verticesList = [];
  final List<ByteBuffer> _byteBuffers = [];

  double minX = 0.0;
  double minY = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;

  double get width => maxX - minX;
  double get height => maxY - minY;

  void update(Skeleton skeleton, bool updateAabb) {
    List<Slot> slots = skeleton.slots;

    for (int i = 0; i < verticesList.length; i++) {
      _byteBuffers.add(verticesList[i].buffer);
    }

    boundingBoxes.clear();
    verticesList.clear();

    for (int i = 0; i < slots.length; i++) {
      Slot slot = slots[i];
      Attachment? attachment = slot.attachment;

      if (attachment is BoundingBoxAttachment) {
        BoundingBoxAttachment boundingBox = attachment;
        Float32List? vertices;
        int verticesLength = boundingBox.worldVerticesLength;
        int byteBufferLength = verticesLength << 2;

        for (int i = 0; i < _byteBuffers.length; i++) {
          var byteBuffer = _byteBuffers[i];
          if (byteBuffer.lengthInBytes >= byteBufferLength) {
            vertices = byteBuffer.asFloat32List(0, verticesLength);
            _byteBuffers.removeAt(i);
            break;
          }
        }

        if (vertices == null) vertices = Float32List(verticesLength);
        boundingBox.computeWorldVertices(slot, vertices);

        boundingBoxes.add(boundingBox);
        verticesList.add(vertices);
      }
    }

    if (updateAabb) {
      aabbCompute();
    } else {
      minX = double.negativeInfinity;
      minY = double.negativeInfinity;
      maxX = double.infinity;
      maxY = double.infinity;
    }
  }

  void aabbCompute() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < verticesList.length; i++) {
      Float32List polygon = verticesList[i];
      for (int ii = 0; ii < polygon.length - 1; ii += 2) {
        double x = polygon[ii + 0];
        double y = polygon[ii + 1];
        if (minX > x) minX = x;
        if (maxX < x) maxX = x;
        if (minY > y) minY = y;
        if (maxY < y) maxY = y;
      }
    }

    this.minX = minX;
    this.minY = minY;
    this.maxX = maxX;
    this.maxY = maxY;
  }

  /// Returns true if the axis aligned bounding box contains the point.
  ///
  bool aabbContainsPoint(double x, double y) {
    return x >= minX && x <= maxX && y >= minY && y <= maxY;
  }

  /// Returns true if the axis aligned bounding box intersects the line segment.
  ///
  bool aabbIntersectsSegment(double x1, double y1, double x2, double y2) {
    if ((x1 <= minX && x2 <= minX) ||
        (y1 <= minY && y2 <= minY) ||
        (x1 >= maxX && x2 >= maxX) ||
        (y1 >= maxY && y2 >= maxY)) return false;

    double m = (y2 - y1) / (x2 - x1);

    double y = m * (minX - x1) + y1;
    if (y > minY && y < maxY) return true;

    y = m * (maxX - x1) + y1;
    if (y > minY && y < maxY) return true;

    double x = (minY - y1) / m + x1;
    if (x > minX && x < maxX) return true;

    x = (maxY - y1) / m + x1;
    if (x > minX && x < maxX) return true;

    return false;
  }

  /// Returns true if the axis aligned bounding box intersects the axis
  /// aligned bounding box of the specified bounds.
  ///
  bool aabbIntersectsSkeleton(SkeletonBounds bounds) {
    return minX < bounds.maxX && maxX > bounds.minX && minY < bounds.maxY && maxY > bounds.minY;
  }

  /// Returns the first bounding box attachment that contains the point,
  /// or null. When doing many checks, it is usually more efficient to only
  /// call this method if [aabbContainsPoint] returns true.
  ///
  BoundingBoxAttachment? containsPoint(double x, double y) {
    for (int i = 0; i < verticesList.length; i++) {
      BoundingBoxAttachment boundingBox = boundingBoxes[i];
      Float32List vertices = verticesList[i];
      if (_containsPoint(vertices, x, y)) return boundingBox;
    }

    return null;
  }

  /// Returns the first bounding box attachment that contains the line
  /// segment, or null. When doing many checks, it is usually more efficient
  /// to only call this method if [aabbIntersectsSegment] returns true.
  ///
  BoundingBoxAttachment? intersectsSegment(double x1, double y1, double x2, double y2) {
    for (int i = 0; i < verticesList.length; i++) {
      BoundingBoxAttachment boundingBox = boundingBoxes[i];
      Float32List vertices = verticesList[i];
      if (_intersectsSegment(vertices, x1, y1, x2, y2)) return boundingBox;
    }

    return null;
  }

  Float32List? getVertices(BoundingBoxAttachment attachment) {
    int index = boundingBoxes.indexOf(attachment);
    return index == -1 ? null : verticesList[index];
  }

  //-----------------------------------------------------------------------------------------------

  bool _containsPoint(Float32List vertices, double x, double y) {
    bool inside = false;
    int prevIndex = vertices.length - 2;

    for (int i = 0; i < vertices.length - 1; i += 2) {
      double vertexX = vertices[i + 0];
      double vertexY = vertices[i + 1];
      double prevX = vertices[prevIndex + 0];
      double prevY = vertices[prevIndex + 1];

      if ((vertexY < y && prevY >= y) || (prevY < y && vertexY >= y)) {
        if (vertexX + (y - vertexY) / (prevY - vertexY) * (prevX - vertexX) < x) {
          inside = !inside;
        }
      }

      prevIndex = i;
    }

    return inside;
  }

  bool _intersectsSegment(Float32List vertices, double x1, double y1, double x2, double y2) {
    double width12 = x1 - x2;
    double height12 = y1 - y2;
    double det1 = x1 * y2 - y1 * x2;

    double x3 = vertices[vertices.length - 2];
    double y3 = vertices[vertices.length - 1];

    for (int i = 0; i < vertices.length - 1; i += 2) {
      double x4 = vertices[i + 0];
      double y4 = vertices[i + 1];

      double det2 = x3 * y4 - y3 * x4;
      double width34 = x3 - x4;
      double height34 = y3 - y4;
      double det3 = width12 * height34 - height12 * width34;

      double x = (det1 * width34 - width12 * det2) / det3;
      if (((x >= x3 && x <= x4) || (x >= x4 && x <= x3)) &&
          ((x >= x1 && x <= x2) || (x >= x2 && x <= x1))) {
        double y = (det1 * height34 - height12 * det2) / det3;
        if (((y >= y3 && y <= y4) || (y >= y4 && y <= y3)) &&
            ((y >= y1 && y <= y2) || (y >= y2 && y <= y1))) return true;
      }

      x3 = x4;
      y3 = y4;
    }

    return false;
  }
}
