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
      :	frames = new Float32List(frameCount * _ENTRIES),
		    super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.transformConstraint.ordinal << 24) + transformConstraintIndex;
  }

	/// Sets the time and mixes of the specified keyframe.

  void setFrame (int frameIndex, num time, num rotateMix, num translateMix, num scaleMix, num shearMix) {
		frameIndex *= _ENTRIES;
		frames[frameIndex + _TIME] = time;
		frames[frameIndex + _ROTATE] = rotateMix;
		frames[frameIndex + _TRANSLATE] = translateMix;
		frames[frameIndex + _SCALE] = scaleMix;
		frames[frameIndex + _SHEAR] = shearMix;
	}

	@override
  void apply(
			Skeleton skeleton, num lastTime, num time, List<Event> firedEvents,
			num alpha, bool setupPose, bool mixingOut) {

    Float32List frames = this.frames;
		if (time < frames[0]) return; // Time is before first frame.

    TransformConstraint constraint = skeleton.transformConstraints[transformConstraintIndex];

		num rotate = 0, translate = 0, scale = 0, shear = 0;
		if (time >= frames[frames.length - _ENTRIES]) { // Time is after last frame.
			int i = frames.length;
			rotate = frames[i + _PREV_ROTATE];
			translate = frames[i + _PREV_TRANSLATE];
			scale = frames[i + _PREV_SCALE];
			shear = frames[i + _PREV_SHEAR];
		} else {
			// Interpolate between the previous frame and the current frame.
			int frame = Animation.binarySearch(frames, time, _ENTRIES);
			rotate = frames[frame + _PREV_ROTATE];
			translate = frames[frame + _PREV_TRANSLATE];
			scale = frames[frame + _PREV_SCALE];
			shear = frames[frame + _PREV_SHEAR];
			num frameTime = frames[frame];
			num percent = getCurvePercent(frame ~/ _ENTRIES - 1, 1 - (time - frameTime) / (frames[frame + _PREV_TIME] - frameTime));

			rotate += (frames[frame + _ROTATE] - rotate) * percent;
			translate += (frames[frame + _TRANSLATE] - translate) * percent;
			scale += (frames[frame + _SCALE] - scale) * percent;
			shear += (frames[frame + _SHEAR] - shear) * percent;
		}

		if (setupPose) {
      TransformConstraintData data = constraint.data;
			constraint.rotateMix = data.rotateMix + (rotate - data.rotateMix) * alpha;
			constraint.translateMix = data.translateMix + (translate - data.translateMix) * alpha;
			constraint.scaleMix = data.scaleMix + (scale - data.scaleMix) * alpha;
			constraint.shearMix = data.shearMix + (shear - data.shearMix) * alpha;
		} else {
			constraint.rotateMix += (rotate - constraint.rotateMix) * alpha;
			constraint.translateMix += (translate - constraint.translateMix) * alpha;
			constraint.scaleMix += (scale - constraint.scaleMix) * alpha;
			constraint.shearMix += (shear - constraint.shearMix) * alpha;
		}
	}
}
