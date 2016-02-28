
defaultURL = 'http://www.mspaintadventures.com/?s=6&p=001901'

defaultSettings = {
    'page-cache-size':      5
    'page-cache-size-back': 2

    'minimal-ui': false
    'sidebar-size': 20

    'scroll-enabled': true
    'scroll-duration': 400
    'scroll-amount-percent': 60
    'scroll-amount-pixel': -20
}

settingClamps = {
    'page-cache-size':      [0, 20]
    'page-cache-size-back': [0, 20]
    'scroll-duration': [0, 10000]
    'sidebar-size': [1, 60]
}



getSetting = (setting) ->
    console.assert not setting.startsWith('#')
    console.assert setting of defaultSettings
    defaultSetting = defaultSettings[setting]
    switch typeof defaultSetting
        when "number"
            val = parseInt $('#' + setting).val()
            if isNaN val
                console.warn "using defaultSetting value for #{setting} due to NaN from field"
                return defaultSettings[setting]
            return val
        when "boolean"
            return $('#' + setting).is(':checked')
        else
            console.warn "requested setting is of a weird type: #{ typeof defaultSetting }"
            return defaultSetting


setSetting = (setting, value) ->
    console.assert not setting.startsWith('#')
    console.assert setting of defaultSettings
    defaultSetting = defaultSettings[setting]
    console.assert ((typeof value) == typeof defaultSetting)

    switch typeof value
        when "number"  then $('#' + setting).val(value)
        when "boolean" then $('#' + setting).prop('checked', value);
        else
            console.warn "requested setting is of a weird type: #{ typeof defaultSetting }"
            return defaultSetting

onSettingsChanged = () ->

    # apply clamps
    for setting, minMax of settingClamps
        min = minMax[0]
        max = minMax[1]
        if getSetting(setting) > max then setSetting(setting, max)
        if getSetting(setting) < min then setSetting(setting, min)

    # set the cookies
    for setting, defaultSetting of defaultSettings
        setCookie(setting, getSetting(setting))


    # apply setting: scroll-enabled
    # iff scroll is disabled, disable sub-settings
    scrollSubSettings = [
        'scroll-duration'
        'scroll-amount-percent'
        'scroll-amount-pixel'
    ]
    scrollEnabled = getSetting('scroll-enabled')
    for setting in scrollSubSettings
        $('#' + setting).prop('disabled', not scrollEnabled);



    # apply setting: minimal-ui
    # apply setting: sidebar-size
    $('#sidebar-size').prop('disabled', getSetting('minimal-ui'));
    if getSetting('minimal-ui')
        $('#sidebar').addClass('minimal-ui');

        sideWidth = 40
        $('#sidebar').width(        sideWidth + 'px')
        $('#settings').css('right', sideWidth + 'px')
        $('#cache-pages').width('100%')

    else
        $('#sidebar').removeClass('minimal-ui')

        sideWidth = getSetting('sidebar-size')
        $('#sidebar').width(        sideWidth + '%')
        $('#settings').css('right', sideWidth + '%')
        $('#cache-pages').width((100 - sideWidth) + '%')


resetAllSettings = () ->
    if not window.confirm("Reset all settings?") then return
    for setting, defaultSetting of defaultSettings
        setSetting(setting, defaultSetting)
    onSettingsChanged()


setCookie = (name, value) ->
    expiry = new Date()
    expiry.setDate(expiry.getDate() + 36000)  # set the cookie expiry date to be way in the future
    document.cookie = "#{ name }=#{ value }; expires=#{ expiry.toUTCString() }"

getCookie = (cookieName, defaultSetting='') ->
    nameEquals = cookieName + '='
    for cookie in document.cookie.split(';')
        cookie = cookie.trim()
        if cookie.startsWith(nameEquals)
            value = cookie.substring(nameEquals.length).trim()
            switch typeof defaultSetting
                when "string"  then return value
                when "number"  then return parseInt value
                when "boolean" then return value == "true"
                else console.warn "defaultSetting for #{ cookieName } had a bad type: #{ typeof defaultSetting }"

    console.info "did not find cookie for name: #{ cookieName }. Using default: #{ defaultSetting }"
    return defaultSetting



# note: this is src so that when the user has clicked a flash link, we progress to the page after that
_currentUrl = null
window.currentUrl = () ->
    return _currentUrl


window.getIframeUnsafe = (url) -> $(""".stuckpage[src="#{url}"]""")
window.getIframe = (url) ->
    iframe = getIframeUnsafe url
    console.assert iframe.length == 1
    return iframe
window.haveCurrentIframe = () -> $('#current-page').length > 0
window.getCurrentIframe = () ->
    iframe = $('#current-page')
    console.assert iframe.length == 1
    return iframe

