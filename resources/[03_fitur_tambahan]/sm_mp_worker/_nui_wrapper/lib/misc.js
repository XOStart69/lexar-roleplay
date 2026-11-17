/**
 * Check if running in browser (not CEF/NUI)
 * @returns {boolean}
 */
export const isEnvBrowser = () => !window.invokeNative;

/**
 * No operation function
 */
export const noop = () => {};

/**
 * Delay/sleep helper
 * @param {number} ms - Milliseconds to wait
 * @returns {Promise<void>}
 */
export const Delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Get resource name
 * @returns {string}
 */
export const getResourceName = () => {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    if (typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    return 'nui-frame-app';
};