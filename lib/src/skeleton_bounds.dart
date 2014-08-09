/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 *
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class SkeletonBounds {

  List<Polygon> _polygonPool = new List<Polygon>();

  List<BoundingBoxAttachment> boundingBoxes = new List<BoundingBoxAttachment>();
  List<Polygon> polygons = new List<Polygon>();
  num minX, minY, maxX, maxY;

  num get width => maxX - minX;
  num get height => maxY - minY;

  void update(Skeleton skeleton, bool updateAabb) {

    List<Slot> slots = skeleton.slots;
    int slotCount = slots.length;
    num x = skeleton.x;
    num y = skeleton.y;

    _polygonPool.addAll(polygons);

    boundingBoxes.clear();
    polygons.clear();

    for (int i = 0; i < slotCount; i++) {
      Slot slot = slots[i];
      BoundingBoxAttachment boundingBox = slot.attachment as BoundingBoxAttachment;
      if (boundingBox == null) continue;

      boundingBoxes.add(boundingBox);

      Polygon polygon = _polygonPool.length > 0 ? _polygonPool.removeLast() : new Polygon();
      polygons.add(polygon);

      polygon.vertices.length = boundingBox.vertices.length;
      boundingBox.computeWorldVertices(x, y, slot.bone, polygon.vertices);
    }

    if (updateAabb) aabbCompute();
  }

  void aabbCompute() {

    num minX = double.INFINITY;
    num minY = double.INFINITY;
    num maxX = double.NEGATIVE_INFINITY;
    num maxY = double.NEGATIVE_INFINITY;

    for (int i = 0; i < polygons.length; i++) {
      Polygon polygon = polygons[i];
      List<num> vertices = polygon.vertices;
      for (int ii = 0; ii < vertices.length; ii += 2) {
        num x = vertices[ii];
        num y = vertices[ii + 1];
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }

    this.minX = minX;
    this.minY = minY;
    this.maxX = maxX;
    this.maxY = maxY;
  }


  /// Returns true if the axis aligned bounding box contains the point.
  ///
  bool aabbContainsPoint(num x, num y) {
    return x >= minX && x <= maxX && y >= minY && y <= maxY;
  }

  /// Returns true if the axis aligned bounding box intersects the line segment.
  ///
  bool aabbIntersectsSegment(num x1, num y1, num x2, num y2) {

    if ((x1 <= minX && x2 <= minX) || (y1 <= minY && y2 <= minY) || (x1 >= maxX && x2 >= maxX) || (y1 >= maxY && y2 >= maxY)) return false;

    num m = (y2 - y1) / (x2 - x1);
    num y = m * (minX - x1) + y1;
    if (y > minY && y < maxY) return true;
    y = m * (maxX - x1) + y1;
    if (y > minY && y < maxY) return true;
    num x = (minY - y1) / m + x1;
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
  BoundingBoxAttachment containsPoint(num x, num y) {

    for (int i = 0; i < polygons.length; i++) {
      if (polygons[i].containsPoint(x, y)) {
        return boundingBoxes[i];
      }
    }
    return null;
  }

  /// Returns the first bounding box attachment that contains the line
  /// segment, or null. When doing many checks, it is usually more efficient
  /// to only call this method if [aabbIntersectsSegment] returns true.
  ///
  BoundingBoxAttachment intersectsSegment(num x1, num y1, num x2, num y2) {

    for (int i = 0; i < polygons.length; i++) {
      if (polygons[i].intersectsSegment(x1, y1, x2, y2)) {
        return boundingBoxes[i];
      }
    }
    return null;
  }

  Polygon getPolygon(BoundingBoxAttachment attachment) {
    int index = boundingBoxes.indexOf(attachment);
    return index == -1 ? null : polygons[index];
  }

}
