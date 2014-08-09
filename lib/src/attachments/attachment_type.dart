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

class AttachmentType {

  static const AttachmentType region = const AttachmentType(0, "region");
  static const AttachmentType regionsequence = const AttachmentType(1, "regionsequence");
  static const AttachmentType boundingbox = const AttachmentType(2, "boundingbox");
  static const AttachmentType mesh = const AttachmentType(3, "mesh");
  static const AttachmentType skinnedmesh = const AttachmentType(4, "skinnedmesh");

  final int ordinal;
  final String name;

  const AttachmentType(this.ordinal, this.name);

  static AttachmentType get(String name) {
    switch (name.toLowerCase()) {
      case "region":
        return AttachmentType.region;
      case "regionsequence":
        return AttachmentType.regionsequence;
      case "boundingbox":
        return AttachmentType.boundingbox;
      case "mesh":
        return AttachmentType.mesh;
      case "skinnedmesh":
        return AttachmentType.skinnedmesh;
      default:
        throw new StateError("Unknwon AttachmentType: $name");
    }
  }

}
