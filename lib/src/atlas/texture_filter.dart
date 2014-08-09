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

class TextureFilter {

  static const TextureFilter nearest = const TextureFilter(0, "nearest");
  static const TextureFilter linear = const TextureFilter(1, "linear");
  static const TextureFilter mipMap = const TextureFilter(2, "mipMap");
  static const TextureFilter mipMapNearestNearest = const TextureFilter(3, "mipMapNearestNearest");
  static const TextureFilter mipMapLinearNearest = const TextureFilter(4, "mipMapLinearNearest");
  static const TextureFilter mipMapNearestLinear = const TextureFilter(5, "mipMapNearestLinear");
  static const TextureFilter mipMapLinearLinear = const TextureFilter(6, "mipMapLinearLinear");

  final int ordinal;
  final String name;

  const TextureFilter(this.ordinal, this.name);

  static TextureFilter get(String name) {
    switch (name.toLowerCase()) {
      case "nearest":
        return TextureFilter.nearest;
      case "linear":
        return TextureFilter.linear;
      case "mipMap":
        return TextureFilter.mipMap;
      case "mipMapNearestNearest":
        return TextureFilter.mipMapNearestNearest;
      case "mipMapLinearNearest":
        return TextureFilter.mipMapLinearNearest;
      case "mipMapNearestLinear":
        return TextureFilter.mipMapNearestLinear;
      case "mipMapLinearLinear":
        return TextureFilter.mipMapLinearLinear;
      default:
        throw new StateError("Unknown TextureFilter: $name");
    }
  }

}
