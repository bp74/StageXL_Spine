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

class IkConstraintTimeline extends CurveTimeline {
  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_MIX = -2;
  static const int _PREV_BEND_DIRECTION = -1;
  static const int _TIME = 0;
  static const int _MIX = 1;
  static const int _BEND_DIRECTION = 2;

  final Float32List frames; // time, mix, bendDirection, ...
  int ikConstraintIndex = 0;

  IkConstraintTimeline(int frameCount)
      : frames = Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.ikConstraint.ordinal << 24) + ikConstraintIndex;
  }

  /// Sets the time, mix and bend direction of the specified keyframe.

  void setFrame(int frameIndex, double time, double mix, int bendDirection) {
    frameIndex *= _ENTRIES;
    frames[frameIndex + _TIME] = time;
    frames[frameIndex + _MIX] = mix;
    frames[frameIndex + _BEND_DIRECTION] = bendDirection.toDouble();
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    IkConstraint constraint = skeleton.ikConstraints[ikConstraintIndex];
    IkConstraintData data = constraint.data;
    double m = 0.0;
    double b = 0.0;

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        constraint.mix = data.mix;
        constraint.bendDirection = data.bendDirection;
      } else if (pose == MixPose.current) {
        constraint.mix += (constraint.data.mix - constraint.mix) * alpha;
        constraint.bendDirection = constraint.data.bendDirection;
      }
      return;
    }

    if (time >= frames[frames.length + _PREV_TIME]) {
      // Time is after last frame.
      m = frames[frames.length + _PREV_MIX];
      b = frames[frames.length + _PREV_BEND_DIRECTION];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      double t0 = frames[frame + _PREV_TIME];
      double m0 = frames[frame + _PREV_MIX];
      double b0 = frames[frame + _PREV_BEND_DIRECTION];
      double t1 = frames[frame + _TIME];
      double m1 = frames[frame + _MIX];
      double between = 1.0 - (time - t1) / (t0 - t1);
      double percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);
      m = m0 + (m1 - m0) * percent;
      b = b0;
    }

    if (pose == MixPose.setup) {
      constraint.mix = data.mix + (m - data.mix) * alpha;
      constraint.bendDirection = direction == MixDirection.Out ? data.bendDirection : b.toInt();
    } else {
      constraint.mix = constraint.mix + (m - constraint.mix) * alpha;
      if (direction == MixDirection.In) constraint.bendDirection = b.toInt();
    }
  }
}
