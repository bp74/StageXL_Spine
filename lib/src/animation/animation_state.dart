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

class AnimationState extends EventDispatcher {

  static final Animation _emptyAnimation = new Animation("<empty>", new List<Timeline>(), 0);

  final AnimationStateData data;
  final List<TrackEntry> _tracks = new List<TrackEntry>();
  final List<Event> _events = new List<Event>();
  final List<TrackEntryEvent> _trackEntryEvents = new List<TrackEntryEvent>();
  final Map<int, int> _propertyIDs = new Map<int, int>();

  bool _eventDispatchDisabled = false;
  bool animationsChanged = false;
  num timeScale = 1.0;

  //----------------------------------------------------------------------------

  AnimationState(this.data) {
    if (data == null) throw new ArgumentError("data cannot be null.");
  }

  EventStream<TrackEntryStartEvent> get onTrackStart {
    return const EventStreamProvider<TrackEntryStartEvent>("start").forTarget(this);
  }

  EventStream<TrackEntryInterruptEvent> get onTrackInterrupt {
    return const EventStreamProvider<TrackEntryInterruptEvent>("interrupt").forTarget(this);
  }

  EventStream<TrackEntryEndEvent> get onTrackEnd {
    return const EventStreamProvider<TrackEntryEndEvent>("end").forTarget(this);
  }

  EventStream<TrackEntryDisposeEvent> get onTrackDispose {
    return const EventStreamProvider<TrackEntryDisposeEvent>("dispose").forTarget(this);
  }

  EventStream<TrackEntryCompleteEvent> get onTrackComplete {
    return const EventStreamProvider<TrackEntryCompleteEvent>("complete").forTarget(this);
  }

  EventStream<TrackEntryEventEvent> get onTrackEvent {
    return const EventStreamProvider<TrackEntryEventEvent>("event").forTarget(this);
  }

  //-----------------------------------------------------------------------------------------------

  void update(num delta) {

    delta *= timeScale;

    for (int i = 0; i < _tracks.length; i++) {

      TrackEntry current = _tracks[i];
      if (current == null) continue;

      current.animationLast = current.nextAnimationLast;
      current.trackLast = current.nextTrackLast;

      num currentDelta = delta * current.timeScale;

      if (current.delay > 0) {
        current.delay -= currentDelta;
        if (current.delay > 0) continue;
        currentDelta = -current.delay;
        current.delay = 0;
      }

      TrackEntry next = current.next;
      if (next != null) {
        // When the next entry's delay is passed, change to the next entry, preserving leftover time.
        num nextTime = current.trackLast - next.delay;
        if (nextTime >= 0) {
          next.delay = 0;
          next.trackTime = nextTime + delta * next.timeScale;
          current.trackTime += currentDelta;
          _setCurrent(i, next);
          while (next.mixingFrom != null) {
            next.mixTime += currentDelta;
            next = next.mixingFrom;
          }
          continue;
        }
        _updateMixingFrom(current, delta, true);
      } else {
        _updateMixingFrom(current, delta, true);
        // Clear the track when there is no next entry, the track end time is reached, and there is no mixingFrom.
        if (current.trackLast >= current.trackEnd &&
            current.mixingFrom == null) {
          _tracks[i] = null;
          _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
          _disposeNext(current);
          continue;
        }
      }

      current.trackTime += currentDelta;
    }

    _dispatchTrackEntryEvents();
  }

  void _updateMixingFrom(TrackEntry entry, num delta, bool canEnd) {

    TrackEntry from = entry.mixingFrom;
    if (from == null) return;

    if (canEnd && entry.mixTime >= entry.mixDuration && entry.mixTime > 0) {
      _enqueueTrackEntryEvent(new TrackEntryEndEvent(from));
      TrackEntry newFrom = from.mixingFrom;
      entry.mixingFrom = newFrom;
      if (newFrom == null) return;
      entry.mixTime = from.mixTime;
      entry.mixDuration = from.mixDuration;
      from = newFrom;
    }

    from.animationLast = from.nextAnimationLast;
    from.trackLast = from.nextTrackLast;
    num mixingFromDelta = delta * from.timeScale;
    from.trackTime += mixingFromDelta;
    entry.mixTime += mixingFromDelta;

    _updateMixingFrom(from, delta, canEnd && from.alpha == 1);
  }

