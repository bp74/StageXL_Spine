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

  final BitmapData bitmapData;

  String path = null;
  Int16List bones = null;
  Float32List weights = null;
  Float32List uvs = null;
  Float32List regionUVs = null;
  Int16List triangles = null;
  Int16List edges = null;
  int hullLength = 0;
  num width = 0.0;
  num height = 0.0;
  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  SkinnedMeshAttachment(String name, this.bitmapData) : super(name);

  void updateUVs() {

    if (uvs == null || uvs.length != regionUVs.length) {
      uvs = new Float32List(regionUVs.length);
    }

    var renderTextureQuad = bitmapData.renderTextureQuad;
    var uvList = renderTextureQuad.uvList;
    var u1 = uvList[0];
    var v1 = uvList[1];
    var u2 = uvList[4];
    var v2 = uvList[5];

    if (renderTextureQuad.rotation == 0 || renderTextureQuad.rotation == 2) {
      for (int i = 0; i < regionUVs.length - 1; i += 2) {
        uvs[i + 0] = u1 + regionUVs[i + 0] * (u2 - u1);
        uvs[i + 1] = v1 + regionUVs[i + 1] * (v2 - v1);
      }
    } else {
      for (int i = 0; i < regionUVs.length - 1; i += 2) {
        uvs[i + 0] = u1 + regionUVs[i + 1] * (u2 - u1);
        uvs[i + 1] = v1 + regionUVs[i + 0] * (v2 - v1);
      }
    }
  }

  void computeWorldVertices(num x, num y, Slot slot, Float32List worldVertices) {

    List<Bone> skeletonBones = slot.skeleton.bones;
    Float32List attachmentVertices = slot.attachmentVertices;  // ffd
    Float32List weights = this.weights;
    Int16List bones = this.bones;

    for (int w = 0, v = 0, b = 0, f = 0; v < bones.length; w += 2) {

      num wx = 0;
      num wy = 0;
      int nn = bones[v++] + v;

      for ( ; v < nn; v++, b += 3, f += 2) {

        num vx = weights[b + 0];
        num vy = weights[b + 1];
        num weight = weights[b + 2];

        if (attachmentVertices.length != 0) {
          vx += attachmentVertices[f + 0];
          vy += attachmentVertices[f + 1];
        }

        Matrix matrix = skeletonBones[bones[v]].worldMatrix;
        wx += (vx * matrix.a + vy * matrix.c + matrix.tx) * weight;
        wy += (vx * matrix.b + vy * matrix.d + matrix.ty) * weight;
      }

      worldVertices[w + 0] = wx + x;
      worldVertices[w + 1] = wy + y;
    }
  }

}
