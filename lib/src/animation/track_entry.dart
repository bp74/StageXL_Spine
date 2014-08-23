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

typedef void TrackEntryAction<T extends TrackEntryActionArgs>(T trackEntryActionArgs);

abstract class TrackEntryActionArgs {
  final int trackIndex;
  TrackEntryActionArgs(this.trackIndex);
}

class TrackEntryStartArgs extends TrackEntryActionArgs {
  TrackEntryStartArgs(int trackIndex) : super(trackIndex);
}

class TrackEntryEndArgs extends TrackEntryActionArgs {
  TrackEntryEndArgs(int trackIndex) : super(trackIndex);
}

class TrackEntryCompleteArgs extends TrackEntryActionArgs {
  final int count;
  TrackEntryCompleteArgs(int trackIndex, this.count) : super(trackIndex);
}

class TrackEntryEventArgs extends TrackEntryActionArgs {
  final Event event;
  TrackEntryEventArgs(int trackIndex, this.event) : super(trackIndex);
}

//-------------------------------------------------------------------------------------------------

class TrackEntry {

  TrackEntry next = null;
  TrackEntry _previous = null;

  Animation animation = null;
  bool loop = false;
  num delay = 0.0;

  num time = 0.0;
  num lastTime = -1.0;
  num endTime = -1.0;
  num timeScale = 1.0;

  num _mixTime = 0.0;
  num _mixDuration = 0.0;
  num _mix = 1.0;

  TrackEntryAction<TrackEntryStartArgs> onStart = null;
  TrackEntryAction<TrackEntryEndArgs> onEnd = null;
  TrackEntryAction<TrackEntryCompleteArgs> onComplete = null;
  TrackEntryAction<TrackEntryEventArgs> onEvent = null;

  String toString() => animation == null ? "<none>" : animation.name;
}
