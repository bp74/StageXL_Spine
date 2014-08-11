part of stagexl_spine;

class SkeletonAnimation extends SkeletonDisplayObject implements Animatable {

  final AnimationState state;

  SkeletonAnimation(SkeletonData skeletonData, [AnimationStateData stateData = null])
      : super(skeletonData),
        state = new AnimationState(stateData != null ? stateData : new AnimationStateData(skeletonData));

  advanceTime(num time) {
    time = time * timeScale;
    skeleton.update(time);
    state.update(time);
    state.apply(skeleton);
    skeleton.updateWorldTransform();
  }

}
