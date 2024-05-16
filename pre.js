/*
 * Copyright (C) 2019-2024 Yahweasel and contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

// Import LibAV.base if applicable
if (typeof _scriptDir === "undefined") {
    let attempt = 0;
    do {
        try {
            if (typeof LibAV === "object" && LibAV && LibAV.base)
                _scriptDir = LibAV.base + "/libav-@VER-@VARIANT.@DBG@TARGET.@JS";
            else if (typeof self && self && self.location)
                _scriptDir = self.location.href;
        } catch (err) {
            // Handle bad assignment "ReferenceError: _scriptDir is not defined" in strict scope
            // If it fails more than once, it's a different error.
            if (!(err instanceof ReferenceError) || attempt++ > 0) throw err;
            global._scriptDir = undefined;
            continue;
        }

        break;
    } while (true);
}

Module.locateFile = function(path, prefix) {
    // if it's the wasm file
    if (path.endsWith(".wasm") && path.indexOf("libav-") !== -1) {
        // Look for overrides
        if (Module.wasmurl)
            return Module.wasmurl;
        if (Module.variant)
            return prefix + "libav-@VER-" + Module.variant + ".@DBG@TARGET.wasm";
    }

    // If it's the worker file
    if ((path.endsWith('.worker.mjs') || path.endsWith('.worker.js')) && path.indexOf("libav-") !== -1) {
        // Look for overrides
        if (Module.threadworkerurl)
            return Module.threadworkerurl;
    }

    // Otherwise, use the default
    return prefix + path;
}
