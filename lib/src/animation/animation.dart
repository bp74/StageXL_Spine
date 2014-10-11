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

class Animation {

  final String name;
  final List<Timeline> timelines;
  final num duration;

  Animation(this.name, this.timelines, this.duration) {
    if (name == null) throw new ArgumentError("name cannot be null.");
    if (timelines == null) throw new ArgumentError("timelines cannot be null.");
  }

  /// Poses the skeleton at the specified time for this animation.
  ///
  void apply(Skeleton skeleton, num lastTime, num time, bool loop, List<Event> events) {

    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");

    if (loop && duration != 0) {
      time %= duration;
      lastTime %= duration;
    }

    for (int i = 0; i < timelines.length; i++) {
      timelines[i].apply(skeleton, lastTime, time, events, 1);
    }
  }

  /// Poses the skeleton at the specified time for this animation mixed
  /// with the current pose.
  ///
  /// alpha: The amount of this animation that affects the current pose.
  ///
  void mix(Skeleton skeleton, num lastTime, num time, bool loop, List<Event> events, num alpha) {

    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");

    if (loop && duration != 0) {
      time %= duration;
      lastTime %= duration;
    }

    for (int i = 0; i < timelines.length; i++) {
      timelines[i].apply(skeleton, lastTime, time, events, alpha);
    }
  }

  /// target: After the first and before the last entry.
  static int binarySearch(Float32List values, num target, int step) {

    int low = 0;
    int high = values.length ~/ step - 2;
    int current = high >> 1;
    if (high == 0) return step;

    while (true) {
      if (values[(current + 1) * step] <= target) {
        low = current + 1;
      } else {
        high = current;
      }

      if (low == high) {
        return (low + 1) * step;
      } else {
        current = (low + high) >> 1;
      }
    }

    return 0; // Can't happen.
  }

  static int binarySearch1(Float32List values, num target) {
    int low = 0;
    int high = values.length - 2;
    if (high == 0) return 1;
    
    int current = high >> 1;
    while (true) {
      if (values[current + 1] <= target) {
        low = current + 1;
      } else {
        high = current;
      }
      if (low == high) return low + 1;
      current = (low + high) >> 1;
    }

    return 0; // Can't happen.
  }
  
  static int linearSearch(Float32List values, num target, int step) {
    for (int i = 0; i <= values.length - step; i += step) {
      if (values[i] > target) return i;
    }
    return -1;
  }

  String toString() => name;

}
