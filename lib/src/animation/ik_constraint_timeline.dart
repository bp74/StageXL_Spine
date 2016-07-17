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

class IkConstraintTimeline extends CurveTimeline {

  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_MIX = -2;
  static const int _PREV_BEND_DIRECTION = -1;
  static const int _TIME = 0;
  static const int _MIX = 1;
  static const int _BEND_DIRECTION = 2;

  final Float32List frames;  // time, mix, bendDirection, ...
  int ikConstraintIndex = 0;

  IkConstraintTimeline(int frameCount)
      : frames = new Float32List(frameCount * _ENTRIES),
        super(frameCount);

  /// Sets the time, mix and bend direction of the specified keyframe.

  void setFrame (int frameIndex, num time, num mix, int bendDirection) {
    frameIndex *= _ENTRIES;
    frames[frameIndex + _TIME] = time;
    frames[frameIndex + _MIX] = mix;
    frames[frameIndex + _BEND_DIRECTION] = bendDirection.toDouble();
  }

  @override
  void apply (Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) {

      // Time is before first frame.

    } else if (time >= frames[frames.length + _PREV_TIME]) {

      // Time is after last frame.

      IkConstraint constraint = skeleton.ikConstraints[ikConstraintIndex];
      num prevMix = frames[frames.length + _PREV_MIX];
      num prevBendDirection = frames[frames.length + _PREV_BEND_DIRECTION];
      constraint.mix += (prevMix - constraint.mix) * alpha;
      constraint.bendDirection = prevBendDirection.round();

    } else {

      // Interpolate between the previous frame and the current frame.

      IkConstraint constraint = skeleton.ikConstraints[ikConstraintIndex];
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      num prevTime = frames[frame + _PREV_TIME];
      num prevMix = frames[frame + _PREV_MIX];
      num prevBendDirection = frames[frames.length + _PREV_BEND_DIRECTION];
      num frameTime = frames[frame + _TIME];
      num frameMix = frames[frame + _MIX];

      num between = 1.0 - (time - frameTime) / (prevTime - frameTime);
      num percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);

      constraint.mix += (prevMix + (frameMix - prevMix) * percent - constraint.mix) * alpha;
      constraint.bendDirection = prevBendDirection.toInt();
    }
  }
}
