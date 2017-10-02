/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

(function() {
  window.ios_mobile_bridge = {
    speak: function(text, flush) {
      $IOS.callNative('SpeechSynthesizer', 'speak', {
                    'text': text,
                    'flush': flush
                    });
    },
    setCallback: function(name) {
      $IOS.callNative('Property', 'callback', {
                    'value': name
                    });
    },
    isSpeaking: function(name) {
      $IOS.callNative('SpeechSynthesizer', 'isSpeaking', {
                    callbackname: name
                    });
    },
    startRecognizer: function(name) {
      $IOS.callNative('STT', 'startRecognizer', {
                    callbackname: name
                    });
    },
    mapCenter: function(lat, lng, floor, sync) {
      $IOS.callNative('Property', 'mapCenter', {
                    'lat': lat,
                    'lng': lng,
                    'floor': floor,
                    'sync': sync
                    });
    },
    logText: function(text) {
      $IOS.callNative('System', 'log', {
                    'text': text
                    });
    },
    vibrate: function() {
      $IOS.callNative('AudioServices', 'vibrate', {});
    },
    mIsSpeaking: false
  }

  if (window.$hulop && window.$hulop.mobile_ready) {
    window.$hulop.mobile_ready(ios_mobile_bridge);
    return "SUCCESS";
  }
  return "ERROR";
})();
