part of stagexl_spine;

class _SpineRenderProgram extends RenderProgram {

  var _vertexShaderSource = """
      attribute vec2 aVertexPosition;
      attribute vec2 aVertexTextCoord;
      attribute vec4 aVertexColor;
      uniform mat3 uGlobalMatrix;
      varying vec2 vTextCoord;
      varying vec4 vColor; 

      void main() {
        vTextCoord = aVertexTextCoord;
        vColor = aVertexColor;
        gl_Position = vec4(aVertexPosition, 1.0, 1.0) * mat4(uGlobalMatrix);
      }
      """;

  var _fragmentShaderSource = """
      precision mediump float;
      uniform sampler2D uSampler;
      varying vec2 vTextCoord;
      varying vec4 vColor; 

      void main() {
        vec4 color = texture2D(uSampler, vTextCoord);
        gl_FragColor = vec4(color.rgb * vColor.rgb * vColor.a, color.a * vColor.a);
      }
      """;

  //---------------------------------------------------------------------------
  // aVertexPosition:   Float32(x), Float32(y)
  // aVertexTextCoord:  Float32(u), Float32(v)
  // aVertextColor:     Float32(r), Float32(g), Float32(b), Float32(a)
  //---------------------------------------------------------------------------

  static final _SpineRenderProgram instance = new _SpineRenderProgram();

  int _contextIdentifier = -1;
  gl.RenderingContext _renderingContext = null;
  gl.Program _program = null;
  gl.Buffer _vertexBuffer = null;
  gl.Buffer _indexBuffer = null;

  Int16List _indexList = new Int16List(2048);
  Float32List _vertexList = new Float32List(1024 * 8);

  gl.UniformLocation _uGlobalMatrixLocation;
  gl.UniformLocation _uSamplerLocation;

  int _aVertexPositionLocation = 0;
  int _aVertexTextCoordLocation = 0;
  int _aVertexColorLocation = 0;
  int _vertexCount = 0;
  int _indexCount = 0;

  //-----------------------------------------------------------------------------------------------

  void activate(RenderContextWebGL renderContext) {

    if (_contextIdentifier != renderContext.contextIdentifier) {

      _contextIdentifier = renderContext.contextIdentifier;
      _renderingContext = renderContext.rawContext;
      _program = createProgram(_renderingContext, _vertexShaderSource, _fragmentShaderSource);
      _indexBuffer = _renderingContext.createBuffer();
      _vertexBuffer = _renderingContext.createBuffer();

      _aVertexPositionLocation = _renderingContext.getAttribLocation(_program, "aVertexPosition");
      _aVertexTextCoordLocation = _renderingContext.getAttribLocation(_program, "aVertexTextCoord");
      _aVertexColorLocation = _renderingContext.getAttribLocation(_program, "aVertexColor");

      _uSamplerLocation = _renderingContext.getUniformLocation(_program, "uSampler");
      _uGlobalMatrixLocation = _renderingContext.getUniformLocation(_program, "uGlobalMatrix");

      _renderingContext.enableVertexAttribArray(_aVertexPositionLocation);
      _renderingContext.enableVertexAttribArray(_aVertexTextCoordLocation);
      _renderingContext.enableVertexAttribArray(_aVertexColorLocation);

      _renderingContext.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
      _renderingContext.bufferDataTyped(gl.ELEMENT_ARRAY_BUFFER, _indexList, gl.DYNAMIC_DRAW);

      _renderingContext.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
      _renderingContext.bufferData(gl.ARRAY_BUFFER, _vertexList, gl.DYNAMIC_DRAW);
    }

    _renderingContext.useProgram(_program);
    _renderingContext.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    _renderingContext.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
    _renderingContext.vertexAttribPointer(_aVertexPositionLocation, 2, gl.FLOAT, false, 32, 0);
    _renderingContext.vertexAttribPointer(_aVertexTextCoordLocation, 2, gl.FLOAT, false, 32, 8);
    _renderingContext.vertexAttribPointer(_aVertexColorLocation, 4, gl.FLOAT, false, 32, 16);
  }

  //-----------------------------------------------------------------------------------------------

  void configure(RenderContextWebGL renderContext, Matrix globalMatrix) {

    renderContext.activateRenderProgram(this);

    Float32List uGlobalMatrix = new Float32List.fromList([
        globalMatrix.a, globalMatrix.c, globalMatrix.tx,
        globalMatrix.b, globalMatrix.d, globalMatrix.ty,
        0.0, 0.0, 1.0]);

    _renderingContext.uniformMatrix3fv(_uGlobalMatrixLocation, false, uGlobalMatrix);
    _renderingContext.uniform1i(_uSamplerLocation, 0);
  }

  //-----------------------------------------------------------------------------------------------

  void renderMesh(Int16List indexList, Float32List xyList, Float32List uvList, num r, num g, num b, num a) {

    int indexCount = _indexCount;
    int indexOffset = indexCount;
    int indexLength = indexList.length;
    bool indexFlush  = indexOffset + indexLength >= _indexList.length;

    int vertexCount = _vertexCount;
    int vertexOffset = vertexCount * 8;
    int vertexLength = uvList.length >> 1;
    bool vertexFlush = vertexOffset + vertexLength * 8 >= _vertexList.length;

    if (indexFlush || vertexFlush) {
      this.flush();
      indexCount = indexOffset = 0;
      vertexCount = vertexOffset = 0;
    }

    for(int i = 0; i < indexLength; i++) {
      _indexList[indexOffset + i] = vertexCount + indexList[i];
    }

    for(int i = 0, j = 0; i < vertexLength; i++, j+=2) {
      if (vertexOffset >= _vertexList.length - 8) continue; // dart2js_hint
      _vertexList[vertexOffset + 0] = xyList[j + 0];
      _vertexList[vertexOffset + 1] = xyList[j + 1];
      _vertexList[vertexOffset + 2] = uvList[j + 0];
      _vertexList[vertexOffset + 3] = uvList[j + 1];
      _vertexList[vertexOffset + 4] = r;
      _vertexList[vertexOffset + 5] = g;
      _vertexList[vertexOffset + 6] = b;
      _vertexList[vertexOffset + 7] = a;
      vertexOffset += 8;
    }

    _indexCount = indexCount + indexLength;
    _vertexCount = vertexCount + vertexLength;
  }

  //-----------------------------------------------------------------------------------------------

  void flush() {

    if (_vertexCount == 0 || _indexCount == 0) return;

    Float32List vertexUpdate = _vertexList;
    Int16List indexUpdate = _indexList;

    if (_vertexCount * 8 < _vertexList.length) {
      vertexUpdate = new Float32List.view(_vertexList.buffer, 0, _vertexCount * 8);
    }

    if (_indexCount < _indexList.length) {
      indexUpdate = new Int16List.view(_indexList.buffer, 0, _indexCount);
    }

    _renderingContext.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, indexUpdate);
    _renderingContext.bufferSubData(gl.ARRAY_BUFFER, 0, vertexUpdate);
    _renderingContext.drawElements(gl.TRIANGLES, _indexCount, gl.UNSIGNED_SHORT, 0);

    _indexCount = 0;
    _vertexCount = 0;
  }

}