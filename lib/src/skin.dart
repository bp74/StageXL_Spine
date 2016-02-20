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

/// Stores attachments by slot index and attachment name.
///
class Skin {

  final String name;
  final List<Map> attachments = new List<Map>();

  Skin(this.name) {
    if (name == null) throw new ArgumentError("name cannot be null.");
  }

  void addAttachment(int slotIndex, String name, Attachment attachment) {
    if (attachment == null) throw new ArgumentError("attachment cannot be null.");
    if (slotIndex >= attachments.length) attachments.length = slotIndex + 1;
    if (attachments[slotIndex] == null) attachments[slotIndex] = new Map();
    attachments[slotIndex][name] = attachment;
  }

  Attachment getAttachment(int slotIndex, String name) {
    if (slotIndex >= attachments.length) return null;
    Map map = attachments[slotIndex];
    return map != null ? map[name] : null;
  }

  /// Attach each attachment in this skin if the corresponding attachment in
  /// the old skin is currently attached.
  ///
  void attachAll(Skeleton skeleton, Skin oldSkin) {
    int slotIndex = 0;
    for (Slot slot in skeleton.slots) {
      Attachment slotAttachment = slot.attachment;
      if (slotAttachment != null && slotIndex < oldSkin.attachments.length) {
        Map map = oldSkin.attachments[slotIndex];
        for (var name in map.keys) {
          Attachment skinAttachment = map[name];
          if (slotAttachment == skinAttachment) {
            Attachment attachment = getAttachment(slotIndex, name);
            if (attachment != null) slot.attachment = attachment;
            break;
          }
        }
      }
      slotIndex++;
    }
  }

  String toString() => name;
}
