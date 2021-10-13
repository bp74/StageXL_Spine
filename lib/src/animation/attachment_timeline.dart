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

class AttachmentTimeline implements Timeline {
  final Float32List frames; // time, ...
  final List<String?> attachmentNames;
  int slotIndex = 0;

  AttachmentTimeline(int frameCount)
      : frames = Float32List(frameCount),
        attachmentNames = List<String?>.filled(frameCount, null);

  int get frameCount => frames.length;

  @override
  int getPropertyId() {
    return (TimelineType.attachment.ordinal << 24) + slotIndex;
  }

  /// Sets the time and value of the specified keyframe.
  ///
  void setFrame(int frameIndex, double time, String attachmentName) {
    frames[frameIndex] = time.toDouble();
    attachmentNames[frameIndex] = attachmentName;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    String? attachmentName;
    Slot slot = skeleton.slots[slotIndex];

    if (direction == MixDirection.Out && pose == MixPose.setup) {
      attachmentName = slot.data.attachmentName;
      slot.attachment = attachmentName == null
          ? null
          : skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName);
      return;
    }

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        attachmentName = slot.data.attachmentName;
        slot.attachment = attachmentName == null
            ? null
            : skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName);
      }
      return;
    }

    int frameIndex = (time >= frames.last)
        ? frames.length - 1 // Time is after last frame.
        : Animation.binarySearch(frames, time, 1) - 1;

    attachmentName = attachmentNames[frameIndex];
    skeleton.slots[slotIndex].attachment = (attachmentName != null)
        ? skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName)
        : null;
  }
}
