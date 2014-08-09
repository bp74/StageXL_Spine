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

class TextureFormat {

  static const TextureFormat alpha = const TextureFormat(0, "alpha");
  static const TextureFormat intensity = const TextureFormat(1, "intensity");
  static const TextureFormat luminanceAlpha = const TextureFormat(2, "luminanceAlpha");
  static const TextureFormat rgb565 = const TextureFormat(3, "rgb565");
  static const TextureFormat rgba4444 = const TextureFormat(4, "rgba4444");
  static const TextureFormat rgb888 = const TextureFormat(5, "rgb888");
  static const TextureFormat rgba8888 = const TextureFormat(6, "rgba8888");

  final int ordinal;
  final String name;

  const TextureFormat(this.ordinal, this.name);

  static TextureFormat get(String name) {
    switch (name) {
      case "alpha":
        return TextureFormat.alpha;
      case "intensity":
        return TextureFormat.intensity;
      case "luminanceAlpha":
        return TextureFormat.luminanceAlpha;
      case "rgb565":
        return TextureFormat.rgb565;
      case "rgba4444":
        return TextureFormat.rgba4444;
      case "rgb888":
        return TextureFormat.rgb888;
      case "rgba8888":
        return TextureFormat.rgba8888;
      default:
        throw new StateError("Unknown TextureFormat: $name");
    }
  }

}
