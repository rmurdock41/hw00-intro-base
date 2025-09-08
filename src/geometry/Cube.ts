import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3) {
    super();
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {
    // 8 vertices of the cube
    this.positions = new Float32Array([
      // Front face
      -1, -1,  1, 1,  // 0
       1, -1,  1, 1,  // 1
       1,  1,  1, 1,  // 2
      -1,  1,  1, 1,  // 3
      
      // Back face
      -1, -1, -1, 1,  // 4
       1, -1, -1, 1,  // 5
       1,  1, -1, 1,  // 6
      -1,  1, -1, 1   // 7
    ]);

    // Compute averaged normals for each vertex based on adjacent faces
    this.normals = new Float32Array([
      // 0: (-1, -1, 1) - intersection of front, left, bottom faces
      -1/Math.sqrt(3), -1/Math.sqrt(3), 1/Math.sqrt(3), 0,
      // 1: (1, -1, 1) - intersection of front, right, bottom faces
      1/Math.sqrt(3), -1/Math.sqrt(3), 1/Math.sqrt(3), 0,
      // 2: (1, 1, 1) - intersection of front, right, top faces
      1/Math.sqrt(3), 1/Math.sqrt(3), 1/Math.sqrt(3), 0,
      // 3: (-1, 1, 1) - intersection of front, left, top faces
      -1/Math.sqrt(3), 1/Math.sqrt(3), 1/Math.sqrt(3), 0,
      
      // 4: (-1, -1, -1) - intersection of back, left, bottom faces
      -1/Math.sqrt(3), -1/Math.sqrt(3), -1/Math.sqrt(3), 0,
      // 5: (1, -1, -1) - intersection of back, right, bottom faces
      1/Math.sqrt(3), -1/Math.sqrt(3), -1/Math.sqrt(3), 0,
      // 6: (1, 1, -1) - intersection of back, right, top faces
      1/Math.sqrt(3), 1/Math.sqrt(3), -1/Math.sqrt(3), 0,
      // 7: (-1, 1, -1) - intersection of back, left, top faces
      -1/Math.sqrt(3), 1/Math.sqrt(3), -1/Math.sqrt(3), 0
    ]);

    // Indices for 12 triangles (36 indices total)
    this.indices = new Uint32Array([
      // Front face
      0, 1, 2,  0, 2, 3,
      // Back face
      4, 6, 5,  4, 7, 6,
      // Left face
      4, 0, 3,  4, 3, 7,
      // Right face
      1, 5, 6,  1, 6, 2,
      // Top face
      3, 2, 6,  3, 6, 7,
      // Bottom face
      4, 5, 1,  4, 1, 0
    ]);

    // Generate buffers
    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;

    // Bind index buffer
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    // Bind normal buffer
    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    // Bind position buffer
    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created cube with ${this.count} indices`);
  }
}

export default Cube;