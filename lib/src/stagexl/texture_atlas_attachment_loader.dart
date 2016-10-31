part of stagexl_spine;

class TextureAtlasAttachmentLoader implements AttachmentLoader {

  final TextureAtlas textureAtlas;
  final String namePrefix;

  TextureAtlasAttachmentLoader(this.textureAtlas, [this.namePrefix = ""]) {
    if (textureAtlas == null) {
      throw new ArgumentError("textureAtlas cannot be null.");
    }
  }

  @override
  RegionAttachment newRegionAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return new RegionAttachment(name, path, bitmapData);
  }

  @override
  MeshAttachment newMeshAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return new MeshAttachment(name, path, bitmapData);
  }

  @override
  BoundingBoxAttachment newBoundingBoxAttachment(Skin skin, String name) {
    return new BoundingBoxAttachment(name);
  }

  @override
  PathAttachment newPathAttachment(Skin skin, String name) {
    return new PathAttachment(name);
  }
}
