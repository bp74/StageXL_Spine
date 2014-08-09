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

	int slotIndex;
	List<num> frames;
	List<List<num>> frameVertices;
	Attachment attachment;

	FfdTimeline(int frameCount) : super(frameCount) {
		frames = new List<num>.filled(frameCount, 0);
		frameVertices = new List<List<num>>.filled(frameCount, null);
	}

	/// Sets the time and value of the specified keyframe.
	///
	void setFrame(int frameIndex, num time, List<num> vertices) {
		frames[frameIndex] = time;
		frameVertices[frameIndex] = vertices;
	}

	void apply(Skeleton skeleton, num lastTime, num time, List<Event> firedEvents, num alpha) {

	  Slot slot = skeleton.slots[slotIndex];
		if (slot.attachment != attachment) return;

		List<num> frames = this.frames;

		if (time < frames[0]) {
			slot.attachmentVertices.length = 0;
			return; // Time is before first frame.
		}

		List<List<num>> frameVertices = this.frameVertices;
		int vertexCount = frameVertices[0].length;

		List<num> vertices = slot.attachmentVertices;
		if (vertices.length != vertexCount) alpha = 1;
		vertices.length = vertexCount;

		if (time >= frames[frames.length - 1]) { // Time is after last frame.

		  List<num> lastVertices = frameVertices[frames.length - 1];

			if (alpha < 1) {
				for (int i = 0; i < vertexCount; i++) {
					vertices[i] += (lastVertices[i] - vertices[i]) * alpha;
				}
			} else {
				for (int i = 0; i < vertexCount; i++) {
					vertices[i] = lastVertices[i];
				}
			}

			return;
		}

		// Interpolate between the previous frame and the current frame.

		int frameIndex = Animation.binarySearch(frames, time, 1);
		num frameTime = frames[frameIndex];
		num percent = 1 - (time - frameTime) / (frames[frameIndex - 1] - frameTime);
		percent = getCurvePercent(frameIndex - 1, percent < 0 ? 0 : (percent > 1 ? 1 : percent));

		List<num> prevVertices = frameVertices[frameIndex - 1];
		List<num> nextVertices = frameVertices[frameIndex];

		num prev;

		if (alpha < 1) {
			for (int i = 0; i < vertexCount; i++) {
				prev = prevVertices[i];
				vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
			}
		} else {
			for (int i = 0; i < vertexCount; i++) {
				prev = prevVertices[i];
				vertices[i] = prev + (nextVertices[i] - prev) * percent;
			}
		}
	}

}
