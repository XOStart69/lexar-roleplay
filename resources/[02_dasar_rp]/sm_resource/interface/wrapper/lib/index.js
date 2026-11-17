/**
 * NUI Library - Framework agnostic utilities for FiveM NUI
 *
 * @example
 * // Import all
 * import * as NUI from './lib/index.js';
 *
 * @example
 * // Import specific functions
 * import { fetchNui, useNuiEvent, useKeyListener } from './lib/index.js';
 */

export {
    isEnvBrowser,
    noop,
    Delay,
    getResourceName
} from './misc.js';

export {
    fetchNui,
    fetchNuiFrame,
    getFrameId,
    setFrameId
} from './fetchNui.js';

export {
    useNuiEvent,
    useNuiMessage,
    useNuiEventOnce
} from './useNuiEvent.js';

export {
    useKeyListener,
    useMultiKeyListener,
    useKeyCombo,
    useExitListener
} from './useKeyListener.js';

export {
    debugData,
    debugEvent,
    debugEventNow,
    debugFrameInit
} from './debugData.js';

export {
    iconClass,
    iconHtml,
    iconElement,
    icons,
    getIcon,
    getIconHtml
} from './icon.js';
