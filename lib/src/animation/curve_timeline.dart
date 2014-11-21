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

/// Base class for frames that use an interpolation bezier curve.
///
class CurveTimeline implements Timeline {

  static const num _LINEAR = 0.0;
  static const num _STEPPED = 1.0;
  static const num _BEZIER = 2.0;
  static const int _BEZIER_SEGMENTS = 10;
  static const int _BEZIER_SIZE = _BEZIER_SEGMENTS * 2 - 1;

  final Float32List _curves; // type, x, y, ...

  CurveTimeline(int frameCount) :
    _curves = new Float32List((frameCount - 1) * _BEZIER_SIZE);

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {
  }

  int get frameCount => _curves.length ~/ _BEZIER_SIZE + 1;

  void setLinear(int frameIndex) {
    _curves[frameIndex * _BEZIER_SIZE] = _LINEAR;
  }

  void setStepped(int frameIndex) {
    _curves[frameIndex * _BEZIER_SIZE] = _STEPPED;
  }

  /// Sets the control handle positions for an interpolation bezier curve
  /// used to transition from this keyframe to the next.
  ///
  /// cx1 and cx2 are from 0 to 1, representing the percent of time between
  /// the two keyframes. cy1 and cy2 are the percent of the difference between
  /// the keyframe's values.
  ///
  void setCurve(int frameIndex, num cx1, num cy1, num cx2, num cy2) {

    num subdiv1 = 1 / _BEZIER_SEGMENTS;
    num subdiv2 = subdiv1 * subdiv1;
    num subdiv3 = subdiv2 * subdiv1;
    num pre1 = 3 * subdiv1;
    num pre2 = 3 * subdiv2;
    num pre4 = 6 * subdiv2;
    num pre5 = 6 * subdiv3;
    num tmp1x = -cx1 * 2 + cx2;
    num tmp1y = -cy1 * 2 + cy2;
    num tmp2x = (cx1 - cx2) * 3 + 1;
    num tmp2y = (cy1 - cy2) * 3 + 1;
    num dfx = cx1 * pre1 + tmp1x * pre2 + tmp2x * subdiv3;
    num dfy = cy1 * pre1 + tmp1y * pre2 + tmp2y * subdiv3;
    num ddfx = tmp1x * pre4 + tmp2x * pre5;
    num ddfy = tmp1y * pre4 + tmp2y * pre5;
    num dddfx = tmp2x * pre5;
    num dddfy = tmp2y * pre5;

    int i = frameIndex * _BEZIER_SIZE;
    _curves[i++] = _BEZIER;

    num x = dfx;
    num y = dfy;

    for (int n = i + _BEZIER_SIZE - 1; i < n; i += 2) {
      _curves[i + 0] = x;
      _curves[i + 1] = y;
      dfx += ddfx;
      dfy += ddfy;
      ddfx += dddfx;
      ddfy += dddfy;
      x += dfx;
      y += dfy;
    }
  }

  num getCurvePercent(int frameIndex, num percent) {

    int i = frameIndex * _BEZIER_SIZE;
    num type = _curves[i];
    if (type == _LINEAR) return percent;
    if (type == _STEPPED) return 0;
    i++;

    num x = 0.0;
    for (int start = i, n = i + _BEZIER_SIZE - 1; i < n; i += 2) {
      x = _curves[i];
      if (x >= percent) {
        num prevX = (i == start) ? 0.0 : _curves[i - 2];
        num prevY = (i == start) ? 0.0 : _curves[i - 1];
        return prevY + (_curves[i + 1] - prevY) * (percent - prevX) / (x - prevX);
      }
    }

    num y = _curves[i - 1];
    return y + (1 - y) * (percent - x) / (1 - x); // Last point is 1,1.
  }
}
