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

class PathConstraintMixTimeline extends CurveTimeline {
  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_ROTATE = -2;
  static const int _PREV_TRANSLATE = -1;
  static const int _TIME = 0;
  static const int _ROTATE = 1;
  static const int _TRANSLATE = 2;

  int pathConstraintIndex = 0;

  final Float32List frames; // time, rotate mix, translate mix, ...

  PathConstraintMixTimeline(int frameCount)
      : frames = Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.pathConstraintMix.ordinal << 24) + pathConstraintIndex;
  }

  /// Sets the time and mixes of the specified keyframe.

  void setFrame(int frameIndex, double time, double rotateMix, double translateMix) {
    frameIndex *= _ENTRIES;
    frames[frameIndex + _TIME] = time;
    frames[frameIndex + _ROTATE] = rotateMix;
    frames[frameIndex + _TRANSLATE] = translateMix;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    PathConstraint pc = skeleton.pathConstraints[pathConstraintIndex];
    PathConstraintData data = pc.data;
    double rot = 0.0;
    double tra = 0.0;

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        pc.rotateMix = data.rotateMix;
        pc.translateMix = data.translateMix;
      } else if (pose == MixPose.current) {
        pc.rotateMix += (data.rotateMix - pc.rotateMix) * alpha;
        pc.translateMix += (data.translateMix - pc.translateMix) * alpha;
      }
      return;
    }

    if (time >= frames[frames.length + _PREV_TIME]) {
      // Time is after last frame.
      rot = frames[frames.length + _PREV_ROTATE];
      tra = frames[frames.length + _PREV_TRANSLATE];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      double tim0 = frames[frame + _PREV_TIME];
      double rot0 = frames[frame + _PREV_ROTATE];
      double tra0 = frames[frame + _PREV_TRANSLATE];
      double tim1 = frames[frame + _TIME];
      double rot1 = frames[frame + _ROTATE];
      double tra1 = frames[frame + _TRANSLATE];
      double between = 1.0 - (time - tim1) / (tim0 - tim1);
      double percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);
      rot = rot0 + (rot1 - rot0) * percent;
      tra = tra0 + (tra1 - tra0) * percent;
    }

    if (pose == MixPose.setup) {
      pc.rotateMix = data.rotateMix + (rot - data.rotateMix) * alpha;
      pc.translateMix = data.translateMix + (tra - data.translateMix) * alpha;
    } else {
      pc.rotateMix = pc.rotateMix + (rot - pc.rotateMix) * alpha;
      pc.translateMix = pc.translateMix + (tra - pc.translateMix) * alpha;
    }
  }
}
