import { fetchNui, useNuiMessage } from './lib/index.js';

const { createApp, reactive, onMounted, onUnmounted } = Vue;

const app = createApp({
    setup() {
        const frames = reactive({});
        const frameRefs = {};
        const iframeRefs = {};
        const runtime = {};
        let cleanupNuiListener = null;

        const HIDE_DELAY = 100;
        const READY_MAX_FRAMES = 12;
        const QUEUE_LIMIT = 50;
        const READY_FALLBACK_MS = 1000;
        let tokenSeq = 0;

        const resetRuntime = (name) => {
            const rt = runtime[name];
            if (rt?.hideTimer) clearTimeout(rt.hideTimer);
            runtime[name] = { ready: false, queue: [], hideTimer: null, token: ++tokenSeq };
            return runtime[name];
        };

        const flushFrame = (name) => {
            const rt = runtime[name];
            const el = iframeRefs[name];
            if (!rt || !el?.contentWindow) return;

            rt.ready = true;
            const queue = rt.queue;
            rt.queue = [];
            for (const data of queue) {
                el.contentWindow.postMessage(data, '*');
            }

            if (frames[name]?.focused) {
                try { el.contentWindow.focus(); } catch (err) {}
            }
        };

        const waitFrameContent = (name, token) => {
            let frame = 0;
            let settle = -1;

            const tick = () => {
                const rt = runtime[name];
                if (!rt || rt.token !== token) return;

                frame++;

                if (settle < 0) {
                    let doc = null;
                    try { doc = iframeRefs[name]?.contentDocument; } catch (err) {}
                    const root = doc && (doc.getElementById('root') || doc.getElementById('app'));
                    if (!root || root.childElementCount > 0 || frame >= READY_MAX_FRAMES) {
                        settle = frame + 2;
                    }
                }

                if (rt.ready) return;

                if (settle >= 0 && frame >= settle) {
                    flushFrame(name);
                    return;
                }

                requestAnimationFrame(tick);
            };

            requestAnimationFrame(tick);

            setTimeout(() => {
                const rt = runtime[name];
                if (rt && rt.token === token && !rt.ready) flushFrame(name);
            }, READY_FALLBACK_MS);
        };

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
            // `mounted` controls whether the iframe element exists in the DOM at all.
            // Hidden frames are unmounted (v-if) so CEF frees their fullscreen GPU
            // surface instead of keeping it composited behind display:none.
            resetRuntime(name);
            frames[name] = { url, visible, mounted: visible !== false, focused: false, gen: 0 };
        };

        const destroyFrame = (name) => {
            if (frames[name]) {
                if (runtime[name]?.hideTimer) clearTimeout(runtime[name].hideTimer);
                delete runtime[name];
                delete frames[name];
                delete frameRefs[name];
                delete iframeRefs[name];
            }
        };

        const showFrame = (name) => {
            const frame = frames[name];
            if (!frame) return;

            const rt = runtime[name];
            const pendingHide = rt?.hideTimer;

            if (frame.mounted && frame.visible && !pendingHide) return;

            resetRuntime(name);
            delete iframeRefs[name];
            frame.gen += 1;
            frame.visible = true;
            frame.mounted = true;
        };

        const hideFrame = (name) => {
            const frame = frames[name];
            if (!frame) return;

            frame.visible = false;
            frame.focused = false;

            const rt = runtime[name];
            if (!rt) return;

            rt.queue = [];
            if (rt.hideTimer) clearTimeout(rt.hideTimer);

            rt.hideTimer = setTimeout(() => {
                rt.hideTimer = null;
                rt.ready = false;
                frame.mounted = false;
                delete frameRefs[name];
                delete iframeRefs[name];
            }, HIDE_DELAY);
        };

        const focusFrame = (name) => {
            for (let key in frames) {
                frames[key].focused = key === name;
            }
            try {
                if (name && iframeRefs[name] && iframeRefs[name].contentWindow) {
                    iframeRefs[name].contentWindow.focus();
                }
            } catch (err) {
                console.error('[Wrapper] Error focusing frame:', name, err);
            }
        };

        const sendToFrame = (name, data) => {
            try {
                const frame = frames[name];
                const rt = runtime[name];
                if (!frame?.mounted || !rt || rt.hideTimer) return;

                if (!rt.ready) {
                    if (rt.queue.length < QUEUE_LIMIT) rt.queue.push(data);
                    return;
                }

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
            initFrame(name);
            const rt = runtime[name];
            if (rt) waitFrameContent(name, rt.token);
            fetchNui('frame_ready', { name }).catch(console.error);
        };

        const handleFrameMessage = (name, msg) => {
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
            cleanupNuiListener = useNuiMessage(handleNuiMessage);
            notifyReady();
        });

        onUnmounted(() => {
            window.removeEventListener('message', handleWindowMessage);
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