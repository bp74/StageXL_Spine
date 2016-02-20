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

class ScaleTimeline extends TranslateTimeline {

  ScaleTimeline(int frameCount) : super(frameCount);

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) return; // Time is before first frame.

    Bone bone = skeleton.bones[boneIndex];

    if (time >= frames[frames.length - 3]) { // Time is after last frame.
      bone.scaleX += (bone.data.scaleX * frames[frames.length - 2] - bone.scaleX) * alpha;
      bone.scaleY += (bone.data.scaleY * frames[frames.length - 1] - bone.scaleY) * alpha;
      return;
    }

    // Interpolate between the previous frame and the current frame.

    int frameIndex = Animation.binarySearch(frames, time, 3);
    num prevFrameX = frames[frameIndex - 2];
    num prevFrameY = frames[frameIndex - 1];
    num frameTime = frames[frameIndex];
    num percent = 1 - (time - frameTime) / (frames[frameIndex + TranslateTimeline._PREV_FRAME_TIME] - frameTime);
    percent = getCurvePercent(frameIndex ~/ 3 - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

    bone.scaleX += (bone.data.scaleX * (prevFrameX + (frames[frameIndex + TranslateTimeline._FRAME_X] - prevFrameX) * percent) - bone.scaleX) * alpha;
    bone.scaleY += (bone.data.scaleY * (prevFrameY + (frames[frameIndex + TranslateTimeline._FRAME_Y] - prevFrameY) * percent) - bone.scaleY) * alpha;
  }
}
