import { fetchNui, useNuiMessage } from './lib/index.js';

const { createApp, reactive, onMounted, onUnmounted } = Vue;

const app = createApp({
    setup() {
        const frames = reactive({});
        const frameRefs = {};
        const iframeRefs = {};
        let cleanupNuiListener = null;
        let focusedFrame = null;

        const setFrameRef = (name, el) => {
            if (el) frameRefs[name] = el;
        };

        const setIframeRef = (name, el) => {
            if (el) iframeRefs[name] = el;
        };

        const getFrameStyle = (frame) => ({
            display: frame.visible ? 'block' : 'none',
            pointerEvents: frame.focused ? 'all' : 'none'
        });

        const createFrame = (name, url, visible = true) => {
            if (frames[name]) {
                destroyFrame(name);
            }
            // `mounted` controls whether the iframe element exists in the DOM at all.
            // Hidden frames are unmounted (v-if) so CEF frees their fullscreen GPU
            // surface instead of keeping it composited behind display:none.
            frames[name] = { url, visible, mounted: visible !== false, focused: false };
        };

        const destroyFrame = (name) => {
            if (frames[name]) {
                if (focusedFrame === name) focusedFrame = null;
                delete frames[name];
                delete frameRefs[name];
                delete iframeRefs[name];
            }
        };

        const showFrame = (name) => {
            if (frames[name]) {
                frames[name].visible = true;
                frames[name].mounted = true;
            }
        };

        const hideFrame = (name) => {
            if (frames[name]) {
                if (focusedFrame === name) focusedFrame = null;
                frames[name].visible = false;
                frames[name].focused = false;
                // Unmount the iframe and drop its refs; a fresh element is created
                // on the next showFrame, releasing the GPU surface in the meantime.
                frames[name].mounted = false;
                delete frameRefs[name];
                delete iframeRefs[name];
            }
        };

        // Keyboard focus harus berada di document DALAM iframe agar listener
        // keydown/keyup milik frame menerima input tanpa perlu klik manual.
        const refocusFrame = () => {
            if (!focusedFrame) return;
            const el = iframeRefs[focusedFrame];
            try {
                if (el) {
                    el.focus();
                    el.contentWindow?.focus();
                }
            } catch (err) {
                console.error('[Wrapper] Error refocusing frame:', focusedFrame, err);
            }
        };

        // SetNuiFocus bisa mendaratkan focus di document wrapper setelah
        // focus_frame diproses; key event yang nyasar diteruskan ke frame aktif.
        const forwardKeyEvent = (e) => {
            if (!focusedFrame) return;
            const win = iframeRefs[focusedFrame]?.contentWindow;
            if (!win) return;
            try {
                win.dispatchEvent(new KeyboardEvent(e.type, {
                    key: e.key,
                    code: e.code,
                    keyCode: e.keyCode,
                    which: e.which,
                    shiftKey: e.shiftKey,
                    ctrlKey: e.ctrlKey,
                    altKey: e.altKey,
                    metaKey: e.metaKey
                }));
            } catch (err) {
                console.error('[Wrapper] Error forwarding key event:', focusedFrame, err);
            }
            refocusFrame();
        };

        const focusFrame = (name) => {
            for (let key in frames) {
                frames[key].focused = key === name;
            }
            focusedFrame = frames[name] ? name : null;
            refocusFrame();
        };

        const sendToFrame = (name, data) => {
            try {
                if (iframeRefs[name] && iframeRefs[name].contentWindow) {
                    iframeRefs[name].contentWindow.postMessage(data, '*');
                }
            } catch (err) {
                console.error('[Wrapper] Error sending to frame:', name, err);
            }
        };

        const resourceName = typeof GetParentResourceName === 'function'
            ? GetParentResourceName()
            : 'rhd_modules';

        const initFrame = (name) => {
            try {
                if (iframeRefs[name] && iframeRefs[name].contentWindow) {
                    iframeRefs[name].contentWindow.postMessage({
                        __frameInit: true,
                        frameId: name,
                        resourceName: resourceName
                    }, '*');
                }
            } catch (err) {
                console.error('[Wrapper] Error initializing frame:', name, err);
            }
        };

        const onIframeLoad = (name) => {
            // console.log(`[Wrapper] Frame loaded: ${name}`);
            initFrame(name);
        };

        const handleFrameMessage = (name, msg) => {
            console.log(name, msg, 'RHD')
            fetchNui('frame_message', { name, msg }).catch(console.error);
        };

        const handleWindowMessage = (event) => {
            for (let name in iframeRefs) {
                if (iframeRefs[name]?.contentWindow === event.source) {
                    handleFrameMessage(name, event.data);
                    return;
                }
            }
        };

        const handleNuiMessage = (msg) => {
            if (!msg) return;

            // Filter messages by resource origin to prevent cross-resource NUI contamination
            if (msg._resource && msg._resource !== resourceName) {
                return;
            }

            if (msg.target && frames[msg.target]) {
                sendToFrame(msg.target, msg.data);
                return;
            }

            const actions = {
                create_frame: () => createFrame(msg.name, msg.url, msg.visible),
                destroy_frame: () => destroyFrame(msg.name),
                show_frame: () => showFrame(msg.name),
                hide_frame: () => hideFrame(msg.name),
                focus_frame: () => focusFrame(msg.name)
            };

            actions[msg.action]?.();
        };

        const notifyReady = () => {
            fetchNui('nui_ready', {})
                .then(() => console.log('[Wrapper] Ready signal sent'))
                .catch(console.error);
        };

        onMounted(() => {
            window.addEventListener('message', handleWindowMessage);
            window.addEventListener('focus', refocusFrame);
            window.addEventListener('keydown', forwardKeyEvent);
            window.addEventListener('keyup', forwardKeyEvent);
            cleanupNuiListener = useNuiMessage(handleNuiMessage);
            notifyReady();
        });

        onUnmounted(() => {
            window.removeEventListener('message', handleWindowMessage);
            window.removeEventListener('focus', refocusFrame);
            window.removeEventListener('keydown', forwardKeyEvent);
            window.removeEventListener('keyup', forwardKeyEvent);
            cleanupNuiListener?.();
        });

        return {
            frames,
            getFrameStyle,
            setFrameRef,
            setIframeRef,
            onIframeLoad
        };
    }
});

app.mount('#app');
