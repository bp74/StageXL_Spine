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

class ColorTimeline extends CurveTimeline {

  static const int _FRAME_TIME = 0;
  static const int _FRAME_R = 1;
  static const int _FRAME_G = 2;
  static const int _FRAME_B = 3;
  static const int _FRAME_A = 4;

  final Float32List frames; // time, r, g, b, a, ...
  int slotIndex = 0;

  ColorTimeline(int frameCount)
      : super(frameCount),
        frames = new Float32List(frameCount * 5);

  /// Sets the time and value of the specified keyframe.
  ///
  void setFrame(int frameIndex, num time, num r, num g, num b, num a) {
    frameIndex *= 5;
    frames[frameIndex + 0] = time.toDouble();
    frames[frameIndex + 1] = r.toDouble();
    frames[frameIndex + 2] = g.toDouble();
    frames[frameIndex + 3] = b.toDouble();
    frames[frameIndex + 4] = a.toDouble();
  }

  @override
  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    num r, g, b, a;

    if (time < frames[0 + _FRAME_TIME]) {
      return; // Time is before first frame.
    }

    // The following code contains dart2js_hints

    int lastFrameIndex = frames.length - 5;
    if (lastFrameIndex < 0) throw new RangeError("");

    if (time >= frames[lastFrameIndex]) {

      // Time is after last frame.

      r = frames[lastFrameIndex + _FRAME_R];
      g = frames[lastFrameIndex + _FRAME_G];
      b = frames[lastFrameIndex + _FRAME_B];
      a = frames[lastFrameIndex + _FRAME_A];

    } else {

      // Interpolate between the previous frame and the current frame.

      int frameIndex = Animation.binarySearch(frames, time, 5);
      if (frameIndex > frames.length - 5) throw new RangeError("");
      if (frameIndex < 5) throw new RangeError("");

      num prevFrameTime = frames[frameIndex - 5];
      num prevFrameR    = frames[frameIndex - 4];
      num prevFrameG    = frames[frameIndex - 3];
      num prevFrameB    = frames[frameIndex - 2];
      num prevFrameA    = frames[frameIndex - 1];
      num frameTime     = frames[frameIndex - 0];

      num percent = 1 - (time - frameTime) / (prevFrameTime - frameTime);
      percent = getCurvePercent(frameIndex ~/ 5 - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

      r = prevFrameR + (frames[frameIndex + _FRAME_R] - prevFrameR) * percent;
      g = prevFrameG + (frames[frameIndex + _FRAME_G] - prevFrameG) * percent;
      b = prevFrameB + (frames[frameIndex + _FRAME_B] - prevFrameB) * percent;
      a = prevFrameA + (frames[frameIndex + _FRAME_A] - prevFrameA) * percent;
    }

    Slot slot = skeleton.slots[slotIndex];

    if (alpha < 1) {
      slot.r += (r - slot.r) * alpha;
      slot.g += (g - slot.g) * alpha;
      slot.b += (b - slot.b) * alpha;
      slot.a += (a - slot.a) * alpha;
    } else {
      slot.r = r;
      slot.g = g;
      slot.b = b;
      slot.a = a;
    }
  }

}
