part of stagexl_spine;

class SkeletonClipping implements RenderMask {

  final Graphics _graphics = new Graphics();
  final _SkeletonClippingCommand _command = new _SkeletonClippingCommand();

  @override bool relativeToParent = false;
  @override bool border = false;
  @override int borderWidth = 1;
  @override int borderColor = 0xFFFF00FF;

  SkeletonClipping() {
    _graphics.addCommand(_command);
    _graphics.fillColor(Color.Magenta);
  }

  set vertices(Float32List vertices) {
    _command.vertices = vertices;
    _command.invalidate();
  }

  @override
  void renderMask(RenderState renderState) {
    _graphics.renderMask(renderState);
  }
}

//-----------------------------------------------------------------------------

class _SkeletonClippingCommand extends GraphicsCommand {

  Float32List vertices = new Float32List(0);

  @override
  void updateContext(GraphicsContext context) {
    for(int i = 0; i < vertices.length - 1; i += 2) {
      context.lineTo(vertices[i], vertices[i + 1]);
    }
  }
}
