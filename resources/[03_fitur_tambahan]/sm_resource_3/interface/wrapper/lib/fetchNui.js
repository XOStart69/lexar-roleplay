import { isEnvBrowser, Delay } from './misc.js';

/**
 * Frame ID - automatically set by wrapper on iframe load
 * @type {string|null}
 */
let frameId = null;

/**
 * Resource name - automatically set by wrapper on iframe load
 * @type {string|null}
 */
let resourceName = null;

/**
 * Initialize listener to receive frameId and resourceName from wrapper
 */
const initFrameListener = () => {
    window.addEventListener('message', (event) => {
        if (event.data?.__frameInit) {
            if (event.data.frameId) {
                frameId = event.data.frameId;
            }
            if (event.data.resourceName) {
                resourceName = event.data.resourceName;
            }
            // console.log(`[NUI] Frame initialized: ${frameId}, resource: ${resourceName}`);
        }
    });
};

// Auto-init on load
initFrameListener();

/**
 * Get current frame ID
 * @returns {string|null}
 */
export const getFrameId = () => frameId;

/**
 * Set frame ID manually (useful for testing)
 * @param {string} id
 */
export const setFrameId = (id) => {
    frameId = id;
};

/**
 * Get resource name (from wrapper or GetParentResourceName)
 * @returns {string}
 */
const getResource = () => {
    // First try resourceName injected from wrapper
    if (resourceName) return resourceName;

    // Then try GetParentResourceName (available in main NUI page)
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }

    // Fallback
    return 'sm_resource';
};

/**
 * Fetch NUI callback - global (tanpa frameId prefix)
 *
 * @param {string} eventName - The NUI callback event name
 * @param {any} data - Data to send
 * @param {Object} mock - Mock data for browser testing
 * @param {any} mock.data - Mock response data
 * @param {number} mock.delay - Mock delay in ms
 * @returns {Promise<any>}
 *
 * @example
 * const result = await fetchNui('getData', { id: 123 });
 */
export async function fetchNui(eventName, data = {}, mock = null) {
    if (isEnvBrowser()) {
        if (!mock) return null;
        if (mock.delay) await Delay(mock.delay);
        return mock.data;
    }

    const resource = getResource();
    const url = `https://${resource}/${eventName}`;

    const resp = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data),
    });

    return await resp.json();
}

/**
 * Fetch NUI callback - per frame (dengan frameId prefix)
 *
 * @param {string} eventName - The NUI callback event name
 * @param {any} data - Data to send
 * @param {Object} mock - Mock data for browser testing
 * @returns {Promise<any>}
 *
 * @example
 * // Dari frame 'antitroll' akan fetch ke 'antitroll:getData'
 * const result = await fetchNuiFrame('getData', { id: 123 });
 */
export async function fetchNuiFrame(eventName, data = {}, mock = null) {
    if (isEnvBrowser()) {
        if (!mock) return null;
        if (mock.delay) await Delay(mock.delay);
        return mock.data;
    }

    const resource = getResource();
    const callbackName = frameId ? `${frameId}:${eventName}` : eventName;
    const url = `https://${resource}/${callbackName}`;

    try {
        const resp = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data),
        });

        const result = await resp.json();
        return result;
    } catch (error) {
        throw error;
    }
}
