/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;
 
class PathConstraint implements Constraint {

  static const int _NONE = -1;
  static const int _BEFORE = -2;
  static const int _AFTER = -3;

  final PathConstraintData data;
  final List<Bone> bones = new List<Bone>();

  Slot target;
  num position = 0.0;
  num spacing = 0.0;
  num rotateMix = 0.0;
  num translateMix = 0.0;

  Float32List _spaces = new Float32List(0);
  Float32List _positions = new Float32List(0);
  Float32List _world = new Float32List(0);
  Float32List _curves = new Float32List(0);
  Float32List _lengths = new Float32List(0);
  Float32List _segments = new Float32List(10);

  PathConstraint(this.data, Skeleton skeleton) {

    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");

    for (BoneData boneData in data.bones) {
      bones.add(skeleton.findBone(boneData.name));
    }

    target = skeleton.findSlot(data.target.name);
    position = data.position;
    spacing = data.spacing;
    rotateMix = data.rotateMix;
    translateMix = data.translateMix;
  }

  void apply() {
    update();
  }

  void update() {

    if (target.attachment is! PathAttachment) return;
    PathAttachment attachment = target.attachment;

    num deg2rad = math.PI / 180.0;
    num rotateMix = this.rotateMix;
    num translateMix = this.translateMix;
    bool translate = translateMix > 0;
    bool rotate = rotateMix > 0;
    if (!translate && !rotate) return;

    PathConstraintData data = this.data;
    SpacingMode spacingMode = data.spacingMode;
    bool lengthSpacing = spacingMode == SpacingMode.length;
    RotateMode rotateMode = data.rotateMode;
    bool tangents = rotateMode == RotateMode.tangent;
    bool scale = rotateMode == RotateMode.chainScale;
    int boneCount = this.bones.length;
    int spacesCount = tangents ? boneCount : boneCount + 1;

    List<Bone> bones = this.bones;
    if (_spaces.length != spacesCount) _spaces = new Float32List(spacesCount);
    Float32List spaces = _spaces;
    Float32List lengths = null;
    num spacing = this.spacing;

    if (scale || lengthSpacing) {
      if (scale) {
        if (_lengths.length != boneCount) _lengths = new Float32List(boneCount);
        lengths = _lengths;
      }

      for (int i = 0; i < spacesCount - 1;) {
        Bone bone = bones[i];
        num length = bone.data.length;
        num x = length * bone.a;
        num y = length * bone.c;
        length = math.sqrt(x * x + y * y);
        if (scale) lengths[i] = length;
        spaces[++i] = lengthSpacing ? math.max(0.0, length + spacing) : spacing;
      }
    } else {
      for (int i = 1; i < spacesCount; i++) {
        spaces[i] = spacing;
      }
    }

    Float32List positions = _computeWorldPositions(
        attachment, spacesCount, tangents,
        data.positionMode == PositionMode.percent,
        spacingMode == SpacingMode.percent);

    num boneX = positions[0];
    num boneY = positions[1];
    num offsetRotation = data.offsetRotation;
    bool tip = rotateMode == RotateMode.chain && offsetRotation == 0;
    int p = 3;

    for (int i = 0; i < boneCount; i++, p += 3) {
      Bone bone = bones[i];
      bone._worldX += (boneX - bone.worldX) * translateMix;
      bone._worldY += (boneY - bone.worldY) * translateMix;
      num x = positions[p + 0];
      num y = positions[p + 1];
      num dx = x - boneX;
      num dy = y - boneY;

      if (scale) {
        num length = lengths[i];
        if (length != 0) {
          num s = (math.sqrt(dx * dx + dy * dy) / length - 1) * rotateMix + 1;
          bone._a *= s;
          bone._c *= s;
        }
      }

      boneX = x;
      boneY = y;

      if (rotate) {
        num a = bone.a;
        num b = bone.b;
        num c = bone.c;
        num d = bone.d;
        num r = 0.0;
        num cos = 0.0;
        num sin = 0.0;

        if (tangents) {
          r = positions[p - 1];
        } else if (spaces[i + 1] == 0) {
          r = positions[p + 2];
        } else {
          r = math.atan2(dy, dx);
        }

        r -= math.atan2(c, a) - offsetRotation * deg2rad;

        if (tip) {
          cos = math.cos(r);
          sin = math.sin(r);
          num length = bone.data.length;
          boneX += (length * (cos * a - sin * c) - dx) * rotateMix;
          boneY += (length * (sin * a + cos * c) - dy) * rotateMix;
        }

        if (r > math.PI) {
          r -= (math.PI * 2);
        } else if (r < -math.PI) {
          r += (math.PI * 2);
        }

        r *= rotateMix;
        cos = math.cos(r);
        sin = math.sin(r);
        bone._a = cos * a - sin * c;
        bone._b = cos * b - sin * d;
        bone._c = sin * a + cos * c;
        bone._d = sin * b + cos * d;
      }
      bone.appliedValid = false;
    }
  }

