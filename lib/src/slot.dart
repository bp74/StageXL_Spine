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

class Slot {

  final SlotData data;
  final Bone bone;

  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  Attachment _attachment = null;
  num _attachmentTime = 0;
  Float32List attachmentVertices = new Float32List(0);

  Slot(this.data, this.bone) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    if (bone == null) throw new ArgumentError("bone cannot be null.");
    setToSetupPose();
  }

  Skeleton get skeleton => bone.skeleton;

  Attachment get attachment => _attachment;

  void set attachment(Attachment attachment) {
    if (_attachment == attachment) return;
    _attachment = attachment;
    _attachmentTime = bone.skeleton.time;
    attachmentVertices = new Float32List(0);
  }

  /// Returns the time since the attachment was set.
  num get attachmentTime => bone.skeleton.time - _attachmentTime;

  void set attachmentTime(num time) {
    _attachmentTime = bone.skeleton.time - time;
  }

  void setToSetupPose() {
    r = data.r;
    g = data.g;
    b = data.b;
    a = data.a;
    if (data.attachmentName == null) {
      attachment = null;
    } else {
      _attachment = null;
      attachment = bone.skeleton.getAttachmentForSlotIndex(data.index, data.attachmentName);
    }
  }

  String toString() => data.name;
}
