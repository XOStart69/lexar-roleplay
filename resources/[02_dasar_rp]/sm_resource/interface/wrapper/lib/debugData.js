import { isEnvBrowser } from './misc.js';

/**
 * Send mock NUI events for browser testing
 * Only works in development/browser environment
 *
 * @param {Array<{action: string, data: any}>} events - Events to dispatch
 * @param {number} timer - Delay before dispatch in ms (default: 1000)
 *
 * @example
 * // Test visibility toggle
 * debugData([
 *   { action: 'setVisible', data: { visible: true } }
 * ]);
 *
 * @example
 * // Multiple events with custom delay
 * debugData([
 *   { action: 'setVisible', data: { visible: true } },
 *   { action: 'updateData', data: { items: ['a', 'b', 'c'] } }
 * ], 500);
 */
export function debugData(events, timer = 1000) {
    if (!isEnvBrowser()) return;

    for (const event of events) {
        setTimeout(() => {
            window.dispatchEvent(
                new MessageEvent('message', {
                    data: {
                        action: event.action,
                        data: event.data,
                    },
                })
            );
        }, timer);
    }
}

/**
 * Send a single debug event
 *
 * @param {string} action - Action name
 * @param {any} data - Event data
 * @param {number} timer - Delay in ms
 *
 * @example
 * debugEvent('setVisible', { visible: true });
 */
export function debugEvent(action, data, timer = 1000) {
    debugData([{ action, data }], timer);
}

/**
 * Send debug event immediately (no delay)
 *
 * @param {string} action
 * @param {any} data
 */
export function debugEventNow(action, data) {
    debugData([{ action, data }], 0);
}

/**
 * Simulate frameInit from wrapper
 *
 * @param {string} frameId - The frame ID to set
 * @param {number} timer - Delay in ms
 */
export function debugFrameInit(frameId, timer = 0) {
    if (!isEnvBrowser()) return;

    setTimeout(() => {
        window.dispatchEvent(
            new MessageEvent('message', {
                data: {
                    __frameInit: true,
                    frameId: frameId,
                },
            })
        );
    }, timer);
}