  Float32List _computeWorldPositions(PathAttachment path, int spacesCount,
      bool tangents, bool percentPosition, bool percentSpacing) {

    Slot target = this.target;
    num position = this.position;
    Float32List spaces = _spaces;

    int positionCount = spacesCount * 3 + 2;
    if (_positions.length != positionCount) {
      _positions = new Float32List(positionCount);
    }

    Float32List out = _positions;
    Float32List world;
    bool closed = path.closed;
    int verticesLength = path.worldVerticesLength;
    int curveCount = verticesLength ~/ 6;
    int prevCurve = _NONE;

    if (!path.constantSpeed) {
      Float32List lengths = path.lengths;
      curveCount -= closed ? 1 : 2;
      num pathLength = lengths[curveCount];
      if (percentPosition) position *= pathLength;
      if (percentSpacing) {
        for (int i = 0; i < spacesCount; i++)
          spaces[i] *= pathLength;
      }

      if (_world.length != 8) _world = new Float32List(8);
      world = _world;
      int o = 0, curve = 0;

      for (int i = 0; i < spacesCount; i++, o += 3) {
        num space = spaces[i];
        position += space;
        num p = position;

        if (closed) {
          p %= pathLength;
          if (p < 0) p += pathLength;
          curve = 0;
        } else if (p < 0) {
          if (prevCurve != _BEFORE) {
            prevCurve = _BEFORE;
            path.computeWorldVertices2(target, 2, 4, world, 0);
          }
          _addBeforePosition(p, world, 0, out, o);
          continue;
        } else if (p > pathLength) {
          if (prevCurve != _AFTER) {
            prevCurve = _AFTER;
            path.computeWorldVertices2(target, verticesLength - 6, 4, world, 0);
          }
          _addAfterPosition(p - pathLength, world, 0, out, o);
          continue;
        }

        // Determine curve containing position.
        for (;; curve++) {
          num length = lengths[curve];
          if (p > length && curve < lengths.length - 1) continue;
          if (curve == 0)
            p /= length;
          else {
            num prev = lengths[curve - 1];
            p = (p - prev) / (length - prev);
          }
          break;
        }

        if (curve != prevCurve) {
          prevCurve = curve;
          if (closed && curve == curveCount) {
            path.computeWorldVertices2(target, verticesLength - 4, 4, world, 0);
            path.computeWorldVertices2(target, 0, 4, world, 4);
          } else {
            path.computeWorldVertices2(target, curve * 6 + 2, 8, world, 0);
          }
        }

        _addCurvePosition(p,
            world[0], world[1], world[2], world[3],
            world[4], world[5], world[6], world[7],
            out, o, tangents || (i > 0 && space == 0));
      }
      return out;
    }

    // World vertices.

    if (closed) {
      verticesLength += 2;
      if (_world.length != verticesLength) _world = new Float32List(verticesLength);
      world = _world;
      path.computeWorldVertices2(target, 2, verticesLength - 4, world, 0);
      path.computeWorldVertices2(target, 0, 2, world, verticesLength - 4);
      world[verticesLength - 2] = world[0];
      world[verticesLength - 1] = world[1];
    } else {
      curveCount--;
      verticesLength -= 4;
      if (_world.length != verticesLength) _world = new Float32List(verticesLength);
      world = _world;
      path.computeWorldVertices2(target, 2, verticesLength, world, 0);
    }

    // Curve lengths.

    if (_curves.length != curveCount) _curves = new Float32List(curveCount);

    Float32List curves = _curves;
    num pathLength = 0.0;
    num x1 = world[0], y1 = world[1];
    num cx1 = 0.0, cy1 = 0.0;
    num cx2 = 0.0, cy2 = 0.0;
    num x2 = 0.0, y2 = 0.0;
    num tmpx = 0.0, tmpy = 0.0;
    num dddfx = 0.0, dddfy = 0.0;
    num ddfx = 0.0, ddfy = 0.0;
    num dfx = 0.0, dfy = 0.0;
    int w = 2;

    for (int i = 0; i < curveCount; i++, w += 6) {
      cx1 = world[w];
      cy1 = world[w + 1];
      cx2 = world[w + 2];
      cy2 = world[w + 3];
      x2 = world[w + 4];
      y2 = world[w + 5];
      tmpx = (x1 - cx1 * 2 + cx2) * 0.1875;
      tmpy = (y1 - cy1 * 2 + cy2) * 0.1875;
      dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.09375;
      dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.09375;
      ddfx = tmpx * 2 + dddfx;
      ddfy = tmpy * 2 + dddfy;
      dfx = (cx1 - x1) * 0.75 + tmpx + dddfx * 0.16666667;
      dfy = (cy1 - y1) * 0.75 + tmpy + dddfy * 0.16666667;
      pathLength += math.sqrt(dfx * dfx + dfy * dfy);
      dfx += ddfx;
      dfy += ddfy;
      ddfx += dddfx;
      ddfy += dddfy;
      pathLength += math.sqrt(dfx * dfx + dfy * dfy);
      dfx += ddfx;
      dfy += ddfy;
      pathLength += math.sqrt(dfx * dfx + dfy * dfy);
      dfx += ddfx + dddfx;
      dfy += ddfy + dddfy;
      pathLength += math.sqrt(dfx * dfx + dfy * dfy);
      curves[i] = pathLength;
      x1 = x2;
      y1 = y2;
    }

    if (percentPosition) {
      position *= pathLength;
    }

    if (percentSpacing) {
      for (int i = 0; i < spacesCount; i++) {
        spaces[i] *= pathLength;
      }
    }

    Float32List segments = _segments;
    num curveLength = 0.0;
    int segment = 0;
    int o = 0;
    int curve = 0;

    for (int i = 0; i < spacesCount; i++, o += 3) {
      num space = spaces[i];
      position += space;
      num p = position;

      if (closed) {
        p %= pathLength;
        if (p < 0) p += pathLength;
        curve = 0;
      } else if (p < 0) {
        _addBeforePosition(p, world, 0, out, o);
        continue;
      } else if (p > pathLength) {
        _addAfterPosition(p - pathLength, world, verticesLength - 4, out, o);
        continue;
      }

      // Determine curve containing position.

      for (;; curve++) {
        num length = curves[curve];
        if (p > length && curve < curves.length - 1) continue;
        if (curve == 0)
          p /= length;
        else {
          num prev = curves[curve - 1];
          p = (p - prev) / (length - prev);
        }
        break;
      }

      // Curve segment lengths.

      if (curve != prevCurve) {
        prevCurve = curve;
        int ii = curve * 6;
        x1 = world[ii];
        y1 = world[ii + 1];
        cx1 = world[ii + 2];
        cy1 = world[ii + 3];
        cx2 = world[ii + 4];
        cy2 = world[ii + 5];
        x2 = world[ii + 6];
        y2 = world[ii + 7];

        tmpx = (x1 - cx1 * 2 + cx2) * 0.03;
        tmpy = (y1 - cy1 * 2 + cy2) * 0.03;
        dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.006;
        dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.006;
        ddfx = tmpx * 2 + dddfx;
        ddfy = tmpy * 2 + dddfy;
        dfx = (cx1 - x1) * 0.3 + tmpx + dddfx * 0.16666667;
        dfy = (cy1 - y1) * 0.3 + tmpy + dddfy * 0.16666667;
        curveLength = math.sqrt(dfx * dfx + dfy * dfy);
        segments[0] = curveLength;

        for (ii = 1; ii < 8; ii++) {
          dfx += ddfx;
          dfy += ddfy;
          ddfx += dddfx;
          ddfy += dddfy;
          curveLength += math.sqrt(dfx * dfx + dfy * dfy);
          segments[ii] = curveLength;
        }

        dfx += ddfx;
        dfy += ddfy;
        curveLength += math.sqrt(dfx * dfx + dfy * dfy);
        segments[8] = curveLength;
        dfx += ddfx + dddfx;
        dfy += ddfy + dddfy;
        curveLength += math.sqrt(dfx * dfx + dfy * dfy);
        segments[9] = curveLength;
        segment = 0;
      }

      // Weight by segment length.

      p *= curveLength;

      for (;; segment++) {
        num length = segments[segment];
        if (p > length && segment < segments.length - 1) continue;
        if (segment == 0) {
          p /= length;
        } else {
          num prev = segments[segment - 1];
          p = segment + (p - prev) / (length - prev);
        }
        break;
      }

      _addCurvePosition(p * 0.1,
          x1, y1, cx1, cy1, cx2, cy2, x2, y2,
          out, o, tangents || (i > 0 && space == 0));
    }
    return out;
  }

