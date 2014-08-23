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

class AnimationState {

  final AnimationStateData data;
  final List<TrackEntry> _tracks = new List<TrackEntry>();
  final List<Event> _events = new List<Event>();

  num timeScale = 1.0;

  static StreamController<TrackEntryStartArgs> _onTrackStart = new StreamController<TrackEntryStartArgs>();
  static StreamController<TrackEntryEndArgs> _onTrackEnd = new StreamController<TrackEntryEndArgs>();
  static StreamController<TrackEntryCompleteArgs> _onTrackComplete = new StreamController<TrackEntryCompleteArgs>();
  static StreamController<TrackEntryEventArgs> _onTrackEvent = new StreamController<TrackEntryEventArgs>();

  final Stream<TrackEntryStartArgs> onTrackStart = _onTrackStart.stream.asBroadcastStream();
  final Stream<TrackEntryEndArgs> onTrackEnd = _onTrackEnd.stream.asBroadcastStream();
  final Stream<TrackEntryCompleteArgs> onTrackComplete = _onTrackComplete.stream.asBroadcastStream();
  final Stream<TrackEntryEventArgs> onTrackEvent = _onTrackEvent.stream.asBroadcastStream();

  //-----------------------------------------------------------------------------------------------

  AnimationState(this.data) {
    if (data == null) throw new ArgumentError("data cannot be null.");
  }

  void update(num delta) {

    delta *= timeScale;

    for (int i = 0; i < _tracks.length; i++) {

      TrackEntry current = _tracks[i];
      if (current == null) continue;

      current.time += delta * current.timeScale;
      if (current._previous != null) {
        num previousDelta = delta * current._previous.timeScale;
        current._previous.time += previousDelta;
        current._mixTime += previousDelta;
      }

      TrackEntry next = current.next;
      if (next != null) {
        next.time = current.lastTime - next.delay;
        if (next.time >= 0) _setCurrent(i, next);
      } else {
        // End non-looping animation when it reaches its end time and there is no next entry.
        if (!current.loop && current.lastTime >= current.endTime) clearTrack(i);
      }
    }
  }

  void apply(Skeleton skeleton) {

    for (int i = 0; i < _tracks.length; i++) {

      TrackEntry current = _tracks[i];
      if (current == null) continue;

      _events.length = 0;

      num time = current.time;
      num lastTime = current.lastTime;
      num endTime = current.endTime;
      bool loop = current.loop;

      if (!loop && time > endTime) time = endTime;

      TrackEntry previous = current._previous;
      if (previous == null) {

        if (current._mix == 1) {
          current.animation.apply(skeleton, current.lastTime, time, loop, _events);
        } else {
          current.animation.mix(skeleton, current.lastTime, time, loop, _events, current._mix);
        }

      } else {

        num previousTime = previous.time;

        if (!previous.loop && previousTime > previous.endTime) {
          previousTime = previous.endTime;
        }

        previous.animation.apply(skeleton, previousTime, previousTime, previous.loop, null);

        num alpha = current._mixTime / current._mixDuration * current._mix;
        if (alpha >= 1) {
          alpha = 1;
          current._previous = null;
        }

        current.animation.mix(skeleton, current.lastTime, time, loop, _events, alpha);
      }

      for (Event event in _events) {
        TrackEntryEventArgs args = new TrackEntryEventArgs(i, event);
        if (current.onEvent != null) current.onEvent(args);
        _onTrackEvent.add(args);
      }

      // Check if completed the animation or a loop iteration.

      if (loop ? (lastTime % endTime > time % endTime) : (lastTime < endTime && time >= endTime)) {
        TrackEntryCompleteArgs args = new TrackEntryCompleteArgs(i, time ~/ endTime);
        if (current.onComplete != null) current.onComplete(args);
        _onTrackComplete.add(args);
      }

      current.lastTime = current.time;
    }
  }

  void clearTracks() {
    for (int i = 0; i < _tracks.length; i++) {
      clearTrack(i);
    }
    _tracks.clear();
  }

