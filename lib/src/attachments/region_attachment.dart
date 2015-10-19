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

class RegionAttachment extends Attachment {

  final BitmapData bitmapData;
  final Matrix matrix = new Matrix.fromIdentity();

  String path = null;
  Float32List vertices = null;
  Float32List uvs = null;
  Float32List regionUVs = null;
  Int16List triangles = null;
  num x = 0.0;
  num y = 0.0;
  num scaleX = 1.0;
  num scaleY = 1.0;
  num rotation = 0.0;
  num width = 0.0;
  num height = 0.0;
  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  RegionAttachment(String name, this.bitmapData) : super(name);

  void updateUVs() {

    matrix.identity();
    matrix.scale(width / bitmapData.width, height / bitmapData.height);
    matrix.translate(0.0 - width / 2, 0.0 - height / 2);
    matrix.scale(scaleX, scaleY);
    matrix.scale(1.0, -1.0);
    matrix.rotate(rotation * math.PI / 180.0);
    matrix.translate(x, y);

    var vxList = bitmapData.renderTextureQuad.vxList;
    var ixList = bitmapData.renderTextureQuad.ixList;

    triangles = ixList;
    vertices = new Float32List(vxList.length >> 1);
    regionUVs = new Float32List(vxList.length >> 1);
    uvs = new Float32List(vxList.length >> 1);

    for(int i = 0; i < vertices.length - 1; i += 2) {
      num vx = vxList[i * 2 + 0];
      num vy = vxList[i * 2 + 1];
      vertices[i + 0] = vx * matrix.a + vy * matrix.c + matrix.tx;
      vertices[i + 1] = vx * matrix.b + vy * matrix.d + matrix.ty;
    }

    for(int i = 0; i < regionUVs.length - 1; i += 2) {
      regionUVs[i + 0] = uvs[i + 0] = vxList[i * 2 + 2];
      regionUVs[i + 1] = uvs[i + 1] = vxList[i * 2 + 3];
    }
  }

  void computeWorldVertices(num x, num y, Slot slot, Float32List worldVertices) {

    var wm = slot.bone.worldMatrix;

    for (int i = 0; i < this.vertices.length - 1; i += 2) {
      num vx = this.vertices[i + 0];
      num vy = this.vertices[i + 1];
      worldVertices[i + 0] = vx * wm.a + vy * wm.c + wm.tx + x;
      worldVertices[i + 1] = vx * wm.b + vy * wm.d + wm.ty + y;
    }
  }

}
