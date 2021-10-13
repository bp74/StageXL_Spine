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

class DrawOrderTimeline implements Timeline {
  final Float32List frames; // time, ...
  final List<Int16List?> drawOrders;

  DrawOrderTimeline(int frameCount)
      : frames = Float32List(frameCount),
        drawOrders = List<Int16List?>.filled(frameCount, null);

  @override
  int getPropertyId() {
    return TimelineType.drawOrder.ordinal << 24;
  }

  int get frameCount => frames.length;

  /// Sets the time and value of the specified keyframe.

  void setFrame(int frameIndex, double time, Int16List? drawOrder) {
    frames[frameIndex] = time.toDouble();
    drawOrders[frameIndex] = drawOrder;
  }

  @override
  void apply(Skeleton skeleton, double lastTime, double time, List<SpineEvent>? firedEvents,
      double alpha, MixPose pose, MixDirection direction) {
    List<Slot> drawOrder = skeleton.drawOrder;
    List<Slot> slots = skeleton.slots;

    if (direction == MixDirection.Out && pose == MixPose.setup) {
      for (int i = 0; i < slots.length; i++) {
        drawOrder[i] = slots[i];
      }
      return;
    }

    if (time < frames[0]) {
      // Time is before first frame.
      if (pose == MixPose.setup) {
        for (int i = 0; i < slots.length; i++) {
          drawOrder[i] = slots[i];
        }
      }
      return;
    }

    int frameIndex = 0;

    if (time >= frames[frames.length - 1]) {
      // Time is after last frame.
      frameIndex = frames.length - 1;
    } else {
      frameIndex = Animation.binarySearch1(frames, time) - 1;
    }

    Int16List? drawOrderToSetupIndex = drawOrders[frameIndex];

    if (drawOrderToSetupIndex == null) {
      for (int i = 0; i < slots.length; i++) {
        drawOrder[i] = slots[i];
      }
    } else {
      for (int i = 0; i < drawOrderToSetupIndex.length; i++) {
        drawOrder[i] = slots[drawOrderToSetupIndex[i]];
      }
    }
  }
}
