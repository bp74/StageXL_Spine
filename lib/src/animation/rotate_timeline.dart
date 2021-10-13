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

class RotateTimeline extends CurveTimeline {
  static const int _ENTRIES = 2;
  static const int _PREV_TIME = -2;
  static const int _PREV_ROTATION = -1;
  static const int _TIME = 0;
  static const int _ROTATION = 1;

  final Float32List frames; // time, degrees, ...
  int boneIndex = 0;

  RotateTimeline(int frameCount)
      : frames = Float32List(frameCount * _ENTRIES),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.rotate.ordinal << 24) + boneIndex;
  }

  /// Sets the time and angle of the specified keyframe.

  void setFrame(int frameIndex, double time, double degrees) {
    frameIndex = frameIndex << 1;
    frames[frameIndex + _TIME] = time.toDouble();
    frames[frameIndex + _ROTATION] = degrees.toDouble();
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    Bone bone = skeleton.bones[boneIndex];
    double rotation = 0.0;

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        bone.rotation = bone.data.rotation;
      } else if (pose == MixPose.current) {
        rotation = bone.data.rotation - bone.rotation;
        bone.rotation += _wrapRotation(rotation) * alpha;
      }
      return;
    }

    if (time >= frames[frames.length + _PREV_TIME]) {
      // Time is after last frame.
      rotation = frames[frames.length + _PREV_ROTATION];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      double t0 = frames[frame + _PREV_TIME];
      double r0 = frames[frame + _PREV_ROTATION];
      double t1 = frames[frame + _TIME];
      double r1 = frames[frame + _ROTATION];
      double between = 1.0 - (time - t1) / (t0 - t1);
      double percent = getCurvePercent((frame >> 1) - 1, between);
      rotation = r0 + _wrapRotation(r1 - r0) * percent;
    }

    if (pose == MixPose.setup) {
      bone.rotation = bone.data.rotation + _wrapRotation(rotation) * alpha;
    } else {
      rotation = bone.data.rotation - bone.rotation + rotation;
      bone.rotation = bone.rotation + _wrapRotation(rotation) * alpha;
    }
  }
}
