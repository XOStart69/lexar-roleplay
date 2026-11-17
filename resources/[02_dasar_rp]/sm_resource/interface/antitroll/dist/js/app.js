import { fetchNuiFrame, useNuiEvent } from "../../../wrapper/lib/index.js";

const { createApp, ref, computed } = Vue;

const app = createApp({
    setup() {
        const show = ref(false);
        const minutes = ref(0);
        let deadline = 0;
        let timeoutId = null;
        let refreshMs = 300000;

        const clear = () => {
            if (timeoutId) {
                clearTimeout(timeoutId);
                timeoutId = null;
            }
        };

        const remaining = () => Math.max(0, Math.round((deadline - Date.now()) / 1000));

        const tick = () => {
            timeoutId = null;
            const left = remaining();

            if (left <= 0) {
                minutes.value = 0;
                show.value = false;
                fetchNuiFrame('timeFinish', {});
                return;
            }

            minutes.value = Math.ceil(left / 60);
            timeoutId = setTimeout(tick, Math.min(refreshMs, left * 1000));
        };

        const setTime = (seconds, saveInterval) => {
            clear();

            if (seconds <= 0) {
                minutes.value = 0;
                show.value = false;
                return;
            }

            if (saveInterval > 0) refreshMs = saveInterval * 60000;

            deadline = Date.now() + seconds * 1000;
            show.value = true;
            tick();
        };

        const formattedTime = computed(() => `${minutes.value} min`);

        useNuiEvent('setTimer', (data) => {
            setTime(data?.time || 0, data?.saveInterval || 0);
        });

        useNuiEvent('stopTimer', () => {
            clear();
            deadline = 0;
            minutes.value = 0;
            show.value = false;
        });

        useNuiEvent('toggleUI', (data) => {
            show.value = remaining() > 0 ? data?.state : false;
        });

        return {
            show,
            minutes,
            formattedTime
        };
    }
});

app.mount('#app');
