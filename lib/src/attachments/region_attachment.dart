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
  final Float32List offset = new Float32List(8);
  final Float32List uvs = new Float32List(8);

  String path = null;
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

    var renderTextureQuad = bitmapData.renderTextureQuad;
    var vxList = renderTextureQuad.vxListQuad;

    uvs[0] = vxList[14];  // bottom-left
    uvs[1] = vxList[15];
    uvs[2] = vxList[02];  // top-left
    uvs[3] = vxList[03];
    uvs[4] = vxList[06];  // top-right
    uvs[5] = vxList[07];
    uvs[6] = vxList[10];  // bottom-right
    uvs[7] = vxList[11];
  }

  void updateOffset() {

    var renderTextureQuad = bitmapData.renderTextureQuad;
    var vxList = renderTextureQuad.vxListQuad;

    matrix.identity();
    matrix.scale(width / bitmapData.width, height / bitmapData.height);
    matrix.translate(0.0 - width / 2, 0.0 - height / 2);
    matrix.scale(scaleX, scaleY);
    matrix.scale(1.0, -1.0);
    matrix.rotate(rotation * math.PI / 180.0);
    matrix.translate(x, y);

    num ma = matrix.a;
    num mb = matrix.b;
    num mc = matrix.c;
    num md = matrix.d;
    num mx = matrix.tx;
    num my = matrix.ty;

    offset[0] = vxList[12] * ma + vxList[13] * mc + mx;
    offset[1] = vxList[12] * mb + vxList[13] * md + my;
    offset[2] = vxList[00] * ma + vxList[01] * mc + mx;
    offset[3] = vxList[00] * mb + vxList[01] * md + my;
    offset[4] = vxList[04] * ma + vxList[05] * mc + mx;
    offset[5] = vxList[04] * mb + vxList[05] * md + my;
    offset[6] = vxList[08] * ma + vxList[09] * mc + mx;
    offset[7] = vxList[08] * mb + vxList[09] * md + my;
  }

  void computeWorldVertices(num x, num y, Bone bone, Float32List worldVertices) {

    Matrix matrix = bone.worldMatrix;
    num ma = matrix.a;
    num mb = matrix.b;
    num mc = matrix.c;
    num md = matrix.d;
    num mx = matrix.tx + x;
    num my = matrix.ty + y;

    if (worldVertices.length < 8) return; // dart2js_hint

    worldVertices[0] = offset[0] * ma + offset[1] * mc + mx;
    worldVertices[1] = offset[0] * mb + offset[1] * md + my;
    worldVertices[2] = offset[2] * ma + offset[3] * mc + mx;
    worldVertices[3] = offset[2] * mb + offset[3] * md + my;
    worldVertices[4] = offset[4] * ma + offset[5] * mc + mx;
    worldVertices[5] = offset[4] * mb + offset[5] * md + my;
    worldVertices[6] = offset[6] * ma + offset[7] * mc + mx;
    worldVertices[7] = offset[6] * mb + offset[7] * md + my;
  }

}
