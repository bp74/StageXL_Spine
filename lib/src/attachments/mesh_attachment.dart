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

  List<num> vertices;
  List<num> uvs;
  List<num> regionUVs;
  List<int> triangles;
  int hullLength;
  num r = 1;
  num g = 1;
  num b = 1;
  num a = 1;

  String path;
  Object rendererObject;

  num regionU, regionV;
  num regionU2, regionV2;
  bool regionRotate;

  num regionOffsetX; // Pixels stripped from the bottom left, unrotated.
  num regionOffsetY;
  num regionWidth; // Unrotated, stripped size.
  num regionHeight;
  num regionOriginalWidth; // Unrotated, unstripped size.
  num regionOriginalHeight;

  // Nonessential.
  List<int> edges;
  num width;
  num height;

  MeshAttachment(String name) : super(name);

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

    Bone bone = slot.bone;
    x += bone.worldX;
    y += bone.worldY;
    num m00 = bone.m00;
    num m01 = bone.m01;
    num m10 = bone.m10;
    num m11 = bone.m11;

    if (slot.attachmentVertices.length == this.vertices.length) {
      this.vertices = slot.attachmentVertices;
    }

    for (int i = 0; i < this.vertices.length; i += 2) {
      num vx = this.vertices[i + 0];
      num vy = this.vertices[i + 1];
      worldVertices[i + 0] = vx * m00 + vy * m01 + x;
      worldVertices[i + 1] = vx * m10 + vy * m11 + y;
    }
  }
}
