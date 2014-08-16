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

  final int X1 = 0;
  final int Y1 = 1;
  final int X2 = 2;
  final int Y2 = 3;
  final int X3 = 4;
  final int Y3 = 5;
  final int X4 = 6;
  final int Y4 = 7;

  final Matrix matrix = new Matrix.fromIdentity();
  final Float32List offset = new Float32List(8);
  final Float32List uvs = new Float32List(8);

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

  String path = null;
  AtlasRegion atlasRegion = null;

  num regionOffsetX = 0.0; // Pixels stripped from the bottom left, unrotated.
  num regionOffsetY = 0.0;
  num regionWidth = 0.0; // Unrotated, stripped size.
  num regionHeight = 0.0;
  num regionOriginalWidth = 0.0; // Unrotated, unstripped size.
  num regionOriginalHeight = 0.0;

  RegionAttachment(String name) : super(name);

  void setUVs(num u, num v, num u2, num v2, bool rotate) {
    uvs[0] = rotate ? u2 : u;
    uvs[1] = v2;
    uvs[2] = u;
    uvs[3] = rotate ? v2 : v;
    uvs[4] = rotate ? u : u2;
    uvs[5] = v;
    uvs[6] = u2;
    uvs[7] = rotate ? v : v2;
  }

  void updateOffset() {

    num pivotX = width / 2;
    num pivotY = height / 2;
    num regionScaleX = scaleX * width / regionOriginalWidth;
    num regionScaleY = scaleY * height / regionOriginalHeight;
    num radians = rotation * math.PI / 180;
    num cos = math.cos(radians);
    num sin = math.sin(radians);

    //--------------------------------------------

    num localX = regionOffsetX * regionScaleX - scaleX * pivotX;
    num localY = regionOffsetY * regionScaleY - scaleY * pivotY;
    num localX2 = localX + regionWidth * regionScaleX;
    num localY2 = localY + regionHeight * regionScaleY;
    num localXCos = localX * cos + x;
    num localXSin = localX * sin;
    num localYCos = localY * cos + y;
    num localYSin = localY * sin;
    num localX2Cos = localX2 * cos + x;
    num localX2Sin = localX2 * sin;
    num localY2Cos = localY2 * cos + y;
    num localY2Sin = localY2 * sin;

    offset[0] = localXCos - localYSin;
    offset[1] = localYCos + localXSin;
    offset[2] = localXCos - localY2Sin;
    offset[3] = localY2Cos + localXSin;
    offset[4] = localX2Cos - localY2Sin;
    offset[5] = localY2Cos + localX2Sin;
    offset[6] = localX2Cos - localYSin;
    offset[7] = localYCos + localX2Sin;

    //--------------------------------------------

    num a  =   regionScaleX * cos;
    num b  =   regionScaleX * sin;
    num c  =   regionScaleY * sin;
    num d  = - regionScaleY * cos;
    num tx = x - pivotX * a - pivotY * c;
    num ty = y - pivotX * b - pivotY * d;

    this.matrix.setTo(a, b, c, d, tx, ty);
  }

  void computeWorldVertices(num x, num y, Bone bone, Float32List worldVertices) {

    Matrix matrix = bone.worldMatrix;

    num a  = matrix.a;
    num b  = matrix.b;
    num c  = matrix.c;
    num d  = matrix.d;
    num tx = matrix.tx + x;
    num ty = matrix.ty + y;

    num x1 = offset[0];
    num y1 = offset[1];
    num x2 = offset[2];
    num y2 = offset[3];
    num x3 = offset[4];
    num y3 = offset[5];
    num x4 = offset[6];
    num y4 = offset[7];

    if (worldVertices.length < 8) return; // dart2js_hint

    worldVertices[0] = x1 * a + y1 * c + tx;
    worldVertices[1] = x1 * b + y1 * d + ty;
    worldVertices[2] = x2 * a + y2 * c + tx;
    worldVertices[3] = x2 * b + y2 * d + ty;
    worldVertices[4] = x3 * a + y3 * c + tx;
    worldVertices[5] = x3 * b + y3 * d + ty;
    worldVertices[6] = x4 * a + y4 * c + tx;
    worldVertices[7] = x4 * b + y4 * d + ty;
  }

}
