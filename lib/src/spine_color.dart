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

class SpineColor {

  //static final Color WHITE = new Color(1.0, 1.0, 1.0, 1.0);
  //static final Color RED = new Color(1.0, 0.0, 0.0, 1.0);
  //static final Color GREEN = new Color(0.0, 1.0, 0.0, 1.0);
  //static final Color BLUE = new Color(0.0, 0.0, 1.0, 1.0);
  //static final Color MAGENTA = new Color(1.0, 0.0, 1.0, 1.0);

  double r = 0.0;
  double g = 0.0;
  double b = 0.0;
  double a = 0.0;

  SpineColor (this.r, this.g, this.b, [this.a = 0.0]);

  SpineColor setFrom(double r, double g , double b , double a ) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
    this.clamp();
    return this;
  }

  SpineColor setFromColor(SpineColor c) {
    this.r = c.r;
    this.g = c.g;
    this.b = c.b;
    this.a = c.a;
    return this;
  }

  SpineColor setFromString(String hex) {
    hex = hex.startsWith('#') ? hex.substring(1) : hex;
    this.r = int.parse(hex.substring(0, 2), radix: 16) / 255.0;
    this.g = int.parse(hex.substring(2, 4), radix: 16) / 255.0;
    this.b = int.parse(hex.substring(4, 6), radix: 16) / 255.0;
    this.a = (hex.length != 8 ? 255 : int.parse(hex.substring(6, 8), radix: 16)) / 255.0;
    return this;
  }

  SpineColor add(double r, double g, double b, double a) {
    this.r += r;
    this.g += g;
    this.b += b;
    this.a += a;
    this.clamp();
    return this;
  }

  SpineColor clamp() {
    if (this.r < 0.0) this.r = 0.0; else if (this.r > 1.0) this.r = 1.0;
    if (this.g < 0.0) this.g = 0.0; else if (this.g > 1.0) this.g = 1.0;
    if (this.b < 0.0) this.b = 0.0; else if (this.b > 1.0) this.b = 1.0;
    if (this.a < 0.0) this.a = 0.0; else if (this.a > 1.0) this.a = 1.0;
    return this;
  }
}