  void apply(Skeleton skeleton) {

    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
    if (animationsChanged) _animationsChanged();

    List<Event> events = _events;

    for (int i = 0; i < _tracks.length; i++) {
      TrackEntry current = _tracks[i];
      if (current == null || current.delay > 0) continue;

      // Apply mixing from entries first.
      num mix = current.alpha;
      if (current.mixingFrom != null) {
        mix = _applyMixingFrom(current, skeleton, mix);
      }

      // Apply current entry.
      num animationLast = current.animationLast;
      num animationTime = current.getAnimationTime();
      int timelineCount = current.animation.timelines.length;
      List<Timeline> timelines = current.animation.timelines;

      if (mix == 1) {
        for (int ii = 0; ii < timelineCount; ii++) {
          timelines[ii].apply(skeleton, animationLast, animationTime, events, 1, true, false);
        }
      } else {
        bool firstFrame = current.timelinesRotation.length == 0;
        if (firstFrame) current.timelinesRotation.length = timelineCount << 1;
        List<num> timelinesRotation = current.timelinesRotation;

        List<bool> timelinesFirst = current.timelinesFirst;
        for (int ii = 0; ii < timelineCount; ii++) {
          Timeline timeline = timelines[ii];
          if (timeline is RotateTimeline) {
            _applyRotateTimeline(
                timeline, skeleton, animationTime, mix,
                timelinesFirst[ii], timelinesRotation, ii << 1, firstFrame);
          } else {
            timeline.apply(
                skeleton, animationLast, animationTime, events,
                mix, timelinesFirst[ii], false);
          }
        }
      }

      _queueEvents(current, animationTime);
      current.nextAnimationLast = animationTime;
      current.nextTrackLast = current.trackTime;
    }

    _dispatchTrackEntryEvents();
  }

  num _applyMixingFrom(TrackEntry entry, Skeleton skeleton, num alpha) {

    TrackEntry from = entry.mixingFrom;
    if (from.mixingFrom != null) _applyMixingFrom(from, skeleton, alpha);

    num mix = 0;
    if (entry.mixDuration == 0) {
      // Single frame mix to undo mixingFrom changes.
      mix = 1;
    } else {
      mix = entry.mixTime / entry.mixDuration;
      if (mix > 1) mix = 1;
      mix *= alpha;
    }

    List<Event> events = mix < from.eventThreshold ? _events : null;
    bool attachments = mix < from.attachmentThreshold;
    bool drawOrder = mix < from.drawOrderThreshold;
    num animationLast = from.animationLast;
    num animationTime = from.getAnimationTime();
    alpha = from.alpha * (1 - mix);
    int timelineCount = from.animation.timelines.length;
    List<Timeline> timelines = from.animation.timelines;
    List<bool> timelinesFirst = from.timelinesFirst;

    bool firstFrame = from.timelinesRotation.length == 0;
    if (firstFrame) from.timelinesRotation.length = timelineCount << 1;
    List<num> timelinesRotation = from.timelinesRotation;

    for (int i = 0; i < timelineCount; i++) {
      Timeline timeline = timelines[i];
      bool setupPose = timelinesFirst[i];
      if (timeline is RotateTimeline) {
        _applyRotateTimeline(
            timeline, skeleton, animationTime, alpha,
            setupPose, timelinesRotation, i << 1, firstFrame);
      } else {
        if (!setupPose) {
          if (!attachments && timeline is AttachmentTimeline) continue;
          if (!drawOrder && timeline is DrawOrderTimeline) continue;
        }
        timeline.apply(
            skeleton, animationLast, animationTime, events,
            alpha, setupPose, true);
      }
    }

    _queueEvents(from, animationTime);
    from.nextAnimationLast = animationTime;
    from.nextTrackLast = from.trackTime;
    return mix;
  }

