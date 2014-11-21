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

class FfdTimeline extends CurveTimeline {

  final Float32List frames;
  final List<Float32List> frameVertices;
  Attachment attachment = null;
  int slotIndex = 0;

  FfdTimeline(int frameCount)
      : super(frameCount),
        frames = new Float32List(frameCount),
        frameVertices = new List<Float32List>(frameCount);

  /// Sets the time and value of the specified keyframe.
  ///
  void setFrame(int frameIndex, num time, Float32List vertices) {
    frames[frameIndex] = time.toDouble();
    frameVertices[frameIndex] = vertices;
  }

  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

    Slot slot = skeleton.slots[slotIndex];
    if (slot.attachment != attachment) return;

    Float32List frames = this.frames;
    if (time < frames[0]) return; // Time is before first frame.

    Float32List attachmentVertices = slot.attachmentVertices;
    List<Float32List> frameVertices = this.frameVertices;
    int vertexCount = frameVertices[0].length;

    if (attachmentVertices.length != vertexCount) {
      attachmentVertices = slot.attachmentVertices = new Float32List(vertexCount);
      alpha = 1; // Don't mix from uninitialized slot vertices.
    }

    if (time >= frames[frames.length - 1]) { // Time is after last frame.

      Float32List lastVertices = frameVertices[frames.length - 1];

      if (alpha < 1) {
        for (int i = 0; i < vertexCount; i++) {
          attachmentVertices[i] += (lastVertices[i] - attachmentVertices[i]) * alpha;
        }
      } else {
        for (int i = 0; i < vertexCount; i++) {
          attachmentVertices[i] = lastVertices[i];
        }
      }

      return;
    }

    // Interpolate between the previous frame and the current frame.

    int frameIndex = Animation.binarySearch1(frames, time);
    num frameTime = frames[frameIndex];
    num percent = 1 - (time - frameTime) / (frames[frameIndex - 1] - frameTime);
    percent = getCurvePercent(frameIndex - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

    Float32List prevVertices = frameVertices[frameIndex - 1];
    Float32List nextVertices = frameVertices[frameIndex];

    num prev;

    if (alpha < 1) {
      for (int i = 0; i < vertexCount; i++) {
        prev = prevVertices[i];
        attachmentVertices[i] += (prev + (nextVertices[i] - prev) * percent - attachmentVertices[i]) * alpha;
      }
    } else {
      for (int i = 0; i < vertexCount; i++) {
        prev = prevVertices[i];
        attachmentVertices[i] = prev + (nextVertices[i] - prev) * percent;
      }
    }
  }

}
