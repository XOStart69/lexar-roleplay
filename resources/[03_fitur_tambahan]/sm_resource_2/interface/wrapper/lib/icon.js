/**
 * Icon helper utilities for FontAwesome (CDN version)
 * Works with any framework - just generates class strings
 */

/**
 * Animation types for FontAwesome icons
 * @typedef {'spin'|'spin-pulse'|'spin-reverse'|'pulse'|'beat'|'fade'|'beat-fade'|'bounce'|'shake'|'flip'} IconAnimation
 */

/**
 * Icon size types
 * @typedef {'2xs'|'xs'|'sm'|'lg'|'xl'|'2xl'|'1x'|'2x'|'3x'|'4x'|'5x'|'6x'|'7x'|'8x'|'9x'|'10x'} IconSize
 */

/**
 * Generate FontAwesome icon class string
 *
 * @param {string} icon - Icon name (e.g., 'car', 'user', 'home')
 * @param {Object} options - Icon options
 * @param {'solid'|'regular'|'brands'|'light'|'thin'|'duotone'} options.style - Icon style (default: 'solid')
 * @param {IconSize} options.size - Icon size
 * @param {IconAnimation} options.animation - Animation type
 * @param {boolean} options.fixedWidth - Fixed width icon
 * @param {'rotate-90'|'rotate-180'|'rotate-270'|'flip-horizontal'|'flip-vertical'|'flip-both'} options.transform - Transform
 * @returns {string} Class string for FontAwesome icon
 *
 * @example
 * // Basic icon
 * iconClass('car') // 'fas fa-car'
 *
 * @example
 * // With options
 * iconClass('spinner', { animation: 'spin', size: '2x' })
 * // 'fas fa-spinner fa-spin fa-2x'
 *
 * @example
 * // Brand icon
 * iconClass('github', { style: 'brands' }) // 'fab fa-github'
 */
export function iconClass(icon, options = {}) {
    const {
        style = 'solid',
        size,
        animation,
        fixedWidth = false,
        transform
    } = options;

    const classes = [];

    // Style prefix
    const styleMap = {
        solid: 'fas',
        regular: 'far',
        brands: 'fab',
        light: 'fal',
        thin: 'fat',
        duotone: 'fad'
    };
    classes.push(styleMap[style] || 'fas');

    // Icon name
    classes.push(`fa-${icon}`);

    // Size
    if (size) classes.push(`fa-${size}`);

    // Animation
    if (animation) classes.push(`fa-${animation}`);

    // Fixed width
    if (fixedWidth) classes.push('fa-fw');

    // Transform
    if (transform) classes.push(`fa-${transform}`);

    return classes.join(' ');
}

/**
 * Generate icon HTML element string
 *
 * @param {string} icon - Icon name
 * @param {Object} options - Same as iconClass options
 * @returns {string} HTML string
 *
 * @example
 * iconHtml('car') // '<i class="fas fa-car"></i>'
 * iconHtml('spinner', { animation: 'spin' }) // '<i class="fas fa-spinner fa-spin"></i>'
 */
export function iconHtml(icon, options = {}) {
    return `<i class="${iconClass(icon, options)}"></i>`;
}

/**
 * Create icon element (DOM)
 *
 * @param {string} icon - Icon name
 * @param {Object} options - Same as iconClass options
 * @returns {HTMLElement}
 *
 * @example
 * const el = iconElement('car');
 * document.body.appendChild(el);
 */
export function iconElement(icon, options = {}) {
    const el = document.createElement('i');
    el.className = iconClass(icon, options);
    return el;
}

/**
 * Predefined icon sets for common UI elements
 */
export const icons = {
    // Navigation
    close: 'xmark',
    back: 'arrow-left',
    forward: 'arrow-right',
    up: 'arrow-up',
    down: 'arrow-down',
    menu: 'bars',
    home: 'house',

    // Actions
    save: 'floppy-disk',
    delete: 'trash',
    edit: 'pen',
    add: 'plus',
    remove: 'minus',
    search: 'magnifying-glass',
    refresh: 'rotate-right',
    settings: 'gear',

    // Status
    success: 'check',
    error: 'xmark',
    warning: 'triangle-exclamation',
    info: 'circle-info',
    loading: 'spinner',

    // User
    user: 'user',
    users: 'users',
    logout: 'right-from-bracket',
    login: 'right-to-bracket',

    // Common
    money: 'dollar-sign',
    car: 'car',
    phone: 'phone',
    map: 'map',
    clock: 'clock',
    calendar: 'calendar',
    lock: 'lock',
    unlock: 'lock-open'
};

/**
 * Get predefined icon class
 *
 * @param {keyof icons} name - Predefined icon name
 * @param {Object} options - Icon options
 * @returns {string}
 *
 * @example
 * getIcon('loading', { animation: 'spin' }) // 'fas fa-spinner fa-spin'
 * getIcon('success') // 'fas fa-check'
 */
export function getIcon(name, options = {}) {
    const iconName = icons[name] || name;
    return iconClass(iconName, options);
}

/**
 * Get predefined icon HTML
 *
 * @param {keyof icons} name
 * @param {Object} options
 * @returns {string}
 */
export function getIconHtml(name, options = {}) {
    const iconName = icons[name] || name;
    return iconHtml(iconName, options);
}
