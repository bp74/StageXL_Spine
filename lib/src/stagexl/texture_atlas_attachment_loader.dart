part of stagexl_spine;

class TextureAtlasAttachmentLoader implements AttachmentLoader {

  final TextureAtlas textureAtlas;
  final String namePrefix;

  TextureAtlasAttachmentLoader(this.textureAtlas, [this.namePrefix = ""]) {
    if (textureAtlas == null) {
      throw new ArgumentError("textureAtlas cannot be null.");
    }
  }

  RegionAttachment newRegionAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return new RegionAttachment(name, path, bitmapData);
  }

  MeshAttachment newMeshAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return new MeshAttachment(name, path, bitmapData);
  }

  WeightedMeshAttachment newWeightedMeshAttachment(Skin skin, String name, String path) {
    var bitmapData = textureAtlas.getBitmapData(namePrefix + path);
    return new WeightedMeshAttachment(name, path, bitmapData);
  }

  BoundingBoxAttachment newBoundingBoxAttachment(Skin skin, String name) {
    return new BoundingBoxAttachment(name);
  }
}
