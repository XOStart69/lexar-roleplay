/**
 * Framework-agnostic NUI event listener
 *
 * @param {string} action - The action name to listen for
 * @param {function} handler - Callback function when event received
 * @returns {function} Cleanup function to remove listener
 *
 * @example
 * // Vanilla JS / Alpine
 * const cleanup = useNuiEvent('setVisible', (data) => {
 *   console.log('Visibility:', data.visible);
 * });
 * // Later: cleanup();
 *
 * @example
 * // Listen to all messages (no action filter)
 * const cleanup = useNuiEvent(null, (data) => {
 *   console.log('Any message:', data);
 * });
 */
export function useNuiEvent(action, handler) {
    const eventListener = (event) => {
        // Ignore internal frame init messages
        if (event.data?.__frameInit) return;

        const { action: eventAction, data } = event.data || {};

        // If no action specified, call handler for all messages
        if (action === null || action === undefined) {
            handler(event.data);
            return;
        }

        // If action matches, call handler with data
        if (eventAction === action) {
            handler(data);
        }
    };

    window.addEventListener('message', eventListener);

    // Return cleanup function
    return () => window.removeEventListener('message', eventListener);
}

/**
 * Listen for raw message events (no action filtering)
 *
 * @param {function} handler - Callback function
 * @returns {function} Cleanup function
 */
export function useNuiMessage(handler) {
    const eventListener = (event) => {
        if (event.data?.__frameInit) return;
        handler(event.data);
    };

    window.addEventListener('message', eventListener);
    return () => window.removeEventListener('message', eventListener);
}

/**
 * One-time event listener (auto removes after first event)
 *
 * @param {string} action - The action name to listen for
 * @param {function} handler - Callback function
 * @returns {function} Cleanup function (in case you want to cancel early)
 */
export function useNuiEventOnce(action, handler) {
    const cleanup = useNuiEvent(action, (data) => {
        cleanup();
        handler(data);
    });
    return cleanup;
}

/**
 * React Hook version - use with useEffect
 * Returns a stable event handler manager
 *
 * @example
 * // In React component
 * useEffect(() => {
 *   return useNuiEvent('setVisible', (data) => {
 *     setVisible(data.visible);
 *   });
 * }, []);
 */

/**
 * Vue 3 Composition API helper
 *
 * @example
 * // In Vue setup()
 * import { onMounted, onUnmounted } from 'vue';
 *
 * onMounted(() => {
 *   const cleanup = useNuiEvent('setVisible', (data) => {
 *     visible.value = data.visible;
 *   });
 *   onUnmounted(cleanup);
 * });
 */
