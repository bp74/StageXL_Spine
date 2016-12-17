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

  static final Animation _emptyAnimation = new Animation("<empty>", new List<Timeline>(), 0.0);

  final AnimationStateData data;
  final List<TrackEntry> _tracks = new List<TrackEntry>();
  final List<Event> _events = new List<Event>();
  final List<TrackEntryEvent> _trackEntryEvents = new List<TrackEntryEvent>();
  final Set<int> _propertyIDs = new Set<int>();

  bool _eventDispatchDisabled = false;
  bool animationsChanged = false;
  double timeScale = 1.0;

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

  void update(double delta) {

    delta *= timeScale;

    for (int i = 0; i < _tracks.length; i++) {

      TrackEntry current = _tracks[i];
      if (current == null) continue;

      current.animationLast = current.nextAnimationLast;
      current.trackLast = current.nextTrackLast;

      double currentDelta = delta * current.timeScale;

      if (current.delay > 0.0) {
        current.delay -= currentDelta;
        if (current.delay > 0.0) continue;
        currentDelta = -current.delay;
        current.delay = 0.0;
      }

      TrackEntry next = current.next;
      if (next != null) {
        // When the next entry's delay is passed, change to the next entry, preserving leftover time.
        double nextTime = current.trackLast - next.delay;
        if (nextTime >= 0.0) {
          next.delay = 0.0;
          next.trackTime = nextTime + delta * next.timeScale;
          current.trackTime += currentDelta;
          _setCurrent(i, next, true);
          while (next.mixingFrom != null) {
            next.mixTime += currentDelta;
            next = next.mixingFrom;
          }
          continue;
        }
      } else {
        // Clear the track when there is no next entry, the track end time is reached, and there is no mixingFrom.
        if (current.trackLast >= current.trackEnd && current.mixingFrom == null) {
          _tracks[i] = null;
          _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
          _disposeNext(current);
          continue;
        }
      }

      _updateMixingFrom(current, delta);
      current.trackTime += currentDelta;
    }

    _dispatchTrackEntryEvents();
  }

  void _updateMixingFrom(TrackEntry entry, double delta) {

    TrackEntry from = entry.mixingFrom;
    if (from == null) return;

    _updateMixingFrom(from, delta);

    if (entry.mixTime >= entry.mixDuration && from.mixingFrom == null && entry.mixTime > 0) {
      entry.mixingFrom = null;
      _enqueueTrackEntryEvent(new TrackEntryEndEvent(from));
      return;
    }

    from.animationLast = from.nextAnimationLast;
    from.trackLast = from.nextTrackLast;
    from.trackTime += delta * from.timeScale;
    entry.mixTime += delta * entry.timeScale;
  }

  void apply(Skeleton skeleton) {

    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
    if (animationsChanged) _animationsChanged();

    List<Event> events = _events;

    for (int i = 0; i < _tracks.length; i++) {

      TrackEntry current = _tracks[i];
      if (current == null || current.delay > 0.0) continue;

      // Apply mixing from entries first.
      double mix = current.alpha;
      if (current.mixingFrom != null) {
        mix *= _applyMixingFrom(current, skeleton);
      } else if (current.trackTime >= current.trackEnd) {
        mix = 0.0;
      }

      // Apply current entry.
      double animationLast = current.animationLast;
      double animationTime = current.getAnimationTime();
      List<Timeline> timelines = current.animation.timelines;
      List<num> timelinesRotation = current.timelinesRotation;
      List<bool> timelinesFirst = current.timelinesFirst;

      if (mix == 1.0) {

        for (int tl = 0; tl < timelines.length; tl++) {
          timelines[tl].apply(skeleton, animationLast, animationTime, events, 1.0, true, false);
        }

      } else {

        var firstFrame = timelinesRotation.length == 0;
        if (firstFrame) {
          timelinesRotation.length = timelines.length << 1;
          timelinesRotation.fillRange(0, timelinesRotation.length, 0.0);
        }

        for (int tl = 0; tl < timelines.length; tl++) {
          Timeline timeline = timelines[tl];
          if (timeline is RotateTimeline) {
            _applyRotateTimeline(
                timeline, skeleton, animationTime, mix,
                timelinesFirst[tl], timelinesRotation, tl << 1, firstFrame);
          } else {
            timeline.apply(
                skeleton, animationLast, animationTime, events,
                mix, timelinesFirst[tl], false);
          }
        }
      }

      _queueEvents(current, animationTime);
      _events.clear();

      current.nextAnimationLast = animationTime;
      current.nextTrackLast = current.trackTime;
    }

    _dispatchTrackEntryEvents();
  }

  double _applyMixingFrom(TrackEntry entry, Skeleton skeleton) {

    TrackEntry from = entry.mixingFrom;
    if (from.mixingFrom != null) _applyMixingFrom(from, skeleton);

    double mix = 0.0;
    if (entry.mixDuration == 0.0) {
      // Single frame mix to undo mixingFrom changes.
      mix = 1.0;
    } else {
      mix = entry.mixTime / entry.mixDuration;
      if (mix > 1.0) mix = 1.0;
    }

    List<Event> events = mix < from.eventThreshold ? _events : null;
    bool attachments = mix < from.attachmentThreshold;
    bool drawOrder = mix < from.drawOrderThreshold;

    double animationLast = from.animationLast;
    double animationTime = from.getAnimationTime();
    List<Timeline> timelines = from.animation.timelines;
    List<num> timelinesRotation = from.timelinesRotation;
    List<bool> timelinesFirst = from.timelinesFirst;
    double alpha = from.alpha * entry.mixAlpha * (1.0 - mix);

    var firstFrame = timelinesRotation.length == 0;
    if (firstFrame) {
      timelinesRotation.length = timelines.length << 1;
      timelinesRotation.fillRange(0, timelinesRotation.length, 0.0);
    }

    for (int i = 0; i < timelines.length; i++) {
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

    if (entry.mixDuration > 0)  {
      _queueEvents(from, animationTime);
    }
    _events.clear();

    from.nextAnimationLast = animationTime;
    from.nextTrackLast = from.trackTime;
    return mix;
  }

  void _applyRotateTimeline(
      Timeline timeline, Skeleton skeleton, double time, double alpha,
      bool setupPose, List<num> timelinesRotation, int i, bool firstFrame) {

    if (firstFrame) {
      timelinesRotation[i] = 0.0;
    }

    if (alpha == 1.0) {
      timeline.apply(skeleton, 0.0, time, null, 1.0, setupPose, false);
      return;
    }

    RotateTimeline rotateTimeline = timeline;
    Float32List frames = rotateTimeline.frames;
    Bone bone = skeleton.bones[rotateTimeline.boneIndex];
    double r2 = 0.0;

    if (time < frames[0]) {
      if (setupPose) bone.rotation = bone.data.rotation;
      return;
    }

    if (time >= frames[frames.length - RotateTimeline._ENTRIES]) {
      // Time is after last frame.
      r2 = bone.data.rotation + frames[frames.length + RotateTimeline._PREV_ROTATION];
    } else {
      // Interpolate between the previous frame and the current frame.
      int frame = Animation.binarySearch(frames, time, RotateTimeline._ENTRIES);
      double prevTime = frames[frame + RotateTimeline._PREV_TIME];
      double prevRotation = frames[frame + RotateTimeline._PREV_ROTATION];
      double frameTime = frames[frame + RotateTimeline._TIME];
      double frameRotation = frames[frame + RotateTimeline._ROTATION];
      double between = 1.0 - (time - frameTime) / (prevTime - frameTime);
      double percent = rotateTimeline.getCurvePercent((frame >> 1) - 1, between);
      r2 = _wrapRotation(frameRotation - prevRotation);
      r2 = _wrapRotation(prevRotation + r2 * percent + bone.data.rotation);
    }

    // Mix between rotations using the direction of the shortest route on the first frame while detecting crosses.
    double r1 = setupPose ? bone.data.rotation : bone.rotation;
    double total = 0.0;
    double diff = r2 - r1;

    if (diff == 0.0) {
      total = timelinesRotation[i];
    } else {
      diff = _wrapRotation(diff);
      double lastTotal = firstFrame ? 0.0 : timelinesRotation[i]; // Angle and direction of mix, including loops.
      double lastDiff = firstFrame ? diff : timelinesRotation[i + 1];  // Difference between bones.
      bool current = diff > 0.0;
      bool dir = lastTotal >= 0.0;
      // Detect cross at 0 (not 180).
      if ((lastDiff.sign != diff.sign) && (lastDiff.abs() <= 90.0)) {
        // A cross after a 360 rotation is a loop.
        if (lastTotal.abs() > 180.0) lastTotal += 360.0 * lastTotal.sign;
        dir = current;
      }
      // Store loops as part of lastTotal.
      total = diff + 360.0 * (lastTotal / 360.0).truncateToDouble();
      if (dir != current) total += 360.0 * lastTotal.sign;
      timelinesRotation[i] = total;
    }

    timelinesRotation[i + 1] = diff;
    bone.rotation = _wrapRotation(r1 + total * alpha);
  }

  void _queueEvents(TrackEntry entry, double animationTime) {

    double animationStart = entry.animationStart;
    double animationEnd = entry.animationEnd;
    double duration = animationEnd - animationStart;
    double trackLastWrapped = entry.trackLast.remainder(duration);
    int i = 0;

    // Queue events before complete.
    for (; i < _events.length; i++) {
      Event event = _events[i];
      if (event.time < trackLastWrapped) break;
      if (event.time > animationEnd) continue;
      _enqueueTrackEntryEvent(new TrackEntryEventEvent(entry, event));
    }

    // Queue complete if completed a loop iteration or the animation.
    if (entry.loop
        ? (trackLastWrapped > entry.trackTime.remainder(duration))
        : (animationTime >= animationEnd && entry.animationLast < animationEnd)) {
      _enqueueTrackEntryEvent(new TrackEntryCompleteEvent(entry));
    }

    // Queue events after complete.
    for (; i < _events.length; i++) {
      Event event = _events[i];
      if (event.time < animationStart) continue;
      _enqueueTrackEntryEvent(new TrackEntryEventEvent(entry, _events[i]));
    }
  }

  void clearTracks() {
    var oldEventDispatchDisabled = _eventDispatchDisabled;
    _eventDispatchDisabled = true;
    for (int i = 0; i < _tracks.length; i++) {
      clearTrack(i);
    }
    _tracks.clear();
    _eventDispatchDisabled = oldEventDispatchDisabled;
    _dispatchTrackEntryEvents();
  }

  void clearTrack(int trackIndex) {

    if (trackIndex >= _tracks.length) return;
    TrackEntry current = _tracks[trackIndex];
    if (current == null) return;
    _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
    _disposeNext(current);
    TrackEntry entry = current;

    for(;;) {
      TrackEntry from = entry.mixingFrom;
      if (from == null) break;
      _enqueueTrackEntryEvent(new TrackEntryEndEvent(from));
      entry.mixingFrom = null;
      entry = from;
    }

    _tracks[current.trackIndex] = null;
    _dispatchTrackEntryEvents();
  }


  void _setCurrent(int index, TrackEntry current, bool interrupt) {
    TrackEntry from = _expandToIndex(index);
    _tracks[index] = current;

    if (from != null) {
      if (interrupt) {
        _enqueueTrackEntryEvent(new TrackEntryInterruptEvent(from));
      }
      current.mixingFrom = from;
      current.mixTime = 0.0;
      from.timelinesRotation.clear();

      // If not completely mixed in, set mixAlpha so mixing out happens from current mix to zero.
      if (from.mixingFrom != null && from.mixDuration > 0.0) {
        current.mixAlpha *= math.min(from.mixTime / from.mixDuration, 1.0);
      }
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
    bool interrupt = true;
    TrackEntry current = _expandToIndex(trackIndex);
    if (current != null) {
      if (current.nextTrackLast == -1) {
        // Don't mix from an entry that was never applied.
        _tracks[trackIndex] = current.mixingFrom;
        _enqueueTrackEntryEvent(new TrackEntryInterruptEvent(current));
        _enqueueTrackEntryEvent(new TrackEntryEndEvent(current));
        _disposeNext(current);
        current = current.mixingFrom;
        interrupt = false;
      } else {
        _disposeNext(current);
      }
    }
    TrackEntry entry = _trackEntry(trackIndex, animation, loop, current);
    _setCurrent(trackIndex, entry, interrupt);
    _dispatchTrackEntryEvents();
    return entry;
  }

  TrackEntry addAnimationByName(int trackIndex, String animationName, bool loop, double delay) {
    Animation animation = data.skeletonData.findAnimation(animationName);
    if (animation == null) throw new ArgumentError("Animation not found: $animationName");
    return addAnimation(trackIndex, animation, loop, delay);
  }

  TrackEntry addAnimation(int trackIndex, Animation animation, bool loop, double delay) {
    if (animation == null) throw new ArgumentError("animation cannot be null.");
    TrackEntry last = _expandToIndex(trackIndex);
    if (last != null) {
      while (last.next != null) {
        last = last.next;
      }
    }

    TrackEntry entry = _trackEntry(trackIndex, animation, loop, last);

    if (last == null) {
      _setCurrent(trackIndex, entry, true);
      _dispatchTrackEntryEvents();
    } else {
      last.next = entry;
      if (delay <= 0.0) {
        double duration = last.animationEnd - last.animationStart;
        if (duration != 0.0) {
          delay += duration * (1.0 + last.trackTime ~/ duration) - data.getMix(last.animation, animation);
        } else {
          delay = 0.0;
        }
      }
    }

    entry.delay = delay;
    return entry;
  }

  TrackEntry setEmptyAnimation(int trackIndex, double mixDuration) {
    TrackEntry entry = setAnimation(trackIndex, _emptyAnimation, false);
    entry.mixDuration = mixDuration;
    entry.trackEnd = mixDuration;
    return entry;
  }

  TrackEntry addEmptyAnimation(int trackIndex, double mixDuration, double delay) {
    if (delay <= 0.0) delay -= mixDuration;
    TrackEntry entry = addAnimation(trackIndex, _emptyAnimation, false, delay);
    entry.mixDuration = mixDuration;
    entry.trackEnd = mixDuration;
    return entry;
  }

  void setEmptyAnimations(double mixDuration) {
    var oldEventDispatchDisabled = _eventDispatchDisabled;
    _eventDispatchDisabled = true;
    for (int i = 0; i < _tracks.length; i++) {
      TrackEntry current = _tracks[i];
      if (current != null) setEmptyAnimation(current.trackIndex, mixDuration);
    }
    _eventDispatchDisabled = oldEventDispatchDisabled;
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
    entry.mixDuration = last == null ? 0.0 : data.getMix(last.animation, animation);
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
    } else {
      List<Timeline> timelines = entry.animation.timelines;
      entry.timelinesFirst.length = timelines.length;
      for (int i = 0; i < timelines.length; i++) {
        _propertyIDs.add(timelines[i].getPropertyId());
        entry.timelinesFirst[i] = true;
      }
    }
  }

  void _checkTimelinesFirst(TrackEntry entry) {
    if (entry.mixingFrom != null) _checkTimelinesFirst(entry.mixingFrom);
    _checkTimelinesUsage(entry, entry.timelinesFirst);
  }

  void _checkTimelinesUsage(TrackEntry entry, List<bool> usageArray) {
    List<Timeline> timelines = entry.animation.timelines;
    usageArray.length = timelines.length;
    for (int i = 0; i < timelines.length; i++) {
      int id = timelines[i].getPropertyId();
      usageArray[i] = _propertyIDs.add(id);
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
      _trackEntryEvents.toList().forEach((trackEntryEvent) {
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
