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

  static const int _maxQuadCount = 256;

  int _contextIdentifier = -1;
  gl.RenderingContext _renderingContext = null;
  gl.Program _program = null;
  gl.Buffer _vertexBuffer = null;
  gl.Buffer _indexBuffer = null;

  Int16List _indexList = new Int16List(_maxQuadCount * 6);
  Float32List _vertexList = new Float32List(_maxQuadCount * 4 * 8);

  gl.UniformLocation _uGlobalMatrixLocation;
  gl.UniformLocation _uSamplerLocation;

  int _aVertexPositionLocation = 0;
  int _aVertexTextCoordLocation = 0;
  int _aVertexColorLocation = 0;
  int _quadCount = 0;

  _SpineRenderProgram() {
    for(int i = 0, j = 0; i <= _indexList.length - 6; i += 6, j +=4 ) {
      _indexList[i + 0] = j + 0;
      _indexList[i + 1] = j + 1;
      _indexList[i + 2] = j + 2;
      _indexList[i + 3] = j + 0;
      _indexList[i + 4] = j + 2;
      _indexList[i + 5] = j + 3;
    }
  }

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
      _renderingContext.bufferDataTyped(gl.ELEMENT_ARRAY_BUFFER, _indexList, gl.STATIC_DRAW);

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

  void renderRegion(List<num> uvList, List<num> xyList, num r, num g, num b, num a) {

    int index = _quadCount * 32;
    if (index > _vertexList.length - 32) return; // dart2js_hint

    // vertex 1
    _vertexList[index + 00] = xyList[0];
    _vertexList[index + 01] = xyList[1];
    _vertexList[index + 02] = uvList[0];
    _vertexList[index + 03] = uvList[1];
    _vertexList[index + 04] = r;
    _vertexList[index + 05] = g;
    _vertexList[index + 06] = b;
    _vertexList[index + 07] = a;

    // vertex 2
    _vertexList[index + 08] = xyList[2];
    _vertexList[index + 09] = xyList[3];
    _vertexList[index + 10] = uvList[2];
    _vertexList[index + 11] = uvList[3];
    _vertexList[index + 12] = r;
    _vertexList[index + 13] = g;
    _vertexList[index + 14] = b;
    _vertexList[index + 15] = a;

    // vertex 3
    _vertexList[index + 16] = xyList[4];
    _vertexList[index + 17] = xyList[5];
    _vertexList[index + 18] = uvList[4];
    _vertexList[index + 19] = uvList[5];
    _vertexList[index + 20] = r;
    _vertexList[index + 21] = g;
    _vertexList[index + 22] = b;
    _vertexList[index + 23] = a;

    // vertex 4
    _vertexList[index + 24] = xyList[6];
    _vertexList[index + 25] = xyList[7];
    _vertexList[index + 26] = uvList[6];
    _vertexList[index + 27] = uvList[7];
    _vertexList[index + 28] = r;
    _vertexList[index + 29] = g;
    _vertexList[index + 30] = b;
    _vertexList[index + 31] = a;

    _quadCount += 1;

    if (_quadCount == _maxQuadCount) flush();
  }

  //-----------------------------------------------------------------------------------------------

  void flush() {

    Float32List vertexUpdate = _vertexList;

    if (_quadCount == 0) {
      return;
    } else if (_quadCount < _maxQuadCount) {
      vertexUpdate = new Float32List.view(_vertexList.buffer, 0, _quadCount * 4 * 8);
    }

    _renderingContext.bufferSubData(gl.ARRAY_BUFFER, 0, vertexUpdate);
    _renderingContext.drawElements(gl.TRIANGLES, _quadCount * 8, gl.UNSIGNED_SHORT, 0);
    _quadCount = 0;
  }

}