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

class Atlas {

  List<AtlasPage> _pages = new List<AtlasPage>();
	List<AtlasRegion> _regions = new List<AtlasRegion>();
	TextureLoader _textureLoader;

	Atlas (String atlasText, TextureLoader textureLoader) {
  	load(atlasText, textureLoader);
	}

	void load(String atlasText, TextureLoader textureLoader) {

	  if (atlasText == null) throw new ArgumentError("atlasText cannot be null.");
	  if (textureLoader == null) throw new ArgumentError("textureLoader cannot be null.");
	  _textureLoader = textureLoader;

		_Reader reader = new _Reader(atlasText);
		List<String> tuple = new List<String>(4);
		AtlasPage page = null;

		while (true) {

			String line = reader.readLine();
			if (line == null) break;

			line = reader.trim(line);
			if (line.length == 0) {
				page = null;
			} else if (page == null) {
				page = new AtlasPage();
				page.name = line;

				if (reader.readTuple(tuple) == 2) {
				  // size is only optional for an atlas packed with an old TexturePacker.
					page.width = int.parse(tuple[0]);
					page.height = int.parse(tuple[1]);
					reader.readTuple(tuple);
				}

				page.format = TextureFormat.get(tuple[0]);

				reader.readTuple(tuple);
				page.minFilter = TextureFilter.get(tuple[0]);
				page.magFilter = TextureFilter.get(tuple[1]);

				String direction = reader.readValue();
				page.uWrap = TextureWrap.clampToEdge;
				page.vWrap = TextureWrap.clampToEdge;

				if (direction == "x") {
					page.uWrap = TextureWrap.repeat;
				} else if (direction == "y") {
					page.vWrap = TextureWrap.repeat;
				} else if (direction == "xy") {
					page.uWrap = page.vWrap = TextureWrap.repeat;
				}

				textureLoader.loadPage(page, line);

				_pages.add(page);

			} else {

			  AtlasRegion region = new AtlasRegion();
				region.name = line;
				region.page = page;
				region.rotate = reader.readValue() == "true";

				reader.readTuple(tuple);
				int x = int.parse(tuple[0]);
				int y = int.parse(tuple[1]);

				reader.readTuple(tuple);
				int width = int.parse(tuple[0]);
				int height = int.parse(tuple[1]);

				region.u = x / page.width;
				region.v = y / page.height;

				if (region.rotate) {
					region.u2 = (x + height) / page.width;
					region.v2 = (y + width) / page.height;
				} else {
					region.u2 = (x + width) / page.width;
					region.v2 = (y + height) / page.height;
				}
				region.x = x;
				region.y = y;
				region.width = width.abs();
				region.height = height.abs();

				if (reader.readTuple(tuple) == 4) {
				  // split is optional
					region.splits = new List<int>.generate(4, (int i) => int.parse(tuple[i]));
					if (reader.readTuple(tuple) == 4) {
					  // pad is optional, but only present with splits
						region.pads = new List<int>.generate(4, (int i) => int.parse(tuple[i]));
						reader.readTuple(tuple);
					}
				}

				region.originalWidth = int.parse(tuple[0]);
				region.originalHeight = int.parse(tuple[1]);

				reader.readTuple(tuple);
				region.offsetX = int.parse(tuple[0]);
				region.offsetY = int.parse(tuple[1]);

				region.index = int.parse(reader.readValue());

				textureLoader.loadRegion(region);

				_regions.add(region);
			}
		}
	}

	/// Returns the first region found with the specified name.
	/// This method uses string comparison to find the region, so the result
	/// should be cached rather than calling this method multiple times.
	///
	AtlasRegion findRegion (String name ) {
	  return _regions.firstWhere((r) => r.name == name, orElse: () => null);
	}

	void dispose() {
    for (int i = 0; i < _pages.length; i++) {
			_textureLoader.unloadPage(_pages[i]);
    }
	}
}

class _Reader {

  static RegExp _splitRexExp = new RegExp(r"\r\n|\r|\n");
  static RegExp _trimRexExp = new RegExp(r"^\s+|\s+$");

  final List<String> lines;
	int index;

	_Reader(String text) : lines = text.split(_splitRexExp);

	String trim(String value) {
	  return value.replaceAll(_trimRexExp, "");
	}

	String readLine() {
		if (index >= lines.length) return null;
		return lines[index++];
	}

	String readValue() {
		String line = readLine();
		int colon = line.indexOf(":");
		if (colon == -1) throw new StateError("Invalid line: $line");
		return trim(line.substring(colon + 1));
	}

	/// Returns the number of tuple values read (1, 2 or 4).
	int readTuple(List tuple) {
		String line = readLine();

		int colon = line.indexOf(":");
		if (colon == -1) throw new StateError("Invalid line: " + line);

		int i = 0;
		int lastMatch= colon + 1;

		for (; i < 3; i++) {
			int comma = line.indexOf(",", lastMatch);
			if (comma == -1) break;
			tuple[i] = trim(line.substring(lastMatch, comma - lastMatch));
			lastMatch = comma + 1;
		}

		tuple[i] = trim(line.substring(lastMatch));
		return i + 1;
	}
}
