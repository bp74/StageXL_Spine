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

class ScaleTimeline extends TranslateTimeline {

  ScaleTimeline(int frameCount) : super(frameCount);

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) {

      // Time is before first frame.

    } else if (time >= frames[frames.length + TranslateTimeline._PREV_TIME]) {

      // Time is after last frame.

      Bone bone = skeleton.bones[boneIndex];
      num prevX = frames[frames.length + TranslateTimeline._PREV_X];
      num prevY = frames[frames.length + TranslateTimeline._PREV_Y];
      bone.scaleX += (bone.data.scaleX * prevX - bone.scaleX) * alpha;
      bone.scaleY += (bone.data.scaleY * prevY - bone.scaleY) * alpha;

    } else {

      // Interpolate between the previous frame and the current frame.

      Bone bone = skeleton.bones[boneIndex];
      int frame = Animation.binarySearch(frames, time, TranslateTimeline._ENTRIES);
      num prevTime = frames[frame + TranslateTimeline._PREV_TIME];
      num prevX = frames[frame + TranslateTimeline._PREV_X];
      num prevY = frames[frame + TranslateTimeline._PREV_Y];
      num frameTime = frames[frame + TranslateTimeline._TIME];
      num frameX = frames[frame + TranslateTimeline._X];
      num frameY = frames[frame + TranslateTimeline._Y];

      num between = 1.0 - (time - frameTime) / (prevTime - frameTime);
      num percent = getCurvePercent(frame ~/ TranslateTimeline._ENTRIES - 1, between);

      bone.scaleX += (bone.data.scaleX * (prevX + (frameX - prevX) * percent) - bone.scaleX) * alpha;
      bone.scaleY += (bone.data.scaleY * (prevY + (frameY - prevY) * percent) - bone.scaleY) * alpha;

    }
  }
}
