import 'dart:html' as html;
import 'dart:typed_data';
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: false, width:480, height: 600, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  resourceManager.addTextFile("spineboy-old", "spine/spineboy-old.json");
  resourceManager.addTextureAtlas("spineboy-old", "atlas1/spineboy-old.atlas", TextureAtlasFormat.LIBGDX);
  //resourceManager.addTextureAtlas("spineboy-old", "atlas2/spineboy-old.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startSpineboyOld());
}

//-----------------------------------------------------------------------------

void startSpineboyOld() {

  var spineJson = resourceManager.getTextFile("spineboy-old");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy-old");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 480;
  skeletonAnimation.state.setAnimationByName(0, "jump", true);
  skeletonAnimation.timeScale = 0.10;

  var skeletonAnimationContainer = new Sprite();
  skeletonAnimationContainer.addChild(skeletonAnimation);
  skeletonAnimationContainer.useHandCursor = true;

  stage.addChild(skeletonAnimationContainer);
  stage.juggler.add(skeletonAnimation);

  //-----------------

  SkeletonBounds skeletonBounds = new SkeletonBounds();
  Shape shape = new Shape();
  shape.x = 240;
  shape.y = 480;
  shape.addTo(stage);

  stage.onEnterFrame.listen((e) {

    skeletonBounds.update(skeletonAnimation.skeleton, false);
    shape.graphics.clear();


    for(Float32List vertices in skeletonBounds.verticesList) {
      shape.graphics.beginPath();
      for(int i = 0; i < vertices.length - 1; i += 2) {
        num x = vertices[i + 0];
        num y = vertices[i + 1];
        shape.graphics.lineTo(x, y);
      }
      shape.graphics.lineTo(vertices[0], vertices[1]);
      shape.graphics.strokeColor(Color.White, 1.0);
    }

  });
}
