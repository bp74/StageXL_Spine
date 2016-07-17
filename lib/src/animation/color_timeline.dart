/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class ColorTimeline extends CurveTimeline {

  static const int _ENTRIES = 5;
  static const int _PREV_TIME = -5;
  static const int _PREV_R = -4;
  static const int _PREV_G = -3;
  static const int _PREV_B = -2;
  static const int _PREV_A = -1;
  static const int _TIME = 0;
  static const int _R = 1;
  static const int _G = 2;
  static const int _B = 3;
  static const int _A = 4;

  final Float32List frames; // time, r, g, b, a, ...
  int slotIndex = 0;

  ColorTimeline(int frameCount)
      : frames = new Float32List(frameCount * 5),
        super(frameCount);

  /// Sets the time and value of the specified keyframe.
  ///
  void setFrame(int frameIndex, num time, num r, num g, num b, num a) {
    frameIndex *= _ENTRIES;
    frames[frameIndex + _TIME] = time.toDouble();
    frames[frameIndex + _R] = r.toDouble();
    frames[frameIndex + _G] = g.toDouble();
    frames[frameIndex + _B] = b.toDouble();
    frames[frameIndex + _A] = a.toDouble();
  }

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0 + _TIME]) return; // Time is before first frame.

    num r = 0.0, g = 0.0, b = 0.0, a = 0.0, t = 0.0;

    if (time >= frames[frames.length + _PREV_TIME]) {

      // Time is after last frame.
      r = frames[frames.length + _PREV_R];
      g = frames[frames.length + _PREV_G];
      b = frames[frames.length + _PREV_B];
      a = frames[frames.length + _PREV_A];

    } else {

      // Interpolate between the previous frame and the current frame.

      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      t = frames[frame + _PREV_TIME];
      r = frames[frame + _PREV_R];
      g = frames[frame + _PREV_G];
      b = frames[frame + _PREV_B];
      a = frames[frame + _PREV_A];

      num ft = frames[frame + _TIME];
      num p = getCurvePercent(frame ~/ _ENTRIES - 1, 1 - (time - ft) / (t - ft));

      r += (frames[frame + _R] - r) * p;
      g += (frames[frame + _G] - g) * p;
      b += (frames[frame + _B] - b) * p;
      a += (frames[frame + _A] - a) * p;
    }

    Slot slot = skeleton.slots[slotIndex];

    if (alpha < 1) {
      slot.r += (r - slot.r) * alpha;
      slot.g += (g - slot.g) * alpha;
      slot.b += (b - slot.b) * alpha;
      slot.a += (a - slot.a) * alpha;
    } else {
      slot.r = r;
      slot.g = g;
      slot.b = b;
      slot.a = a;
    }
  }

}
