// Generated by CoffeeScript 1.10.0
(function() {
  var activateIframe, appendToCache, cacheSize_forward, defaultURL, inCache, main, mainelement, makeHash, makeIframe, pollCurrentPage, prependToCache, removeFromCache, scroll, scrollAmount, sendMessageToIframe, setLinks, update, updateFromHash,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  cacheSize_forward = 6;

  defaultURL = 'http://www.mspaintadventures.com/?s=6&p=001901';

  window.currentUrl = function() {
    if ($('#current-page') != null) {
      return $('#current-page').attr('src');
    } else {
      return null;
    }
  };

  window.getIframeUnsafe = function(url) {
    return $(".stuckpage[src=\"" + url + "\"]");
  };

  window.getIframe = function(url) {
    var iframe;
    iframe = getIframeUnsafe(url);
    console.assert(iframe.length === 1);
    return iframe;
  };

  inCache = function(url) {
    var numIframes;
    numIframes = getIframeUnsafe(url).length;
    console.assert((0 <= numIframes && numIframes <= 1));
    return numIframes > 0;
  };

  makeIframe = function(url) {
    return "<iframe class=\"stuckpage\" contentHeight=\"5\" src=\"" + url + "\"></iframe>";
  };

  window.onmessage = function(event) {
    var data, ref;
    data = event.data;
    if (data.contentHeight) {
      getIframe(data.iframeSrc).attr('contentHeight', data.contentHeight);
    }
    if (data.interactive) {
      getIframe(data.page).attr('interactive', true);
    }
    if ((ref = currentUrl()) === data.iframeSrc || ref === data.page) {
      if (data.iframeSrc !== data.page && document.location.hash !== makeHash(data.page)) {
        history.pushState({}, 'Better Homestuck', makeHash(data.page));
      }
      return setLinks(data.page);
    }
  };

  sendMessageToIframe = function(iframe, url) {
    var message;
    message = {
      'messagetype': 'your iframeSrc is',
      'iframeSrc': url
    };
    return iframe[0].contentWindow.postMessage(message, '*');
  };

  activateIframe = function(url) {
    var iframe;
    iframe = getIframe(url);
    return iframe.load(function() {
      return sendMessageToIframe(iframe, url);
    });
  };

  pollCurrentPage = function() {
    return sendMessageToIframe(getIframe(currentUrl()), currentUrl());
  };

  prependToCache = function(url) {
    $('#cache-pages').prepend(makeIframe(url));
    return activateIframe(url);
  };

  appendToCache = function(url) {
    $('#cache-pages').append(makeIframe(url));
    return activateIframe(url);
  };

  removeFromCache = function(url) {
    return getIframe(url).remove();
  };

  update = function(targetUrl) {
    var i, j, k, l, len, ref, ref1, url, urlsToCache;
    console.log('updating: ' + targetUrl);
    console.assert(isHomestuckUrl(targetUrl));
    urlsToCache = [targetUrl];
    url = targetUrl;
    for (i = j = 0, ref = cacheSize_forward; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
      url = nextUrl(url);
      urlsToCache.push(url);
    }
    for (i = k = ref1 = urlsToCache.length - 1; k >= 0; i = k += -1) {
      url = urlsToCache[i];
      if ((!inCache(url)) && inCache(nextUrl(url)) && !isFlashPage(url)) {
        prependToCache(url);
      }
    }
    if (isFlashPage(url)) {
      prependToCache(targetUrl);
    }
    for (l = 0, len = urlsToCache.length; l < len; l++) {
      url = urlsToCache[l];
      if ((!inCache(url)) && !isFlashPage(url)) {
        appendToCache(url);
      }
    }
    $('#current-page').removeAttr('id');
    getIframe(targetUrl).attr('id', 'current-page');
    $('#hold-your-horses').detach().insertAfter(getIframe(targetUrl));
    $('.stuckpage').each(function() {
      url = $(this).attr('src');
      if (indexOf.call(urlsToCache, url) < 0 || (isFlashPage(url) && url !== targetUrl)) {
        return removeFromCache(url);
      }
    });
    document.title = 'Better Homestuck #' + getPageNumber(targetUrl);
    setLinks();
    return console.assert(inCache(currentUrl()));
  };

  scroll = function(topMaybe) {
    if (topMaybe != null) {
      $("html, body").stop();
      return $(window).scrollTop(topMaybe);
    } else {
      return $(window).scrollTop();
    }
  };

  updateFromHash = function(hash) {
    var expiry, hashParts, top, url;
    expiry = new Date();
    expiry.setDate(expiry.getDate() + 36000);
    document.cookie = "hash=" + hash + "; expires=" + (expiry.toUTCString());
    hashParts = hash.split('#');
    url = defaultURL;
    if (hashParts.length > 1) {
      url = hashParts[1];
    }
    top = 0;
    if (url.startsWith('http://www.mspaintadventures.com/?s=6&p=')) {
      top = 29;
    }
    if (hashParts.length > 2) {
      top = Math.max(top, parseInt(hashParts[2]));
    }
    if (url === currentUrl() || ((currentUrl() != null) && getPageNumber(url) === getPageNumber(currentUrl()))) {
      $("html, body").animate({
        scrollTop: top
      });
    } else {
      scroll(top);
      update(url);
    }
    return mainelement().focus();
  };

  makeHash = function(url, top) {
    var hash;
    if (!isHomestuckUrl(url)) {
      console.warn("url is not a homestuck url: " + url);
    }
    if (url.indexOf('#') >= 0) {
      console.warn('oh no! homestuck url has a hash in it: ' + url);
      url = url.split('#')[0];
    }
    hash = '#' + url;
    if (top != null) {
      hash += '#' + parseInt(Math.max(0, top));
    }
    return hash;
  };

  window.onpopstate = function(event) {
    console.log("popstate: " + document.location.hash);
    return updateFromHash(document.location.hash);
  };

  scrollAmount = function() {
    return 0.6 * window.innerHeight - 20;
  };

  setLinks = function(url) {
    var contentBottom, nexthash, prevhash;
    if (url == null) {
      url = currentUrl();
    }
    if (scroll() <= 30) {
      prevhash = makeHash(prevUrl(url));
    } else {
      prevhash = makeHash(url, scroll() - scrollAmount());
    }
    contentBottom = parseInt(getIframe(currentUrl()).attr('contentHeight')) - 15;
    if (scroll() + $(window).height() > contentBottom) {
      nexthash = makeHash(nextUrl(url));
    } else {
      nexthash = makeHash(url, Math.min(contentBottom + 5 - $(window).height(), scroll() + scrollAmount()));
    }
    $('#prevlink').attr('href', prevhash);
    return $('#nextlink').attr('href', nexthash);
  };

  mainelement = function() {
    var i;
    i = getIframe(currentUrl());
    if (i.attr('interactive')) {
      return i;
    }
    return document.getElementById('nextlink');
  };

  main = function() {
    var hash;
    if (String.prototype.startsWith == null) {
      String.prototype.startsWith = function(str) {
        return this.indexOf(str) === 0;
      };
    }
    $(window).scroll(function() {
      return setLinks();
    });
    hash = document.location.hash;
    if (!(hash.startsWith('#') && isHomestuckUrl(hash.split('#')[1]))) {
      if (document.cookie.startsWith('hash=#')) {
        hash = document.cookie.split(';')[0].split('hash=')[1];
      } else {
        hash = makeHash(defaultURL);
      }
    }
    updateFromHash(hash);
    return setInterval(pollCurrentPage, 500);
  };

  main();

}).call(this);

//# sourceMappingURL=main.js.map
