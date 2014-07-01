/**
 * @type {Object}
 * @const
 */
var hljs = {};

/**
 * @param {string} lang
 * @param {string} code
 * @return {hljs.HighlightReturnValue}
 */
hljs.highlight = function (lang, code) {};

/**
 * @param {string} lang
 * @return {hljs.HighlightReturnValue}
 */
hljs.highlightAuto = function (code) {};

/**
 * @type {Object}
 */
hljs.HighlightReturnValue = {};

/**
 * @type {string}
 */
hljs.HighlightReturnValue.value;
