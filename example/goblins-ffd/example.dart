import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Stage stage;
RenderLoop renderLoop;
ResourceManager resourceManager = new ResourceManager();

void main() {

  var canvas = html.querySelector('#stage');

  stage = new Stage(canvas, webGL: true, width:480, height: 600, color: Color.DarkSlateGray);
  stage.scaleMode = StageScaleMode.SHOW_ALL;
  stage.align = StageAlign.NONE;

  renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  BitmapData.defaultLoadOptions.webp = true;

  resourceManager.addTextFile("goblins-ffd", "spine/goblins-ffd.json");
  resourceManager.addTextureAtlas("goblins-ffd", "atlas1/goblins-ffd.atlas", TextureAtlasFormat.LIBGDX);
  //resourceManager.addTextureAtlas("goblins-ffd", "atlas2/goblins-ffd.json", TextureAtlasFormat.JSONARRAY);
  resourceManager.load().then((rm) => startGoblins());
}

//-----------------------------------------------------------------------------

void startGoblins() {

  var spineJson = resourceManager.getTextFile("goblins-ffd");
  var textureAtlas = resourceManager.getTextureAtlas("goblins-ffd");
  var attachmentLoader = new TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = new SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);

  var animationStateData = new AnimationStateData(skeletonData);

  var skeletonAnimation = new SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 560;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 1.5;

  skeletonAnimation.skeleton.skinName = "goblin";
  //skeletonAnimation.skeleton.skinName = "goblingirl";

  skeletonAnimation.state.setAnimationByName(0, "walk", true);

  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);
}



