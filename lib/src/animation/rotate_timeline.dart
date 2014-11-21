/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 *
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class RotateTimeline extends CurveTimeline {

  static const int _PREV_FRAME_TIME = -2;
  static const int _FRAME_VALUE = 1;

  final Float32List frames; // time, value, ...
  int boneIndex = 0;

  RotateTimeline(int frameCount)
      : super(frameCount),
        frames = new Float32List(frameCount * 2);

  /// Sets the time and angle of the specified keyframe.

  void setFrame(int frameIndex, num time, num angle) {
    frameIndex = frameIndex << 1;
    frames[frameIndex + 0] = time.toDouble();
    frames[frameIndex + 1] = angle.toDouble();
  }

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    if (time < frames[0]) return; // Time is before first frame.

    Bone bone = skeleton.bones[boneIndex];

    num amount;

    if (time >= frames[frames.length - 2]) { // Time is after last frame.
      amount = bone.data.rotation + frames[frames.length - 1] - bone.rotation;
      while (amount > 180) amount -= 360;
      while (amount < -180) amount += 360;
      bone.rotation += amount * alpha;
      return;
    }

    // Interpolate between the previous frame and the current frame.

    int frameIndex = Animation.binarySearch(frames, time, 2);
    num prevFrameValue = frames[frameIndex - 1];
    num frameTime = frames[frameIndex];
    num percent = 1 - (time - frameTime) / (frames[frameIndex + _PREV_FRAME_TIME] - frameTime);
    percent = getCurvePercent(frameIndex ~/ 2 - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

    amount = frames[frameIndex + _FRAME_VALUE] - prevFrameValue;
    while (amount > 180) amount -= 360;
    while (amount < -180) amount += 360;
    amount = bone.data.rotation + (prevFrameValue + amount * percent) - bone.rotation;
    while (amount > 180) amount -= 360;
    while (amount < -180) amount += 360;
    bone.rotation += amount * alpha;
  }
}
