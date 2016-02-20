import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;
  StageXL.bitmapDataLoadOptions.webp = true;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width: 480, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "spineboy-old" skeleton resources

  var resourceManager = new ResourceManager();
  resourceManager.addTextFile("spineboy-old", "spine/spineboy-old.json");
  //resourceManager.addTextureAtlas("spineboy-old", "atlas1/spineboy-old.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("spineboy-old", "atlas2/spineboy-old.json", TextureAtlasFormat.JSONARRAY);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("spineboy-old");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy-old");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = new AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 480;
  skeletonAnimation.state.setAnimationByName(0, "jump", true);
  skeletonAnimation.timeScale = 0.10;
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);

  // check and draw the SkeletonBounds at every frame

  var skeletonBounds = new SkeletonBounds();
  var shape = new Shape();
  shape.x = 240;
  shape.y = 480;
  shape.addTo(stage);

  stage.onEnterFrame.listen((e) {
    skeletonBounds.update(skeletonAnimation.skeleton, false);
    shape.graphics.clear();
    for (Float32List vertices in skeletonBounds.verticesList) {
      shape.graphics.beginPath();
      for (int i = 0; i < vertices.length - 1; i += 2) {
        num x = vertices[i + 0];
        num y = vertices[i + 1];
        shape.graphics.lineTo(x, y);
      }
      shape.graphics.lineTo(vertices[0], vertices[1]);
      shape.graphics.strokeColor(Color.White, 1.0);
    }
  });
}
