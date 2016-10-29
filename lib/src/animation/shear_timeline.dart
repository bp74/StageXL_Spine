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
 
class ShearTimeline extends TranslateTimeline {

  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_X = -2;
  static const int _PREV_Y = -1;
  static const int _TIME = 0;
  static const int _X = 1;
  static const int _Y = 2;

  ShearTimeline (int frameCount) : super(frameCount);

  @override
  int getPropertyId () {
    return (TimelineType.shear.ordinal << 24) + boneIndex;
  }

	@override
  void apply(
			Skeleton skeleton, num lastTime, num time, List<Event> firedEvents,
			num alpha, bool setupPose, bool mixingOut) {

    Float32List frames = this.frames;
		if (time < frames[0]) return; // Time is before first frame.

		Bone bone = skeleton.bones[boneIndex];

		num x = 0, y = 0;
		if (time >= frames[frames.length - _ENTRIES]) { // Time is after last frame.
			x = frames[frames.length + _PREV_X];
			y = frames[frames.length + _PREV_Y];
		} else {
			// Interpolate between the previous frame and the current frame.
			int frame = Animation.binarySearch(frames, time, _ENTRIES);
			x = frames[frame + _PREV_X];
			y = frames[frame + _PREV_Y];
			num frameTime = frames[frame];
			num percent = getCurvePercent(frame ~/ _ENTRIES - 1, 1 - (time - frameTime) / (frames[frame + _PREV_TIME] - frameTime));
			x = x + (frames[frame + _X] - x) * percent;
			y = y + (frames[frame + _Y] - y) * percent;
		}

		if (setupPose) {
			bone.shearX = bone.data.shearX + x * alpha;
			bone.shearY = bone.data.shearY + y * alpha;
		} else {
			bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
			bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
		}
	}
}

