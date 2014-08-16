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

  Float32List vertices = null;
  Float32List uvs = null;
  Float32List regionUVs = null;
  Int16List triangles = null;

  int hullLength = 0;
  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  String path = null;
  AtlasRegion atlasRegion = null;

  num regionU = 0.0;
  num regionV = 0.0;
  num regionU2 = 0.0;
  num regionV2 = 0.0;
  bool regionRotate = false;

  num regionOffsetX = 0.0; // Pixels stripped from the bottom left, unrotated.
  num regionOffsetY = 0.0;
  num regionWidth = 0.0; // Unrotated, stripped size.
  num regionHeight = 0.0;
  num regionOriginalWidth = 0.0; // Unrotated, unstripped size.
  num regionOriginalHeight = 0.0;

  // Nonessential.
  Int16List edges = null;
  num width = 0.0;
  num height = 0.0;

  MeshAttachment(String name) : super(name);

  void updateUVs() {

    num width = regionU2 - regionU;
    num height = regionV2 - regionV;

    if (uvs == null || uvs.length != regionUVs.length) {
      uvs = new Float32List(regionUVs.length);
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

  void computeWorldVertices(num x, num y, Slot slot, Float32List worldVertices) {

    Matrix matrix = slot.bone.worldMatrix;

    num a  = matrix.a;
    num b  = matrix.b;
    num c  = matrix.c;
    num d  = matrix.d;
    num tx = matrix.tx + x;
    num ty = matrix.ty + y;

    if (slot.attachmentVertices.length == this.vertices.length) {
      this.vertices = slot.attachmentVertices;
    }

    for (int i = 0; i < this.vertices.length; i += 2) {
      num vx = this.vertices[i + 0];
      num vy = this.vertices[i + 1];
      worldVertices[i + 0] = vx * a + vy * c + tx;
      worldVertices[i + 1] = vx * b + vy * d + ty;
    }
  }
}
