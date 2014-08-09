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

class SkinnedMeshAttachment extends Attachment {

  List<int> bones = null;
  List<num> weights = null;
  List<num> uvs = null;
  List<num> regionUVs = null;
  List<int> triangles = null;
  int hullLength = 0;

  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  String path = null;
  Object rendererObject = null;

  num regionU = 0.0;
  num regionV = 0.0;
  num regionU2 = 1.0;
  num regionV2 = 1.0;
  bool regionRotate = false;

  num regionOffsetX = 0.0; // Pixels stripped from the bottom left, unrotated.
  num regionOffsetY = 0.0;
  num regionWidth = 0.0; // Unrotated, stripped size.
  num regionHeight = 0.0;
  num regionOriginalWidth = 0.0; // Unrotated, unstripped size.
  num regionOriginalHeight = 0.0;

  // Nonessential.
  List<int> edges = null;
  num width = 0.0;
  num height = 0.0;

  SkinnedMeshAttachment(String name) : super(name);

  void updateUVs() {

    num width = regionU2 - regionU;
    num height = regionV2 - regionV;

    if (uvs == null || uvs.length != regionUVs.length) {
      uvs = new List<num>.filled(regionUVs.length, 0);
    }

    if (regionRotate) {
      for (int i = 0; i < regionUVs.length; i += 2) {
        uvs[i + 0] = regionU + regionUVs[i + 1] * width;
        uvs[i + 1] = regionV - regionUVs[i + 0] * height + height;
      }
    } else {
      for (int i = 0; i < regionUVs.length; i += 2) {
        uvs[i + 0] = regionU + regionUVs[i + 0] * width;
        uvs[i + 1] = regionV + regionUVs[i + 1] * height;
      }
    }
  }

  void computeWorldVertices(num x, num y, Slot slot, List<num> worldVertices) {

    List<Bone> skeletonBones = slot.skeleton.bones;
    List<num> weights = this.weights;
    List<int> bones = this.bones;

    int w = 0;
    int v = 0;
    int b = 0;
    int f = 0;
    int nn;

    num wx;
    num wy;
    Bone bone;
    num vx;
    num vy;
    num weight;

    if (slot.attachmentVertices.length == 0) {

      for ( ; v < bones.length; w += 2) {
        wx = wy = 0;
        int nn = bones[v++] + v;
        for ( ; v < nn; v++, b += 3) {
          bone = skeletonBones[bones[v]];
          vx = weights[b + 0];
          vy = weights[b + 1];
          weight = weights[b + 2];
          wx += (vx * bone.m00 + vy * bone.m01 + bone.worldX) * weight;
          wy += (vx * bone.m10 + vy * bone.m11 + bone.worldY) * weight;
        }
        worldVertices[w + 0] = wx + x;
        worldVertices[w + 1] = wy + y;
      }

    } else {

      List<num> ffd = slot.attachmentVertices;
      for ( ; v < bones.length; w += 2) {
        wx = wy = 0;
        int nn = bones[v++] + v;
        for ( ; v < nn; v++, b += 3, f += 2) {
          bone = skeletonBones[bones[v]];
          vx = weights[b + 0] + ffd[f + 0];
          vy = weights[b + 1] + ffd[f + 1];
          weight = weights[b + 2];
          wx += (vx * bone.m00 + vy * bone.m01 + bone.worldX) * weight;
          wy += (vx * bone.m10 + vy * bone.m11 + bone.worldY) * weight;
        }
        worldVertices[w + 0] = wx + x;
        worldVertices[w + 1] = wy + y;
      }
    }
  }

}
