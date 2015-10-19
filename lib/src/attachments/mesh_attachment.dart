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

  final BitmapData bitmapData;

  String path = null;
  Float32List vertices = null;
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

  MeshAttachment(String name, this.bitmapData) : super(name);

  void updateUVs() {

    if (uvs == null || uvs.length != regionUVs.length) {
      uvs = new Float32List(regionUVs.length);
    }

    var sm = bitmapData.renderTextureQuad.samplerMatrix;

    for (int i = 0; i < regionUVs.length - 1; i += 2) {
      var x = regionUVs[i + 0] * bitmapData.width;
      var y = regionUVs[i + 1] * bitmapData.height;
      uvs[i + 0] = sm.tx + x * sm.a + y * sm.c;
      uvs[i + 1] = sm.ty + x * sm.b + y * sm.d;
    }
  }

  void computeWorldVertices(num x, num y, Slot slot, Float32List worldVertices) {

    if (slot.attachmentVertices.length == this.vertices.length) {
      this.vertices = slot.attachmentVertices;
    }

    var wm = slot.bone.worldMatrix;

    for (int i = 0; i < this.vertices.length - 1; i += 2) {
      num vx = this.vertices[i + 0];
      num vy = this.vertices[i + 1];
      worldVertices[i + 0] = vx * wm.a + vy * wm.c + wm.tx + x;
      worldVertices[i + 1] = vx * wm.b + vy * wm.d + wm.ty + y;
    }
  }
}
