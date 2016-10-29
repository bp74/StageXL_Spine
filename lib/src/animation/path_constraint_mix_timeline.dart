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

	PathConstraintMixTimeline (int frameCount)
      : frames = new Float32List(frameCount * _ENTRIES),
        super(frameCount);

	/// Sets the time and mixes of the specified keyframe.

  void setFrame(int frameIndex, num time, num rotateMix, num translateMix) {
		frameIndex *= _ENTRIES;
		frames[frameIndex + _TIME] = time;
		frames[frameIndex + _ROTATE] = rotateMix;
		frames[frameIndex + _TRANSLATE] = translateMix;
	}

	@override
  void apply (Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) {

      // Time is before first frame.

		} else if (time >= frames[frames.length + _PREV_TIME]) {

      // Time is after last frame.

      PathConstraint constraint = skeleton.pathConstraints[pathConstraintIndex];
      num prevRotate = frames[frames.length + _PREV_ROTATE];
      num prevTranslate = frames[frames.length + _PREV_TRANSLATE];
      constraint.rotateMix += (prevRotate - constraint.rotateMix) * alpha;
			constraint.translateMix += (prevTranslate - constraint.translateMix) * alpha;

		} else {

      // Interpolate between the previous frame and the current frame.

      PathConstraint constraint = skeleton.pathConstraints[pathConstraintIndex];
      int frame = Animation.binarySearch(frames, time, _ENTRIES);
      num prevTime = frames[frame + _PREV_TIME];
      num prevRotate = frames[frame + _PREV_ROTATE];
      num prevTranslate = frames[frame + _PREV_TRANSLATE];
      num frameTime = frames[frame + _TIME];
      num frameRotate = frames[frame + _ROTATE];
      num frameTranslate = frames[frame + _TRANSLATE];

      num between = 1.0 - (time - frameTime) / (prevTime - frameTime);
      num percent = getCurvePercent(frame ~/ _ENTRIES - 1, between);

      constraint.rotateMix += (prevRotate + (frameRotate - prevRotate) * percent - constraint.rotateMix) * alpha;
      constraint.translateMix += (prevTranslate + (frameTranslate - prevTranslate) * percent - constraint.translateMix) * alpha;
    }
	}
}
