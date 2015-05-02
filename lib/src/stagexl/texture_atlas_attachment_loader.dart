part of stagexl_spine;

class TextureAtlasAttachmentLoader implements AttachmentLoader {

  final TextureAtlas textureAtlas;
  final String namePrefix;

  TextureAtlasAttachmentLoader(this.textureAtlas, [this.namePrefix = ""]) {
    if (textureAtlas == null) throw new ArgumentError("textureAtlas cannot be null.");
  }

  RegionAttachment newRegionAttachment(Skin skin, String name, String path) {
    return new RegionAttachment(name, textureAtlas.getBitmapData(namePrefix + path));
  }

  MeshAttachment newMeshAttachment(Skin skin, String name, String path) {
    return new MeshAttachment(name, textureAtlas.getBitmapData(namePrefix + path));
  }

  SkinnedMeshAttachment newSkinnedMeshAttachment(Skin skin, String name, String path) {
    return new SkinnedMeshAttachment(name, textureAtlas.getBitmapData(namePrefix + path));
  }

  BoundingBoxAttachment newBoundingBoxAttachment(Skin skin, String name) {
    return new BoundingBoxAttachment(name);
  }

}