# returns whether a given url is in cache or not
inCache = (url) ->
    numIframes = getIframeUnsafe(url).length
    console.assert 0 <= numIframes <= 1
    return numIframes > 0

makeIframe = (url) -> """<iframe class="stuckpage" contentHeight="5" src="#{ url }"></iframe>"""



# respond to messages from the iframees
window.onmessage = (event) ->
    data = event.data

    # find out about the size of the iframe content. (requires a message from the iframe content)
    if data.contentHeight
        # console.debug "contentHeight (#{ data.iframeSrc },  #{ data.page }) -->  #{ data.contentHeight }"
        getIframe(data.iframeSrc).attr('contentHeight', data.contentHeight)

    if data.windowHeight
        getIframe(data.iframeSrc).css("height", "#{ data.windowHeight }")

    # is this information regarding the current iframe?
    if getCurrentIframe().attr('src') == data.iframeSrc
        # special logic for when the user navigated within the iframe
        if currentUrl() != data.page
            _currentUrl = data.page  # pretend that we make an update without changing any iframes
            scroll getTopLocation(currentUrl())
            history.pushState({}, 'Better Homestuck', makeHash currentUrl()) # set the browserURL without leaving this page
            if isHomestuckUrl(currentUrl())
                setCookie('hash', makeHash currentUrl())


            # console.debug "The iframe url changed: #{ currentUrl() } --> #{ data.page }"
        setLinks(data.page)


    # switch focus out of the iframe unless it has keyboard interaction
    if document.activeElement.tagName == 'IFRAME'
        focusElement().focus()

focusElement = () ->
    if pageRequiresKeyboard(currentUrl())
        return getCurrentIframe()
    return document.getElementById('nextlink')




# communicate with the iframe (note: window.onmessage handles the response)
sendMessageToIframe = (iframe, url) ->
    # if getIframeUnsafe(url).length == 0
    #     console.debug 'iframe src changed.'
    message = {
        'messagetype': 'your iframeSrc is'
        'iframeSrc': url
    }
    iframe[0].contentWindow.postMessage(message, '*')

activateIframe = (url) ->
    iframe = getIframe(url)
    iframe.load ->
        sendMessageToIframe(iframe, url)

# sometimes we get redirected and the iframe src goes out of sync with what we expect the page to be
# this is a hack to get around that
pollCurrentPage = () ->
    sendMessageToIframe(getCurrentIframe(), getCurrentIframe().attr('src'))



prependToCache = (url) ->
    $('#cache-pages').prepend makeIframe url
    activateIframe url

appendToCache = (url) ->
    $('#cache-pages').append makeIframe url
    activateIframe url

removeFromCache = (url) ->
    getIframe(url).remove()


# deals with going to a new page in the comic
update = (targetUrl) ->
    # console.debug ('updating: ' + targetUrl)
    console.assert isHomestuckUrl targetUrl
    # figure out which urls we want in the cache
    urlsToCache = [targetUrl]
    cacheSize_back = getSetting 'page-cache-size-back'
    url = targetUrl
    for i in [0..cacheSize_back]
        url = prevUrl url
        if url == targetUrl then break
        urlsToCache.unshift url

    url = targetUrl
    cacheSize_forward = getSetting 'page-cache-size'
    for i in [0..cacheSize_forward]
        url = nextUrl url
        urlsToCache.push(url)

    # if the current page has been navigated in-iframe, remove it
    # note: this deals with inner-forward, outer-backward navigation
    if haveCurrentIframe() and getCurrentIframe().attr('src') != currentUrl()
        console.info "removing iframe due to content change: #{ getCurrentIframe().attr('src') }  #{ currentUrl() }"
        removeFromCache(getCurrentIframe().attr('src'))

    # prepend any missing pages that are logically before any element in the cache
    for i in [urlsToCache.length-1 .. 0] by -1
        url = urlsToCache[i]
        if (not inCache(url)) and inCache(nextUrl(url)) and not isFlashPage url
            prependToCache url

    # special case for flash as they don't get preloaded
    if isFlashPage targetUrl
        prependToCache targetUrl

    # append any urls that are still missing to the cache
    for url in urlsToCache
        if (not inCache(url)) and not isFlashPage url
            appendToCache url

    # change what currentUrl means
    _currentUrl = targetUrl
    $('#current-page').removeAttr('id')
    getIframe(targetUrl).attr('id', 'current-page')


    # move hold-your-horses below the current page
    $('#hold-your-horses').detach().insertAfter(getIframe(targetUrl))

    # trim the cache
    $('.stuckpage').each ->
        url = $(@).attr('src')
        if url not in urlsToCache or (isFlashPage(url) and url != targetUrl)
            removeFromCache(url)

    document.title = 'Better Homestuck #' + getPageNumber(targetUrl)
    setLinks()

    console.assert inCache currentUrl()