  void _applyRotateTimeline(
      Timeline timeline, Skeleton skeleton, num time, num alpha,
      bool setupPose, List<num> timelinesRotation, int i, bool firstFrame) {

    if (alpha == 1) {
      timeline.apply(skeleton, 0, time, null, 1, setupPose, false);
      return;
    }

    RotateTimeline rotateTimeline = timeline;
    List<num> frames = rotateTimeline.frames;
    if (time < frames[0]) return; // Time is before first frame.

    Bone bone = skeleton.bones[rotateTimeline.boneIndex];

    num r2 = 0;
    if (time >= frames[frames.length - RotateTimeline._ENTRIES]) {
      // Time is after last frame.
      r2 = bone.data.rotation + frames[frames.length + RotateTimeline._PREV_ROTATION];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, RotateTimeline._ENTRIES);
      num prevRotation = frames[frame + RotateTimeline._PREV_ROTATION];
      num frameTime = frames[frame];
      num percent = rotateTimeline.getCurvePercent((frame >> 1) - 1,
          1 - (time - frameTime) / (frames[frame + RotateTimeline._PREV_TIME] - frameTime));

      r2 = frames[frame + RotateTimeline._ROTATION] - prevRotation;
      r2 -= (16384 - (16384.499999999996 - r2 / 360).toInt()) * 360;
      r2 = prevRotation + r2 * percent + bone.data.rotation;
      r2 -= (16384 - (16384.499999999996 - r2 / 360).toInt()) * 360;
    }

