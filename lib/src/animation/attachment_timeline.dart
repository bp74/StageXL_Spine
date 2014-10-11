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

class AttachmentTimeline implements Timeline {

  final Float32List frames; // time, ...
  final List<String> attachmentNames;
  int slotIndex = 0;

  AttachmentTimeline(int frameCount)
      : frames = new Float32List(frameCount),
        attachmentNames = new List<String>.filled(frameCount, null);

  int get frameCount => frames.length;

  /// Sets the time and value of the specified keyframe.
  ///
  void setFrame(int frameIndex, num time, String attachmentName) {
    frames[frameIndex] = time.toDouble();
    attachmentNames[frameIndex] = attachmentName;
  }

  void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {
    
    if (time < this.frames[0]) {
      if (lastTime > time) apply(skeleton, lastTime, double.MAX_FINITE, null, 0);
      return;
    } else if (lastTime > time) {
      lastTime = -1;
    }

    int frameIndex = time >= this.frames[this.frames.length - 1] 
      ? this.frames.length - 1 
      : Animation.binarySearch1(this.frames, time) - 1;
    
    if (this.frames[frameIndex] < lastTime) return;
        
    String attachmentName = attachmentNames[frameIndex];
    skeleton.slots[slotIndex].attachment = (attachmentName != null) 
        ? skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName)
        : null;
  }
}
