import 'dart:async';
import 'dart:html' as html;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_spine/stagexl_spine.dart';

Future main() async {
  // configure StageXL default options

  StageXL.stageOptions.renderEngine = RenderEngine.WebGL;
  StageXL.stageOptions.backgroundColor = Color.DarkSlateGray;

  // init Stage and RenderLoop

  var canvas = html.querySelector('#stage') as html.CanvasElement;
  var stage = Stage(canvas, width: 480, height: 600);
  var renderLoop = RenderLoop();
  renderLoop.addStage(stage);

  // load "goblins-ffd" skeleton resources

  var resourceManager = ResourceManager();
  var libgdx = TextureAtlasFormat.LIBGDX;
  resourceManager.addTextFile("goblins", "spine/goblins.json");
  resourceManager.addTextureAtlas("goblins", "spine/goblins.atlas", libgdx);
  await resourceManager.load();

  // load Spine skeleton

  var spineJson = resourceManager.getTextFile("goblins");
  var textureAtlas = resourceManager.getTextureAtlas("goblins");
  var attachmentLoader = TextureAtlasAttachmentLoader(textureAtlas);
  var skeletonLoader = SkeletonLoader(attachmentLoader);
  var skeletonData = skeletonLoader.readSkeletonData(spineJson);
  var animationStateData = AnimationStateData(skeletonData);

  // create the display object showing the skeleton animation

  var skeletonAnimation = SkeletonAnimation(skeletonData, animationStateData);
  skeletonAnimation.x = 240;
  skeletonAnimation.y = 560;
  skeletonAnimation.scaleX = skeletonAnimation.scaleY = 1.5;
  skeletonAnimation.state.setAnimationByName(0, "walk", true);
  skeletonAnimation.skeleton.skinName = "goblin";
  stage.addChild(skeletonAnimation);
  stage.juggler.add(skeletonAnimation);

  // feature: change the skin used for the skeleton

  //skeletonAnimation.skeleton.skinName = "goblin";
  //skeletonAnimation.skeleton.skinName = "goblingirl";

  // feature: change the attachments assigned to slots

  //skeletonAnimation.skeleton.setAttachment("left hand item", "dagger");
  //skeletonAnimation.skeleton.setAttachment("right hand item", null);
  //skeletonAnimation.skeleton.setAttachment("right hand item 2", null);
}
