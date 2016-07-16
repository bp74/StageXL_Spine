/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class VertexAttachment extends Attachment {

  Int16List bones;
  Float32List vertices;
  int worldVerticesLength = 0;

  VertexAttachment(String name) : super(name);

  void computeWorldVertices(Slot slot, Float32List worldVertices) {
    computeWorldVertices2(slot, 0, worldVerticesLength, worldVertices, 0);
  }

  /// Transforms local vertices to world coordinates.
  ///
  /// [start] The index of the first local vertex value to transform.
  /// Each vertex has 2 values, x and y.
  ///
  /// [count] The number of world vertex values to output.
  /// Must be <= getWorldVerticesLength() - start.
  ///
  /// [worldVertices] The output world vertices.
  /// Must have a length >= offset + count.
  ///
  /// [offset] The worldVertices index to begin writing values.

  void computeWorldVertices2(
      Slot slot, int start, int count,
      Float32List worldVertices, int offset) {

    count += offset;
    Skeleton skeleton = slot.skeleton;
    num x = skeleton.x, y = skeleton.y;
    Float32List deformArray = slot.attachmentVertices;
    Float32List vertices = this.vertices;
    Int16List bones = this.bones;

    int v = 0, w = 0, n = 0, i = 0, skip = 0, b = 0, f = 0;
    num vx = 0.0, vy = 0.0;
    num wx = 0.0, wy = 0.0;
    num weight = 0.0;
    Bone bone;

    if (bones == null) {
      if (deformArray.length > 0) vertices = deformArray;
      bone = slot.bone;
      x += bone.worldX;
      y += bone.worldY;
      num ba = bone.a;
      num bb = bone.b;
      num bc = bone.c;
      num bd = bone.d;
      v = start;
      for (w = offset; w < count; v += 2, w += 2) {
        vx = vertices[v + 0];
        vy = vertices[v + 1];
        worldVertices[w + 0] = 0 + (vx * ba + vy * bb + x);
        worldVertices[w + 1] = 0 - (vx * bc + vy * bd + y);
      }
      return;
    }

    v = 0;
    skip = 0;
    for (i = 0; i < start; i += 2) {
      n = bones[v];
      v += n + 1;
      skip += n;
    }

    List<Bone> skeletonBones = skeleton.bones;

    if (deformArray.length == 0) {
      b = skip * 3;
      for (w = offset; w < count; w += 2) {
        wx = x;
        wy = y;
        n = bones[v++];
        n += v;
        for (; v < n; v++, b += 3) {
          bone = skeletonBones[bones[v]];
          vx = vertices[b + 0];
          vy = vertices[b + 1];
          weight = vertices[b + 2];
          wx += (vx * bone.a + vy * bone.b + bone.worldX) * weight;
          wy += (vx * bone.c + vy * bone.d + bone.worldY) * weight;
        }
        worldVertices[w + 0] = 0 + wx;
        worldVertices[w + 1] = 0 - wy;
      }

    } else {

      Float32List deform = deformArray;
      b = skip * 3;
      f = skip << 1;
      for (w = offset; w < count; w += 2) {
        wx = x;
        wy = y;
        n = bones[v++];
        n += v;
        for (; v < n; v++, b += 3, f += 2) {
          bone = skeletonBones[bones[v]];
          vx = vertices[b + 0] + deform[f + 0];
          vy = vertices[b + 1] + deform[f + 1];
          weight = vertices[b + 2];
          wx += (vx * bone.a + vy * bone.b + bone.worldX) * weight;
          wy += (vx * bone.c + vy * bone.d + bone.worldY) * weight;
        }
        worldVertices[w + 0] = 0 + wx;
        worldVertices[w + 1] = 0 - wy;
      }
    }
  }

  /// Returns true if a deform originally applied to the specified attachment
  /// should be applied to this attachment.

  bool applyDeform(VertexAttachment sourceAttachment) {
    return this == sourceAttachment;
  }
}
