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

class TranslateTimeline extends CurveTimeline {

  static const int _ENTRIES = 3;
  static const int _PREV_TIME = -3;
  static const int _PREV_X = -2;
  static const int _PREV_Y = -1;
  static const int _TIME = 0;
  static const int _X = 1;
  static const int _Y = 2;

  final Float32List frames; // time, value, value, ...
  int boneIndex = 0;

  TranslateTimeline(int frameCount)
      : frames = new Float32List(frameCount * 3),
        super(frameCount);

  /// Sets the time and value of the specified keyframe.

  void setFrame(int frameIndex, num time, num x, num y) {
    frameIndex *= 3;
    frames[frameIndex + 0] = time.toDouble();
    frames[frameIndex + 1] = x.toDouble();
    frames[frameIndex + 2] = y.toDouble();
  }

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) {

      // Time is before first frame.

    } else if (time >= frames[frames.length + _PREV_TIME]) {

      // Time is after last frame.

      Bone bone = skeleton.bones[boneIndex];
      num prevX = frames[frames.length + _PREV_X];
      num prevY = frames[frames.length + _PREV_Y];
      bone.x += (bone.data.x + prevX - bone.x) * alpha;
      bone.y += (bone.data.y + prevY - bone.y) * alpha;

    } else {

      // Interpolate between the previous frame and the current frame.

      Bone bone = skeleton.bones[boneIndex];
      int frameIndex = Animation.binarySearch(frames, time, 3);
      num prevTime = frames[frameIndex + _PREV_TIME];
      num prevX = frames[frameIndex + _PREV_X];
      num prevY = frames[frameIndex + _PREV_Y];
      num frameTime = frames[frameIndex + _TIME];
      num frameX = frames[frameIndex + _X];
      num frameY = frames[frameIndex + _Y];

      num between = 1.0 - (time - frameTime) / (prevTime - frameTime);
      num percent = getCurvePercent(frameIndex ~/ _ENTRIES - 1, between);

      bone.x += (bone.data.x + prevX + (frameX - prevX) * percent - bone.x) * alpha;
      bone.y += (bone.data.y + prevY + (frameY - prevY) * percent - bone.y) * alpha;
    }
  }
}
