/**
 * Single key listener
 *
 * @param {string} key - Key to listen for (e.g., 'Escape', 'Enter', 'a')
 * @param {function} handler - Callback function
 * @param {Object} options - Options
 * @param {HTMLElement|Window} options.target - Target element (default: window)
 * @param {'keydown'|'keyup'|'keypress'} options.eventType - Event type (default: 'keydown')
 * @param {boolean} options.preventDefault - Prevent default behavior
 * @param {boolean} options.stopPropagation - Stop event propagation
 * @param {boolean} options.enabled - Enable/disable listener (default: true)
 * @returns {function} Cleanup function
 *
 * @example
 * const cleanup = useKeyListener('Escape', () => {
 *   console.log('Escape pressed!');
 *   fetchNui('close');
 * });
 */
export function useKeyListener(key, handler, options = {}) {
    const {
        target = window,
        eventType = 'keydown',
        preventDefault = false,
        stopPropagation = false,
        enabled = true
    } = options;

    if (!enabled) return () => {};

    const eventHandler = (event) => {
        if (event.key === key) {
            if (preventDefault) event.preventDefault();
            if (stopPropagation) event.stopPropagation();
            handler(event);
        }
    };

    target.addEventListener(eventType, eventHandler);
    return () => target.removeEventListener(eventType, eventHandler);
}

/**
 * Multiple keys listener
 *
 * @param {string[]} keys - Array of keys to listen for
 * @param {function} handler - Callback function
 * @param {Object} options - Same as useKeyListener
 * @returns {function} Cleanup function
 *
 * @example
 * const cleanup = useMultiKeyListener(['Escape', 'Backspace'], () => {
 *   closeMenu();
 * });
 */
export function useMultiKeyListener(keys, handler, options = {}) {
    const {
        target = window,
        eventType = 'keydown',
        preventDefault = false,
        stopPropagation = false,
        enabled = true
    } = options;

    if (!enabled) return () => {};

    const eventHandler = (event) => {
        if (keys.includes(event.key)) {
            if (preventDefault) event.preventDefault();
            if (stopPropagation) event.stopPropagation();
            handler(event);
        }
    };

    target.addEventListener(eventType, eventHandler);
    return () => target.removeEventListener(eventType, eventHandler);
}

/**
 * Key combination listener (Ctrl+S, Alt+Enter, etc.)
 *
 * @param {Object} combo - Key combination
 * @param {string} combo.key - The main key
 * @param {boolean} combo.ctrl - Require Ctrl key
 * @param {boolean} combo.alt - Require Alt key
 * @param {boolean} combo.shift - Require Shift key
 * @param {boolean} combo.meta - Require Meta/Cmd key
 * @param {function} handler - Callback function
 * @param {Object} options - Same as useKeyListener
 * @returns {function} Cleanup function
 *
 * @example
 * const cleanup = useKeyCombo({ key: 's', ctrl: true }, () => {
 *   saveData();
 * });
 */
export function useKeyCombo(combo, handler, options = {}) {
    const {
        target = window,
        eventType = 'keydown',
        preventDefault = true,
        stopPropagation = true,
        enabled = true
    } = options;

    if (!enabled) return () => {};

    const eventHandler = (event) => {
        const matchesKey = event.key.toLowerCase() === combo.key.toLowerCase();
        const matchesCtrl = combo.ctrl ? event.ctrlKey : !event.ctrlKey;
        const matchesAlt = combo.alt ? event.altKey : !event.altKey;
        const matchesShift = combo.shift ? event.shiftKey : !event.shiftKey;
        const matchesMeta = combo.meta ? event.metaKey : !event.metaKey;

        if (matchesKey && matchesCtrl && matchesAlt && matchesShift && matchesMeta) {
            if (preventDefault) event.preventDefault();
            if (stopPropagation) event.stopPropagation();
            handler(event);
        }
    };

    target.addEventListener(eventType, eventHandler);
    return () => target.removeEventListener(eventType, eventHandler);
}

/**
 * Exit listener - shortcut for Escape key to close UI
 *
 * @param {function} onExit - Callback when Escape is pressed
 * @param {Object} options - Additional options
 * @param {boolean} options.autoFetchNui - Auto call fetchNui('exit') (default: false)
 * @returns {function} Cleanup function
 *
 * @example
 * const cleanup = useExitListener(() => {
 *   setVisible(false);
 * });
 */
export function useExitListener(onExit, options = {}) {
    const { autoFetchNui = false } = options;

    return useKeyListener('Escape', async () => {
        onExit();
        if (autoFetchNui) {
            const { fetchNuiFrame } = await import('./fetchNui.js');
            fetchNuiFrame('exit');
        }
    });
}
