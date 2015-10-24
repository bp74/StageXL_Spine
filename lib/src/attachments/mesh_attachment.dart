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

class MeshAttachment extends Attachment {

  final String path;
  final BitmapData bitmapData;

  Int16List edges = null;
  int hullLength = 0;
  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;

  Int16List triangles = null;
  Float32List vertices = null;
  Float32List uvs = null;

  MeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update(Int16List triangles, Float32List vertices, Float32List uvs) {

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

    for (int i = 0; i < uvs.length - 1; i += 2) {
      var u = this.uvs[i + 0];
      var v = this.uvs[i + 1];
      this.uvs[i + 0] = u * ma + v * mc + mx;
      this.uvs[i + 1] = u * mb + v * md + my;
    }
  }

  //---------------------------------------------------------------------------

  Float32List getWorldVertices(num posX, num posY, Slot slot) {

    var matrix = slot.bone.worldMatrix;
    var result = _tmpFloat32List;
    var length = vertices.length;

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx + posX;
    var my = matrix.ty + posY;

    if (slot.attachmentVertices.length == this.vertices.length) {
      this.vertices = slot.attachmentVertices;
    }

    for (int i = 0; i <= length - 2; i += 2) {
      var x = vertices[i + 0];
      var y = vertices[i + 1];
      var u = uvs[i + 0];
      var v = uvs[i + 1];
      result[(i << 1) + 0] = x * ma + y * mc + mx;
      result[(i << 1) + 1] = x * mb + y * md + my;
      result[(i << 1) + 2] = u;
      result[(i << 1) + 3] = v;
    }

    return new Float32List.view(result.buffer, 0, length * 2);
  }
}
