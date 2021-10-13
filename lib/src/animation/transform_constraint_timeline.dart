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

class TransformConstraintTimeline extends CurveTimeline {
  static const int _ENTRIES = 5;
  static const int _PREV_TIME = -5;
  static const int _PREV_ROTATE = -4;
  static const int _PREV_TRANSLATE = -3;
  static const int _PREV_SCALE = -2;
  static const int _PREV_SHEAR = -1;
  static const int _TIME = 0;
  static const int _ROTATE = 1;
  static const int _TRANSLATE = 2;
  static const int _SCALE = 3;
  static const int _SHEAR = 4;

  int transformConstraintIndex = 0;

  final Float32List frames; // time, rotate mix, translate mix, scale mix, shear mix, ...

  TransformConstraintTimeline(int frameCount)
      : frames = Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.transformConstraint.ordinal << 24) + transformConstraintIndex;
  }

  /// Sets the time and mixes of the specified keyframe.

  void setFrame(int frameIndex, double time, double rotateMix, double translateMix, double scaleMix,
      double shearMix) {
    frameIndex *= _ENTRIES;
    frames[frameIndex + _TIME] = time;
    frames[frameIndex + _ROTATE] = rotateMix;
    frames[frameIndex + _TRANSLATE] = translateMix;
    frames[frameIndex + _SCALE] = scaleMix;
    frames[frameIndex + _SHEAR] = shearMix;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    List<TransformConstraint> tcs = skeleton.transformConstraints;
    TransformConstraint tc = tcs[transformConstraintIndex];
    TransformConstraintData data = tc.data;
    double rot = 0.0; // rotate
    double tra = 0.0; // translate
    double sca = 0.0; // scale
    double she = 0.0; // shear

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        tc.rotateMix = data.rotateMix;
        tc.translateMix = data.translateMix;
        tc.scaleMix = data.scaleMix;
        tc.shearMix = data.shearMix;
      } else if (pose == MixPose.current) {
        tc.rotateMix += (data.rotateMix - tc.rotateMix) * alpha;
        tc.translateMix += (data.translateMix - tc.translateMix) * alpha;
        tc.scaleMix += (data.scaleMix - tc.scaleMix) * alpha;
        tc.shearMix += (data.shearMix - tc.shearMix) * alpha;
      }
      return;
    }

    if (time >= frames[frames.length + _PREV_TIME]) {
      // Time is after last frame.
      rot = frames[frames.length + _PREV_ROTATE];
      tra = frames[frames.length + _PREV_TRANSLATE];
      sca = frames[frames.length + _PREV_SCALE];
      she = frames[frames.length + _PREV_SHEAR];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      double tim0 = frames[frame + _PREV_TIME];
      double rot0 = frames[frame + _PREV_ROTATE];
      double tra0 = frames[frame + _PREV_TRANSLATE];
      double sca0 = frames[frame + _PREV_SCALE];
      double she0 = frames[frame + _PREV_SHEAR];
      double tim1 = frames[frame + _TIME];
      double rot1 = frames[frame + _ROTATE];
      double tra1 = frames[frame + _TRANSLATE];
      double sca1 = frames[frame + _SCALE];
      double she1 = frames[frame + _SHEAR];
      double between = 1.0 - (time - tim1) / (tim0 - tim1);
      double percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);
      rot = rot0 + (rot1 - rot0) * percent;
      tra = tra0 + (tra1 - tra0) * percent;
      sca = sca0 + (sca1 - sca0) * percent;
      she = she0 + (she1 - she0) * percent;
    }

    if (pose == MixPose.setup) {
      tc.rotateMix = data.rotateMix + (rot - data.rotateMix) * alpha;
      tc.translateMix = data.translateMix + (tra - data.translateMix) * alpha;
      tc.scaleMix = data.scaleMix + (sca - data.scaleMix) * alpha;
      tc.shearMix = data.shearMix + (she - data.shearMix) * alpha;
    } else {
      tc.rotateMix = tc.rotateMix + (rot - tc.rotateMix) * alpha;
      tc.translateMix = tc.translateMix + (tra - tc.translateMix) * alpha;
      tc.scaleMix = tc.scaleMix + (sca - tc.scaleMix) * alpha;
      tc.shearMix = tc.shearMix + (she - tc.shearMix) * alpha;
    }
  }
}
