part of stagexl_spine;

class TextureAtlasAttachmentLoader implements AttachmentLoader {

  final TextureAtlas textureAtlas;

  TextureAtlasAttachmentLoader(this.textureAtlas) {
    if (textureAtlas == null) throw new ArgumentError("textureAtlas cannot be null.");
  }

  RegionAttachment newRegionAttachment(Skin skin, String name, String path) {
    return new RegionAttachment(name, textureAtlas.getBitmapData(path));
  }

  MeshAttachment newMeshAttachment(Skin skin, String name, String path) {
    return new MeshAttachment(name, textureAtlas.getBitmapData(path));
  }

  SkinnedMeshAttachment newSkinnedMeshAttachment(Skin skin, String name, String path) {
    return new SkinnedMeshAttachment(name, textureAtlas.getBitmapData(path));
  }

  BoundingBoxAttachment newBoundingBoxAttachment(Skin skin, String name) {
    return new BoundingBoxAttachment(name);
  }

}