  void clearTrack(int trackIndex) {

    if (trackIndex >= _tracks.length) return;

    TrackEntry current = _tracks[trackIndex];
    if (current == null) return;

    TrackEntryEndArgs args = new TrackEntryEndArgs(trackIndex);
    if (current.onEnd != null) current.onEnd(args);
    _onTrackEnd.add(args);

    _tracks[trackIndex] = null;
  }

  TrackEntry setAnimationByName(int trackIndex, String animationName, bool loop) {
    Animation animation = this.data.skeletonData.findAnimation(animationName);
    if (animation == null) throw new ArgumentError("Animation not found: $animationName");
    return setAnimation(trackIndex, animation, loop);
  }

  /// Set the current animation. Any queued animations are cleared.
  TrackEntry setAnimation(int trackIndex, Animation animation, bool loop) {
    TrackEntry entry = new TrackEntry();
    entry.animation = animation;
    entry.loop = loop;
    entry.endTime = animation.duration;
    _setCurrent(trackIndex, entry);
    return entry;
  }

  TrackEntry addAnimationByName(int trackIndex, String animationName, bool loop, num delay) {
    Animation animation = this.data.skeletonData.findAnimation(animationName);
    if (animation == null) throw new ArgumentError("Animation not found: $animationName");
    return addAnimation(trackIndex, animation, loop, delay);
  }

  /// Adds an animation to be played delay seconds after the current or
  /// last queued animation.
  ///
  /// delay: May be <= 0 to use duration of previous animation minus any
  /// mix duration plus the negative delay.
  ///
  TrackEntry addAnimation(int trackIndex, Animation animation, bool loop, num delay) {

    TrackEntry entry = new TrackEntry();
    entry.animation = animation;
    entry.loop = loop;
    entry.endTime = animation.duration;

    TrackEntry last = _expandToIndex(trackIndex);

    if (last != null) {
      while (last.next != null) last = last.next;
      last.next = entry;
    } else {
      _tracks[trackIndex] = entry;
    }

    if (delay <= 0) {
      if (last != null) {
        delay += last.endTime - this.data.getMix(last.animation, animation);
      } else {
        delay = 0;
      }
    }

    entry.delay = delay;
    return entry;
  }


  TrackEntry getCurrent(int trackIndex) {
    if (trackIndex >= _tracks.length) return null;
    return _tracks[trackIndex];
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    for (TrackEntry entry in _tracks) {
      if (entry == null) continue;
      if (buffer.length > 0) buffer.write(", ");
      buffer.write(entry.toString());
    }
    if (buffer.length == 0) return "<none>";
    return buffer.toString();
  }

  //-----------------------------------------------------------------------------------------------
  //-----------------------------------------------------------------------------------------------

  TrackEntry _expandToIndex(int index) {
    if (index < _tracks.length) return _tracks[index];
    if (index >= _tracks.length) _tracks.length = index + 1;
    return null;
  }

  void _setCurrent(int trackIndex, TrackEntry trackEntry) {

    TrackEntry current = _expandToIndex(trackIndex);
    if (current != null) {

      TrackEntry previous = current._previous;
      current._previous = null;

      TrackEntryEndArgs args = new TrackEntryEndArgs(trackIndex);
      if (current.onEnd != null) current.onEnd(args);
      _onTrackEnd.add(args);

      trackEntry._mixDuration = this.data.getMix(current.animation, trackEntry.animation);
      if (trackEntry._mixDuration > 0) {
        trackEntry._mixTime = 0;
        // If a mix is in progress, mix from the closest animation.
        if (previous != null && current._mixTime / current._mixDuration < 0.5) {
          trackEntry._previous = previous;
          previous = current;
        } else trackEntry._previous = current;
      }
    }

    _tracks[trackIndex] = trackEntry;

    TrackEntryStartArgs args = new TrackEntryStartArgs(trackIndex);
    if (trackEntry.onStart != null) trackEntry.onStart(args);
    _onTrackStart.add(args);
  }
}
