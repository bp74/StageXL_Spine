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

class Animation {
  final String name;
  final List<Timeline> timelines;
  final double duration;

  Animation(this.name, this.timelines, this.duration);

  /// Poses the skeleton at the specified time for this animation.
  ///
  void apply(Skeleton skeleton, double lastTime, double time, bool loop, List<SpineEvent> events,
      double alpha, MixPose pose, MixDirection direction) {
    if (loop && duration != 0) {
      time = time.remainder(duration);
      if (lastTime > 0) lastTime %= duration;
    }

    for (int i = 0; i < timelines.length; i++) {
      timelines[i].apply(skeleton, lastTime, time, events, alpha, pose, direction);
    }
  }

  /// target: After the first and before the last entry.
  static int binarySearch(Float32List values, double target, int step) {
    int low = 0;
    int high = values.length ~/ step - 2;
    int current = high >> 1;
    if (high == 0) return step;

    for (;;) {
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
  }

  static int binarySearch1(Float32List values, double target) {
    int low = 0;
    int high = values.length - 2;
    if (high == 0) return 1;

    int current = high >> 1;
    for (;;) {
      if (values[current + 1] <= target) {
        low = current + 1;
      } else {
        high = current;
      }
      if (low == high) return low + 1;
      current = (low + high) >> 1;
    }
  }

  static int linearSearch(Float32List values, double target, int step) {
    for (int i = 0; i <= values.length - step; i += step) {
      if (values[i] > target) return i;
    }
    return -1;
  }

  @override
  String toString() => name;
}
