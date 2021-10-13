part of stagexl_spine;

class TextureAtlasAttachmentLoader implements AttachmentLoader {
  final TextureAtlas textureAtlas;
  final String namePrefix;

  TextureAtlasAttachmentLoader(this.textureAtlas, [this.namePrefix = ""]);

  @override
  RegionAttachment newRegionAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return RegionAttachment(name, path, bitmapData);
  }

  @override
  MeshAttachment newMeshAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return MeshAttachment(name, path, bitmapData);
  }

  @override
  BoundingBoxAttachment newBoundingBoxAttachment(Skin skin, String name) {
    return BoundingBoxAttachment(name);
  }

  @override
  PathAttachment newPathAttachment(Skin skin, String name) {
    return PathAttachment(name);
  }

  @override
  PointAttachment newPointAttachment(Skin skin, String name) {
    return PointAttachment(name);
  }

  @override
  ClippingAttachment newClippingAttachment(Skin skin, String name) {
    return ClippingAttachment(name);
  }
}
