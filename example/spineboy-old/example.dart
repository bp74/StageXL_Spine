import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {

  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage');
  var stage = new Stage(canvas, width: 480, height: 600);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  // load "spineboy-old" skeleton resources

  var resourceManager = new ResourceManager();
  var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("spineboy", "spine/spineboy-old.json");
  resourceManager.addTextureAtlas("spineboy", "spine/spineboy-old.atlas", libgdx);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("spineboy");
  var textureAtlas = resourceManager.getTextureAtlas("spineboy");
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
  skeletonAnimation.boundsCalculation = SkeletonBoundsCalculation.BoundingBoxes;

  var mouseContainer = new Sprite();
  mouseContainer.addChild(skeletonAnimation);
  mouseContainer.mouseCursor = MouseCursor.CROSSHAIR;
  stage.juggler.add(skeletonAnimation);
  stage.addChild(mouseContainer);

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
        num x = 0.0 + vertices[i + 0];
        num y = 0.0 - vertices[i + 1];
        shape.graphics.lineTo(x, y);
      }
      shape.graphics.lineTo(vertices[0], 0.0 - vertices[1]);
      shape.graphics.strokeColor(Color.White, 1.0);
    }
  });
}
