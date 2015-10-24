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

  final String path;
  final BitmapData bitmapData;

  Int16List bones = null;
  Float32List weights = null;
  Int16List edges = null;
  int hullLength = 0;
  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;

  Int16List triangles = null;
  Float32List vertices = null;
  Float32List uvs = null;

  SkinnedMeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update(Int16List triangles, Float32List vertices, Float32List uvs, num scale) {

    var weights = new List<double>();
    var bones = new List<int>();

    for (int i = 0; i < vertices.length; ) {
      int boneCount = vertices[i++].toInt();
      bones.add(boneCount);
      for (int nn = i + boneCount * 4; i < nn; ) {
        bones.add(vertices[i].toInt());
        weights.add(vertices[i + 1] * scale);
        weights.add(vertices[i + 2] * scale);
        weights.add(vertices[i + 3]);
        i += 4;
      }
    }

    this.bones = new Int16List.fromList(bones);
    this.weights = new Float32List.fromList(weights);
    this.triangles = triangles;
    this.vertices = vertices;
    this.uvs = uvs;

    var matrix = bitmapData.renderTextureQuad.samplerMatrix;
    var ma = matrix.a * bitmapData.width;
    var mb = matrix.b * bitmapData.width;
    var mc = matrix.c * bitmapData.height;
    var md = matrix.d * bitmapData.height;
    var mx = matrix.tx;
    var my = matrix.ty;

    for (int i = 0; i < this.uvs.length - 1; i += 2) {
      var x = this.uvs[i + 0];
      var y = this.uvs[i + 1];
      this.uvs[i + 0] = x * ma + y * mc + mx;
      this.uvs[i + 1] = x * mb + y * md + my;
    }
  }

  //---------------------------------------------------------------------------

  Float32List getWorldVertices(num posX, num posY, Slot slot) {

    var skeletonBones = slot.skeleton.bones;
    var attachmentVertices = slot.attachmentVertices;  // ffd
    var weights = this.weights;
    var bones = this.bones;
    var result = _tmpFloat32List;
    var length = 0;

    for (int b = 0, w = 0, a = 0, i = 0; b < bones.length; i++) {

      var x = 0.0;
      var y = 0.0;
      var nn = bones[b++] + b;

      for ( ; b < nn; b++, w += 3, a += 2) {
        var wm = skeletonBones[bones[b]].worldMatrix;
        var vx = weights[w + 0];
        var vy = weights[w + 1];
        var weight = weights[w + 2];

        if (attachmentVertices.length != 0) {
          vx += attachmentVertices[a + 0];
          vy += attachmentVertices[a + 1];
        }

        x += (vx * wm.a + vy * wm.c + wm.tx) * weight;
        y += (vx * wm.b + vy * wm.d + wm.ty) * weight;
      }

      result[(i << 2) + 0] = x + posX;
      result[(i << 2) + 1] = y + posY;
      result[(i << 2) + 2] = uvs[(i << 1) + 0];
      result[(i << 2) + 3] = uvs[(i << 1) + 1];
      length += 4;
    }

    return new Float32List.view(result.buffer, 0, length);
  }

}
