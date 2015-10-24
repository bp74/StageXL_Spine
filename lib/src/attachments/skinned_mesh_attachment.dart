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

  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;
  int hullLength = 0;
  int vertexLength = 0;

  Int16List edges = null;
  Int16List triangles = null;
  Float32List vertices = null;
  Float32List uvs = null;

  SkinnedMeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update(Int16List triangles, Float32List vertices, Float32List uvs) {

    this.triangles = triangles;
    this.vertices = vertices;
    this.uvs = uvs;
    this.vertexLength = 0;

    for (int i = 0; i < this.vertices.length; i++) {
      var boneCount = vertices[i].toInt();
      this.vertexLength += boneCount * 2;
      i += boneCount * 4;
    }

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
    var vxList = _tmpFloat32List;
    var vxIndex = 0;
    var uvIndex = 0;
    var avIndex = 0;

    for (int i = 0; i < vertices.length; ) {

      var x = posX;
      var y = posY;
      var boneCount = vertices[i++];

      for(int b = 0; b < boneCount; b++) {

        var boneIndex = vertices[i + 0];
        var bone = skeletonBones[boneIndex.toInt()];
        var wm = bone.worldMatrix;

        var vx = vertices[i + 1];
        var vy = vertices[i + 2];
        var vs = vertices[i + 3];

        if (avIndex < attachmentVertices.length - 1) {
          vx += attachmentVertices[avIndex + 0];
          vy += attachmentVertices[avIndex + 1];
          avIndex += 2;
        }

        x += (vx * wm.a + vy * wm.c + wm.tx) * vs;
        y += (vx * wm.b + vy * wm.d + wm.ty) * vs;
        i += 4;
      }

      vxList[vxIndex + 0] = x;
      vxList[vxIndex + 1] = y;
      vxList[vxIndex + 2] = uvs[uvIndex + 0];
      vxList[vxIndex + 3] = uvs[uvIndex + 1];
      vxIndex += 4;
      uvIndex += 2;
    }

    return new Float32List.view(vxList.buffer, 0, vxIndex);
  }

}