    // Mix between rotations using the direction of the shortest route on the first frame while detecting crosses.
    num r1 = setupPose ? bone.data.rotation : bone.rotation;
    num total = 0;
    num diff = r2 - r1;
    if (diff == 0) {
      if (firstFrame) {
        timelinesRotation[i] = 0;
        total = 0;
      } else {
        total = timelinesRotation[i];
      }
    } else {
      diff -= (16384 - (16384.499999999996 - diff / 360).toInt()) * 360;
      num lastTotal = 0;
      num lastDiff = 0;
      if (firstFrame) {
        lastTotal = 0;
        lastDiff = diff;
      } else {
        lastTotal = timelinesRotation[i]; // Angle and direction of mix, including loops.
        lastDiff = timelinesRotation[i + 1]; // Difference between bones.
      }
      bool current = diff > 0;
      bool dir = lastTotal >= 0;

      // Detect cross at 0 (not 180).      
      if (lastDiff.sign != diff.sign && lastDiff.abs() <= 90) {
        // A cross after a 360 rotation is a loop.
        if (lastTotal.abs() > 180) lastTotal += 360 * lastTotal.sign;
        dir = current;
      }
      total = diff + lastTotal - lastTotal % 360; // Store loops as part of lastTotal.
      if (dir != current) total += 360 * lastTotal.sign;
      timelinesRotation[i] = total;
    }
    timelinesRotation[i + 1] = diff;
    r1 += total * alpha;
    bone.rotation = r1 - (16384 - (16384.499999999996 - r1 / 360).toInt()) * 360;
  }

  void _queueEvents(TrackEntry entry, num animationTime) {

    num animationStart = entry.animationStart;
    num animationEnd = entry.animationEnd;
    num duration = animationEnd - animationStart;
    num trackLastWrapped = entry.trackLast % duration;
    int i = 0;

    // Queue events before complete.
    for (; i < _events.length; i++) {
      Event event = _events[i];
      if (event.time < trackLastWrapped) break;
      if (event.time > animationEnd) continue;
      _enqueueTrackEntryEvent(new TrackEntryEventEvent(entry, event));
    }

    // Queue complete if completed a loop iteration or the animation.
    if (entry.loop ? (trackLastWrapped > entry.trackTime % duration) : (animationTime >= animationEnd && entry.animationLast < animationEnd)) {
      _enqueueTrackEntryEvent(new TrackEntryCompleteEvent(entry));
    }

    // Queue events after complete.
    for (; i < _events.length; i++) {
      Event  event = _events[i];
      if (event.time < animationStart) continue;
      _enqueueTrackEntryEvent(new TrackEntryEventEvent(entry, _events[i]));
    }

    _events.length = 0;
  }

  void clearTracks() {
    _eventDispatchDisabled = true;
    for (int i = 0; i < _tracks.length; i++) {
      clearTrack(i);
    }
    _tracks.clear();
    _eventDispatchDisabled = false;
    _dispatchTrackEntryEvents();
  }

  void clearTrack(int trackIndex) {
    if (trackIndex >= _tracks.length) return;
    TrackEntry current = _tracks[trackIndex];
    if (current == null) return;
    _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
    _disposeNext(current);
    TrackEntry entry = current;
    while (true) {
      TrackEntry from = entry.mixingFrom;
      if (from == null) break;
      _enqueueTrackEntryEvent(new TrackEntryEndEvent(from));
      entry.mixingFrom = null;
      entry = from;
    }

    _tracks[current.trackIndex] = null;
    _dispatchTrackEntryEvents();
  }


  void _setCurrent(int index, TrackEntry current) {
    TrackEntry from = _expandToIndex(index);
    _tracks[index] = current;

    if (from != null) {
      _enqueueTrackEntryEvent(new TrackEntryInterruptEvent(from));
      current.mixingFrom = from;
      current.mixTime = 0;
      from.timelinesRotation.clear();
      // If not completely mixed in, set alpha so mixing out happens from current mix to zero.
      if (from.mixingFrom != null)
        from.alpha *= math.min(from.mixTime / from.mixDuration, 1);
    }

    _enqueueTrackEntryEvent(new TrackEntryStartEvent(current));
  }

  TrackEntry setAnimationByName(int trackIndex, String animationName, bool loop) {
    Animation animation = data.skeletonData.findAnimation(animationName);
    if (animation == null) throw new ArgumentError("Animation not found: $animationName");
    return setAnimation(trackIndex, animation, loop);
  }

  TrackEntry setAnimation(int trackIndex, Animation animation, bool loop) {
    if (animation == null) throw new ArgumentError("animation cannot be null.");
    TrackEntry current = _expandToIndex(trackIndex);
    if (current != null) {
      if (current.nextTrackLast == -1) {
        // Don't mix from an entry that was never applied.
        _tracks[trackIndex] = null;
        _enqueueTrackEntryEvent(new TrackEntryInterruptEvent(current));
        _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
        _disposeNext(current);
        current = null;
      } else {
        _disposeNext(current);
      }
    }
    TrackEntry entry = _trackEntry(trackIndex, animation, loop, current);
    _setCurrent(trackIndex, entry);
    _dispatchTrackEntryEvents();
    return entry;
  }

  TrackEntry addAnimationByName(int trackIndex, String animationName, bool loop, num delay) {
    Animation animation = data.skeletonData.findAnimation(animationName);
    if (animation == null) throw new ArgumentError("Animation not found: $animationName");
    return addAnimation(trackIndex, animation, loop, delay);
  }

  TrackEntry addAnimation(int trackIndex, Animation animation, bool loop, num delay) {
    if (animation == null) throw new ArgumentError("animation cannot be null.");
    TrackEntry last = _expandToIndex(trackIndex);
    if (last != null) {
      while (last.next != null) {
        last = last.next;
      }
    }

    TrackEntry entry = _trackEntry(trackIndex, animation, loop, last);

    if (last == null) {
      _setCurrent(trackIndex, entry);
      _dispatchTrackEntryEvents();
    } else {
      last.next = entry;
      if (delay <= 0) {
        num duration = last.animationEnd - last.animationStart;
        if (duration != 0) {
          delay += duration * (1 + last.trackTime ~/ duration) - data.getMix(last.animation, animation);
        } else {
          delay = 0;
        }
      }
    }

    entry.delay = delay;
    return entry;
  }

  TrackEntry setEmptyAnimation(int trackIndex, num mixDuration) {
    TrackEntry entry = setAnimation(trackIndex, _emptyAnimation, false);
    entry.mixDuration = mixDuration;
    entry.trackEnd = mixDuration;
    return entry;
  }

  TrackEntry addEmptyAnimation(int trackIndex, num mixDuration, num delay) {
    if (delay <= 0) delay -= mixDuration;
    TrackEntry entry = addAnimation(trackIndex, _emptyAnimation, false, delay);
    entry.mixDuration = mixDuration;
    entry.trackEnd = mixDuration;
    return entry;
  }

  void setEmptyAnimations(num mixDuration) {
    _eventDispatchDisabled = true;
    for (int i = 0; i < _tracks.length; i++) {
      TrackEntry current = _tracks[i];
      if (current != null) setEmptyAnimation(current.trackIndex, mixDuration);
    }
    _eventDispatchDisabled = false;
    _dispatchTrackEntryEvents();
  }

  TrackEntry _expandToIndex(int index) {
    if (index < _tracks.length) return _tracks[index];
    _tracks.length = index + 1;
    return null;
  }

  TrackEntry _trackEntry(int trackIndex, Animation animation, bool loop, TrackEntry last) {
    TrackEntry entry = new TrackEntry(trackIndex, animation);
    entry.loop = loop;
    entry.trackEnd = loop ? double.MAX_FINITE : entry.animationEnd;
    entry.mixDuration = last == null ? 0 : data.getMix(last.animation, animation);
    return entry;
  }

  void _disposeNext(TrackEntry entry) {
    for (var next = entry.next; next != null; next = next.next) {
      _enqueueTrackEntryEvent(new TrackEntryDisposeEvent(next));
    }
    entry.next = null;
  }

  void _animationsChanged() {
    this.animationsChanged = false;
    _propertyIDs.clear();
    // Compute timelinesFirst from lowest to highest track entries.
    int i = 0;
    for (; i < _tracks.length; i++) { // Find first non-null entry.
      TrackEntry entry = _tracks[i];
      if (entry == null) continue;
      _setTimelinesFirst(entry);
      i++;
      break;
    }
    for (; i < _tracks.length; i++) { // Rest of entries.
      TrackEntry entry = _tracks[i];
      if (entry != null) _checkTimelinesFirst(entry);
    }
  }

  void _setTimelinesFirst(TrackEntry entry) {
    if (entry.mixingFrom != null) {
      _setTimelinesFirst(entry.mixingFrom);
      _checkTimelinesUsage(entry, entry.timelinesFirst);
      return;
    }
    entry.timelinesFirst.length = entry.animation.timelines.length;
    for (int i = 0; i < entry.animation.timelines.length; i++) {
      int id = entry.animation.timelines[i].getPropertyId();
      _propertyIDs[id] = id;
      entry.timelinesFirst[i] = true;
    }
  }

  void _checkTimelinesFirst(TrackEntry entry) {
    if (entry.mixingFrom != null) _checkTimelinesFirst(entry.mixingFrom);
    _checkTimelinesUsage(entry, entry.timelinesFirst);
  }

  void _checkTimelinesUsage(TrackEntry entry, List<bool> usageArray) {
    usageArray.length = entry.animation.timelines.length;
    for (int i = 0; i < entry.animation.timelines.length; i++) {
      int id = entry.animation.timelines[i].getPropertyId();
      usageArray[i] = !_propertyIDs.containsKey(id);
      _propertyIDs[id] = id;
    }
  }

  void _enqueueTrackEntryEvent(TrackEntryEvent trackEntryEvent) {
    _trackEntryEvents.add(trackEntryEvent);
    if (trackEntryEvent is TrackEntryStartEvent ||
        trackEntryEvent is TrackEntryEndEvent) {
      this.animationsChanged = true;
    }
  }

  void _dispatchTrackEntryEvents() {
    if (_eventDispatchDisabled == false) {
      _eventDispatchDisabled = true;
      _trackEntryEvents.forEach((trackEntryEvent) {
        trackEntryEvent.trackEntry.dispatchEvent(trackEntryEvent);
        this.dispatchEvent(trackEntryEvent);
      });
      _trackEntryEvents.clear();
      _eventDispatchDisabled = false;
    }
  }

  TrackEntry getCurrent(int trackIndex) {
    if (trackIndex >= _tracks.length) return null;
    return _tracks[trackIndex];
  }

  void clearListeners() {
    this.removeEventListeners("start");
    this.removeEventListeners("interrupt");
    this.removeEventListeners("end");
    this.removeEventListeners("dispose");
    this.removeEventListeners("complete");
    this.removeEventListeners("event");
  }

  void clearListenerNotifications() {
    _trackEntryEvents.clear();
  }
}
