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

class Slot {

  SlotData _data;  // internal
  Bone _bone;  // internal
  Skeleton _skeleton;  // internal

	num r;
	num g;
	num b;
	num a;

	Attachment _attachment;  // internal
	num _attachmentTime;
	List<num> attachmentVertices = new List<num>();

	Slot (SlotData data, Skeleton skeleton, Bone bone) {
		if (data == null) throw new ArgumentError("data cannot be null.");
		if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
		if (bone == null) throw new ArgumentError("bone cannot be null.");
		_data = data;
		_skeleton = skeleton;
		_bone = bone;
		setToSetupPose();
	}

	SlotData get data => _data;
	Skeleton get skeleton => _skeleton;
	Bone get bone => _bone;

	Attachment get attachment => _attachment;

	void set attachment(Attachment attachment) {
    _attachment = attachment;
		_attachmentTime = _skeleton.time;
		attachmentVertices.length = 0;
	}

  /// Returns the time since the attachment was set.
  num get attachmentTime => skeleton.time - _attachmentTime;

	void set attachmentTime (num time) {
		_attachmentTime = skeleton.time - time;
	}

	void setToSetupPose() {
		int slotIndex = skeleton.data.slots.indexOf(data);
		r = _data.r;
		g = _data.g;
		b = _data.b;
		a = _data.a;
		attachment = _data.attachmentName == null
		    ? null : skeleton.getAttachmentForSlotIndex(slotIndex, data.attachmentName);
	}

	String toString() => _data.name;
}
