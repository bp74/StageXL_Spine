part of stagexl_spine;

class BitmapDataTextureLoader implements TextureLoader {

  Map<String, BitmapData> _bitmapDatas = new Map<String, BitmapData>();
  BitmapData _singleBitmapData = null;

  /// The [bitmapDatas] parameter may be a BitmapData for an atlas that has
  /// only one page, or for a multi page atlas an object where the key is
  /// the image path and the value is the BitmapData.

  BitmapDataTextureLoader(dynamic bitmapDatas) {
    if (bitmapDatas is BitmapData) {
      _singleBitmapData = bitmapDatas;
    } else if (bitmapDatas is Map) {
      _bitmapDatas = bitmapDatas;
    } else {
      throw new ArgumentError("Invalid bitmaps parameter.");
    }
  }

  //-----------------------------------------------------------------------------------------------
  //-----------------------------------------------------------------------------------------------

  void loadPage(AtlasPage page, String path) {

    BitmapData bitmapData;

    if (_singleBitmapData != null) {
      bitmapData = _singleBitmapData;
    } else if (_bitmapDatas.containsKey(path)) {
      bitmapData = _bitmapDatas[path];
    } else {
      throw new ArgumentError("BitmapData not found with name: $path");
    }

    page.renderTexture = bitmapData.renderTexture;
  }

  //-----------------------------------------------------------------------------------------------

  void unloadPage(AtlasPage page) {
    //RenderTexture renderTexture = page.rendererObject;
    //renderTexture.dispose();
  }

  //-----------------------------------------------------------------------------------------------

  void loadRegion(AtlasRegion region) {

    var renderTexture = region.page.renderTexture;

    if (region.rotate) {
      region.renderTextureQuad = new RenderTextureQuad(renderTexture, 3,
          region.offsetX, region.offsetY,
          region.x, region.y + region.width, region.width, region.height);
    } else {
      region.renderTextureQuad = new RenderTextureQuad(renderTexture, 0,
          region.offsetX, region.offsetY,
          region.x, region.y, region.width, region.height);
    }
  }

}