# a convenience wrapper for $(window.top).scrollTop()
scroll = (topMaybe) ->
    if topMaybe?
        $("html, body").stop()
        $(window).scrollTop(topMaybe)
    else
        $(window).scrollTop()

# the scroll height that is the top of the content
getTopLocation = (url) ->
    if url.startsWith('http://www.mspaintadventures.com/?s=6&p=')
        return 29  # for standard pages skip the top bar
    return 0


# deals with scrolling to a location on the current page or updating to a new page
updateFromHash = (hash) ->


    # make the browser remember this hash to go back to
    setCookie('hash', hash)

    hashParts = hash.split('#')

    url = defaultURL
    if hashParts.length > 1
        url = hashParts[1]

    top = getTopLocation(url)

    # if we have an instruction to go to a specific height, follow it
    if hashParts.length > 2
        top = Math.max(top, parseInt(hashParts[2]))


    if url == currentUrl() || (currentUrl()? and getPageNumber(url) == getPageNumber(currentUrl()))
        # smooth scrolling to where we want to be
        $("html, body").animate(
            { scrollTop: top },
            duration=getSetting 'scroll-duration'
        )
    else
        # move the view to top. skip the little bar at the top for standard pages
        scroll top  # hard/fast scrolling
        update url


# given a homestuck url, returns the what the url-ending should be for the BetterHomestuck page
makeHash = (url, top) ->
    if not isHomestuckUrl url
        console.warn "url is not a homestuck url: " + url

    if url.indexOf('#') >= 0
        console.warn 'oh no! homestuck url has a hash in it: ' + url
        url = url.split('#')[0]

    hash = '#' + url
    if top?
        hash += '#' + parseInt(Math.max(0, top))

    return hash


# any time the url is changed by the browser. eg. clicking one of the buttons
window.onpopstate = (event) ->
    # console.debug "popstate: " + document.location.hash
    updateFromHash document.location.hash


scrollAmount = () -> (getSetting('scroll-amount-percent') / 100.0) * window.innerHeight + getSetting('scroll-amount-pixel')

# sets the links on the buttons to point to the correct hashes
setLinks = (url) ->
    if not url?
        url = currentUrl()

    contentBottom = parseInt(getCurrentIframe().attr('contentHeight')) - 15
    bottomMostScroll = contentBottom + 5 - $(window).height()  # if we go down further, there is no content to be seen

    if scroll() <= 30 or not getSetting('scroll-enabled')
        prevhash = makeHash prevUrl url
    else
        prevhash = makeHash(url, Math.min(bottomMostScroll, scroll() - scrollAmount()))

    # if the bottom of the view is below the bottom of the content, go to the next page
    if scroll() + $(window).height() > contentBottom or not getSetting('scroll-enabled')
        nexthash = makeHash nextUrl url
    else
        nexthash = makeHash(url, Math.min(bottomMostScroll, scroll() + scrollAmount()))

    $('#prevlink').attr('href', prevhash)
    $('#nextlink').attr('href', nexthash)

onScroll = () ->
    setLinks()


main = () ->

    # old browser ECMA6 compatibility
    if not String.prototype.startsWith?
        String.prototype.startsWith = (str) ->
            @indexOf(str) == 0


    # event listeners
    $('#settings-toggle').click -> $('#settings').toggle()
    $('#settings-reset-all').click resetAllSettings
    $(document).keydown (e) ->
        switch(e.which)
            when 37 then $('#prevlink')[0].click() # left
            when 39 then $('#nextlink')[0].click() # right

    # populate the settings from cookie or defaultSettings
    for setting, defaultSetting of defaultSettings
        console.assert $('#'+setting).length == 1  # check that there's a html setting for each setting
        value = getCookie(setting, defaultSetting)
        console.assert ((typeof value) == typeof defaultSetting)
        setSetting(setting, value)

    onSettingsChanged()

    # call onSettingsChanged when values are changedget the
    for setting, defaultSetting of defaultSettings
        $('#' + setting).change(onSettingsChanged)

    hash = document.location.hash
    if not (hash.startsWith('#') and isHomestuckUrl(hash.split('#')[1])) # if url is not a valid hash
        hash = getCookie('hash')
        if hash is ''
            hash = makeHash defaultURL
    updateFromHash hash

    # things that assume there is a current page
    setInterval(pollCurrentPage, 500)
    $(window).scroll(onScroll)


main()
