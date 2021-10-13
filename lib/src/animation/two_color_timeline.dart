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

class TwoColorTimeline extends CurveTimeline {
  static const int _ENTRIES = 8;
  static const int _PREV_TIME = -8;
  static const int _PREV_R1 = -7;
  static const int _PREV_G1 = -6;
  static const int _PREV_B1 = -5;
  static const int _PREV_A1 = -4;
  static const int _PREV_R2 = -3;
  static const int _PREV_G2 = -2;
  static const int _PREV_B2 = -1;
  static const int _TIME = 0;
  static const int _R1 = 1;
  static const int _G1 = 2;
  static const int _B1 = 3;
  static const int _A1 = 4;
  static const int _R2 = 5;
  static const int _G2 = 6;
  static const int _B2 = 7;

  int slotIndex = 0;
  final Float32List frames; // time, r, g, b, a, ...

  TwoColorTimeline(int frameCount)
      : frames = Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.twoColor.ordinal << 24) + slotIndex;
  }

  /// Sets the time and value of the specified keyframe.
  void setFrame(int frameIndex, double time, double r, double g, double b, double a, double r2,
      double g2, double b2) {
    frameIndex *= TwoColorTimeline._ENTRIES;
    this.frames[frameIndex] = time;
    this.frames[frameIndex + TwoColorTimeline._R1] = r;
    this.frames[frameIndex + TwoColorTimeline._G1] = g;
    this.frames[frameIndex + TwoColorTimeline._B1] = b;
    this.frames[frameIndex + TwoColorTimeline._A1] = a;
    this.frames[frameIndex + TwoColorTimeline._R2] = r2;
    this.frames[frameIndex + TwoColorTimeline._G2] = g2;
    this.frames[frameIndex + TwoColorTimeline._B2] = b2;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    Slot slot = skeleton.slots[slotIndex];
    double r1 = 0.0;
    double g1 = 0.0;
    double b1 = 0.0;
    double a1 = 0.0;
    double r2 = 0.0;
    double g2 = 0.0;
    double b2 = 0.0;

    if (time < frames[0]) {
      if (pose == MixPose.setup) {
        slot.color.setFromColor(slot.data.color);
        if (slot.data.darkColor != null) {
          slot.darkColor?.setFromColor(slot.data.darkColor!);
        }
      } else if (pose == MixPose.current && slot.darkColor != null && slot.data.darkColor != null) {
        var l1 = slot.color;
        var d1 = slot.darkColor!;
        var l2 = slot.data.color;
        var s2 = slot.data.darkColor!;
        l1.add((l2.r - l1.r) * alpha, (l2.g - l1.g) * alpha, (l2.b - l1.b) * alpha,
            (l2.a - l1.a) * alpha);
        d1.add((s2.r - d1.r) * alpha, (s2.g - d1.g) * alpha, (s2.b - d1.b) * alpha, 0.0);
      }
      return;
    }

    if (time >= frames[frames.length - _ENTRIES]) {
      // Time is after last frame.
      r1 = frames[frames.length + _PREV_R1];
      g1 = frames[frames.length + _PREV_G1];
      b1 = frames[frames.length + _PREV_B1];
      a1 = frames[frames.length + _PREV_A1];
      r2 = frames[frames.length + _PREV_R2];
      g2 = frames[frames.length + _PREV_G2];
      b2 = frames[frames.length + _PREV_B2];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, _ENTRIES);

      double t0 = frames[frame + _PREV_TIME];
      double r01 = frames[frame + _PREV_R1];
      double g01 = frames[frame + _PREV_G1];
      double b01 = frames[frame + _PREV_B1];
      double a01 = frames[frame + _PREV_A1];
      double r02 = frames[frame + _PREV_R2];
      double g02 = frames[frame + _PREV_G2];
      double b02 = frames[frame + _PREV_B2];

      double t1 = frames[frame + _TIME];
      double r11 = frames[frame + _R1];
      double g11 = frames[frame + _G1];
      double b11 = frames[frame + _B1];
      double a11 = frames[frame + _A1];
      double r12 = frames[frame + _R2];
      double g12 = frames[frame + _G2];
      double b12 = frames[frame + _B2];

      double between = 1.0 - (time - t1) / (t0 - t1);
      double percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);

      r1 = r01 + (r11 - r01) * percent;
      g1 = g01 + (g11 - g01) * percent;
      b1 = b01 + (b11 - b01) * percent;
      a1 = a01 + (a11 - a01) * percent;
      r2 = r02 + (r12 - r02) * percent;
      g2 = g02 + (g12 - g02) * percent;
      b2 = b02 + (b12 - b02) * percent;
    }

    if (alpha == 1.0) {
      slot.color.setFrom(r1, g1, b1, a1);
      slot.darkColor?.setFrom(r2, g2, b2, 1.0);
    } else {
      var light = slot.color;
      var dark = slot.darkColor;
      if (pose == MixPose.setup) {
        light.setFromColor(slot.data.color);
        if (slot.data.darkColor != null) {
          dark?.setFromColor(slot.data.darkColor!);
        }
      }
      light.add((r1 - light.r) * alpha, (g1 - light.g) * alpha, (b1 - light.b) * alpha,
          (a1 - light.a) * alpha);
      dark?.add((r2 - dark.r) * alpha, (g2 - dark.g) * alpha, (b2 - dark.b) * alpha, 0.0);
    }
  }
}
