import { fetchNui } from './lib/index.js';

const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'sm_resource';

const VERTEX_SHADER = `
precision mediump float;
attribute vec2 a_position;
attribute vec2 a_texcoord;
varying vec2 textureCoordinate;
void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    textureCoordinate = a_texcoord;
}
`;

const FRAGMENT_SHADER = `
precision mediump float;
varying vec2 textureCoordinate;
uniform sampler2D external_texture;
void main() {
    gl_FragColor = texture2D(external_texture, textureCoordinate);
}
`;

const MIME = {
    jpg: 'image/jpeg',
    png: 'image/png',
    webp: 'image/webp'
};

const compileShader = (gl, type, source) => {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    return shader;
};

const createGameTexture = (gl) => {
    const texture = gl.createTexture();

    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 255, 255]));
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    return texture;
};

const createBuffer = (gl, values) => {
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(values), gl.STATIC_DRAW);
    return buffer;
};

const createGameView = (width, height) => {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;

    const gl = canvas.getContext('webgl2', {
        antialias: false,
        depth: false,
        stencil: false,
        alpha: false,
        preserveDrawingBuffer: true
    });

    const texture = createGameTexture(gl);
    const vertexBuffer = createBuffer(gl, [-1, -1, 1, -1, -1, 1, 1, 1]);
    const texBuffer = createBuffer(gl, [0, 0, 1, 0, 0, 1, 1, 1]);

    const vertexShader = compileShader(gl, gl.VERTEX_SHADER, VERTEX_SHADER);
    const fragmentShader = compileShader(gl, gl.FRAGMENT_SHADER, FRAGMENT_SHADER);
    const program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    const positionLoc = gl.getAttribLocation(program, 'a_position');
    const texcoordLoc = gl.getAttribLocation(program, 'a_texcoord');

    gl.useProgram(program);
    gl.uniform1i(gl.getUniformLocation(program, 'external_texture'), 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(positionLoc, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(positionLoc);

    gl.bindBuffer(gl.ARRAY_BUFFER, texBuffer);
    gl.vertexAttribPointer(texcoordLoc, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(texcoordLoc);

    gl.viewport(0, 0, width, height);

    return {
        canvas,
        render: () => gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4),
        cleanup: () => {
            gl.deleteTexture(texture);
            gl.deleteBuffer(vertexBuffer);
            gl.deleteBuffer(texBuffer);
            gl.deleteProgram(program);
            gl.getExtension('WEBGL_lose_context')?.loseContext();
        }
    };
};

const nextFrame = () => new Promise((resolve) => requestAnimationFrame(resolve));

const toBlob = (canvas, type, quality) => new Promise((resolve) => canvas.toBlob(resolve, type, quality));

const capture = async (request) => {
    const encoding = MIME[request.encoding] ? request.encoding : 'jpg';
    const view = createGameView(window.innerWidth, window.innerHeight);

    try {
        await nextFrame();
        view.render();

        const blob = await toBlob(view.canvas, MIME[encoding], request.quality);
        if (!blob) return null;

        const form = new FormData();
        form.append(request.field, blob, `screenshot.${encoding}`);

        const resp = await fetch(request.url, { method: 'POST', mode: 'cors', body: form });
        return await resp.text();
    } catch (err) {
        console.error('[Capture]', err);
        return null;
    } finally {
        view.cleanup();
    }
};

window.addEventListener('message', async (event) => {
    const msg = event.data;
    if (msg?.action !== 'capture' || msg._resource !== resourceName) return;
    if (typeof msg.url !== 'string' || typeof msg.field !== 'string') return;

    const body = await capture(msg);
    fetchNui('capture_result', { id: msg.id, body }).catch(console.error);
});
