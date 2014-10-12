import 'dart:math' as math;
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: true, width:1300, height: 1100, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  resourceManager.addTextFile("raptor", "spine/raptor.json");
  //resourceManager.addTextureAtlas("raptor", "atlas1/raptor.atlas", TextureAtlasFormat.LIBGDX);
  resourceManager.addTextureAtlas("raptor", "atlas2/raptor.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startDragon());
}

//-----------------------------------------------------------------------------

void startDragon() {

  var spineJson = resourceManager.getTextFile("raptor");
  var textureAtlas = resourceManager.getTextureAtlas("raptor");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 600;
  skeletonAnimation.y = 1000;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 0.8;
  skeletonAnimation.state.setAnimationByName(0, "walk", true);
  
  var skeletonAnimationContainer = new Sprite();
  skeletonAnimationContainer.addChild(skeletonAnimation);
  skeletonAnimationContainer.useHandCursor = true;

  stage.addChild(skeletonAnimationContainer);
  stage.juggler.add(skeletonAnimation);
  stage.juggler.transition(0, 1800, 3600, TransitionFunction.linear, 
      (v) => skeletonAnimation.timeScale = 0.7 + 0.5 * math.sin(v));
}