  void _addBeforePosition(num p, Float32List temp, int i, Float32List out, int o) {
    num x1 = temp[i + 0];
    num y1 = temp[i + 1];
    num dx = temp[i + 2] - x1;
    num dy = temp[i + 3] - y1;
    num r = math.atan2(dy, dx);
    out[o + 0] = x1 + p * math.cos(r);
    out[o + 1] = y1 + p * math.sin(r);
    out[o + 2] = r;
  }

  void _addAfterPosition(num p, Float32List temp, int i, Float32List out, int o) {
    num x1 = temp[i + 2];
    num y1 = temp[i + 3];
    num dx = x1 - temp[i];
    num dy = y1 - temp[i + 1];
    num r = math.atan2(dy, dx);
    out[o + 0] = x1 + p * math.cos(r);
    out[o + 1] = y1 + p * math.sin(r);
    out[o + 2] = r;
  }

  void _addCurvePosition(num p,
      num x1, num y1, num cx1, num cy1, num cx2, num cy2, num x2, num y2,
      Float32List out, int o, bool tangents) {

    if (p == 0 || p.isNaN) p = 0.0001;
    num tt = p * p;
    num ttt = tt * p;
    num u = 1.0 - p;
    num uu = u * u;
    num uuu = uu * u;
    num ut = u * p;
    num ut3 = ut * 3;
    num uut3 = u * ut3;
    num utt3 = ut3 * p;
    num x = x1 * uuu + cx1 * uut3 + cx2 * utt3 + x2 * ttt;
    num y = y1 * uuu + cy1 * uut3 + cy2 * utt3 + y2 * ttt;
    out[o + 0] = x;
    out[o + 1] = y;

    if (tangents) {
      out[o + 2] = math.atan2(
          y - (y1 * uu + cy1 * ut * 2 + cy2 * tt),
          x - (x1 * uu + cx1 * ut * 2 + cx2 * tt));
    }
  }

  @override
  int getOrder() => data.order;

  @override
  String toString() => data.name;
}
