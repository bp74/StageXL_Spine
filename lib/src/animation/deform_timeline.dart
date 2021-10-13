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

class DeformTimeline extends CurveTimeline {
  final Float32List frames;
  final List<Float32List?> frameVertices;

  int slotIndex = 0;
  VertexAttachment attachment;

  DeformTimeline(int frameCount, this.attachment)
      : frames = Float32List(frameCount),
        frameVertices = List<Float32List?>.filled(frameCount, null),
        super(frameCount);

  @override
  int getPropertyId() {
    return (TimelineType.deform.ordinal << 27) + attachment.id + slotIndex;
  }

  /// Sets the time and value of the specified keyframe.

  void setFrame(int frameIndex, double time, Float32List vertices) {
    frames[frameIndex] = time;
    frameVertices[frameIndex] = vertices;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    Slot slot = skeleton.slots[slotIndex];
    if (slot.attachment is! VertexAttachment) return;

    var vertexAttachment = slot.attachment as VertexAttachment;
    if (vertexAttachment.applyDeform(attachment) == false) return;

    var vertexCount = frameVertices[0]!.length;
    var targetVertices = slot.attachmentVertices;
    if (targetVertices.isEmpty) alpha = 1.0;
    var setupVertices = vertexAttachment.vertices;

    //-----------------------

    if (time < frames[0]) {
      if (pose == MixPose.setup) {
        targetVertices = _resizeList(targetVertices, 0);
      } else if (pose != MixPose.current) {
        // do nothing
      } else if (alpha == 1.0) {
        targetVertices = _resizeList(targetVertices, 0);
      } else if (vertexAttachment.bones == null) {
        // Unweighted vertex positions.
        targetVertices = _resizeList(targetVertices, vertexCount);
        for (int i = 0; i < vertexCount; i++) {
          targetVertices[i] += (setupVertices[i] - targetVertices[i]) * alpha;
        }
      } else {
        // Weighted deform offsets.
        targetVertices = _resizeList(targetVertices, vertexCount);
        alpha = 1.0 - alpha;
        for (int i = 0; i < vertexCount; i++) {
          targetVertices[i] *= alpha;
        }
      }
      slot.attachmentVertices = targetVertices;
      return;
    }

    //-----------------------

    targetVertices = _resizeList(targetVertices, vertexCount);
    slot.attachmentVertices = targetVertices;

    if (time >= frames[frames.length - 1]) {
      // Time is after last frame.
      Float32List lastVertices = frameVertices[frames.length - 1]!;
      if (alpha == 1.0) {
        // Vertex positions or deform offsets, no alpha.
        for (int i = 0; i < vertexCount; i++) {
          targetVertices[i] = lastVertices[i];
        }
      } else if (pose != MixPose.setup) {
        // Vertex positions or deform offsets, with alpha.
        for (int i = 0; i < vertexCount; i++) {
          double v0 = targetVertices[i];
          double v1 = lastVertices[i];
          targetVertices[i] = v0 + (v1 - v0) * alpha;
        }
      } else if (vertexAttachment.bones == null) {
        // Unweighted vertex positions, with alpha.
        for (int i = 0; i < vertexCount; i++) {
          double v0 = setupVertices[i];
          double v1 = lastVertices[i];
          targetVertices[i] = v0 + (v1 - v0) * alpha;
        }
      } else {
        // Weighted deform offsets, with alpha.
        for (int i = 0; i < vertexCount; i++) {
          targetVertices[i] = lastVertices[i] * alpha;
        }
      }
      return;
    }

    //-----------------------

    // Interpolate between the previous frame and the current frame.
    int frame = Animation.binarySearch1(frames, time);
    double t0 = frames[frame - 1];
    double t1 = frames[frame + 0];
    Float32List v0List = frameVertices[frame - 1]!;
    Float32List v1List = frameVertices[frame + 0]!;
    double between = 1.0 - (time - t1) / (t0 - t1);
    double percent = getCurvePercent(frame - 1, between);

    if (alpha == 1.0) {
      // Vertex positions or deform offsets, no alpha.
      for (int i = 0; i < vertexCount; i++) {
        double v0 = v0List[i];
        targetVertices[i] = v0 + (v1List[i] - v0) * percent;
      }
    } else if (pose != MixPose.setup) {
      // Vertex positions or deform offsets, with alpha.
      for (int i = 0; i < vertexCount; i++) {
        double v0 = v0List[i];
        double v1 = v1List[i];
        double vx = targetVertices[i];
        targetVertices[i] = vx + (v0 + (v1 - v0) * percent - vx) * alpha;
      }
    } else if (vertexAttachment.bones == null) {
      // Unweighted vertex positions, with alpha.
      for (int i = 0; i < vertexCount; i++) {
        double v0 = v0List[i];
        double v1 = v1List[i];
        double vx = setupVertices[i];
        targetVertices[i] = vx + (v0 + (v1 - v0) * percent - vx) * alpha;
      }
    } else {
      // Weighted deform offsets, with alpha.
      for (int i = 0; i < vertexCount; i++) {
        double v0 = v0List[i];
        double v1 = v1List[i];
        targetVertices[i] = (v0 + (v1 - v0) * percent) * alpha;
      }
    }
  }

  Float32List _resizeList(Float32List oldList, int length) {
    if (oldList.length == length) return oldList;
    var newList = Float32List(length);
    for (int i = 0; i < newList.length && i < oldList.length; i++) {
      newList[i] = oldList[i];
    }
    return newList;
  }
}
