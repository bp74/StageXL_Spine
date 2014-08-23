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
  static const num _STEPPED = -1.0;
  static const int _BEZIER_SEGMENTS = 10;

  final Float32List _curves; // dfx, dfy, ddfx, ddfy, dddfx, dddfy, ...

  CurveTimeline(int frameCount) : _curves = new Float32List(frameCount * 6);

  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {
  }

  int get frameCount => _curves.length ~/ 6;

  void setLinear(int frameIndex) {
    _curves[frameIndex * 6] = _LINEAR;
  }

  void setStepped(int frameIndex) {
    _curves[frameIndex * 6] = _STEPPED;
  }

  /// Sets the control handle positions for an interpolation bezier curve
  /// used to transition from this keyframe to the next.
  ///
  /// cx1 and cx2 are from 0 to 1, representing the percent of time between
  /// the two keyframes. cy1 and cy2 are the percent of the difference between
  /// the keyframe's values.
  ///
  void setCurve(int frameIndex, num cx1, num cy1, num cx2, num cy2) {

    num subdiv_step = 1 / _BEZIER_SEGMENTS;
    num subdiv_step2 = subdiv_step * subdiv_step;
    num subdiv_step3 = subdiv_step2 * subdiv_step;

    num pre1 = 3 * subdiv_step;
    num pre2 = 3 * subdiv_step2;
    num pre4 = 6 * subdiv_step2;
    num pre5 = 6 * subdiv_step3;

    num tmp1x = -cx1 * 2.0 + cx2;
    num tmp1y = -cy1 * 2.0 + cy2;
    num tmp2x = (cx1 - cx2) * 3.0 + 1.0;
    num tmp2y = (cy1 - cy2) * 3.0 + 1.0;

    int i = frameIndex * 6;

    _curves[i + 0] = cx1 * pre1 + tmp1x * pre2 + tmp2x * subdiv_step3;
    _curves[i + 1] = cy1 * pre1 + tmp1y * pre2 + tmp2y * subdiv_step3;
    _curves[i + 2] = tmp1x * pre4 + tmp2x * pre5;
    _curves[i + 3] = tmp1y * pre4 + tmp2y * pre5;
    _curves[i + 4] = tmp2x * pre5;
    _curves[i + 5] = tmp2y * pre5;
  }

  num getCurvePercent(int frameIndex, num percent) {

    int curveIndex = frameIndex * 6;
    num dfx = _curves[curveIndex];
    if (dfx == _LINEAR) return percent;
    if (dfx == _STEPPED) return 0;

    if (curveIndex > _curves.length - 6) throw new RangeError("");

    num dfy = _curves[curveIndex + 1];
    num ddfx = _curves[curveIndex + 2];
    num ddfy = _curves[curveIndex + 3];
    num dddfx = _curves[curveIndex + 4];
    num dddfy = _curves[curveIndex + 5];
    num x = dfx;
    num y = dfy;

    int i = _BEZIER_SEGMENTS - 2;

    while (true) {

      if (x >= percent) {
        num prevX = x - dfx;
        num prevY = y - dfy;
        return prevY + (y - prevY) * (percent - prevX) / (x - prevX);
      }

      if (i == 0) break;

      i--;
      dfx += ddfx;
      dfy += ddfy;
      ddfx += dddfx;
      ddfy += dddfy;
      x += dfx;
      y += dfy;
    }

    return y + (1 - y) * (percent - x) / (1 - x); // Last point is 1,1.
  }
}
