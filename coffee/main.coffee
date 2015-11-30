
cacheSize_forward = 6
defaultURL = 'http://www.mspaintadventures.com/?s=6&p=001901'



# note: this is src so that when the user has clicked a flash link, we progress to the page after that
window.currentUrl = ->
    if $('#current-page')?
        return $('#current-page').attr('src')
    else
        return null


window.getIframeUnsafe = (url) -> $(""".stuckpage[src="#{url}"]""")
window.getIframe = (url) ->
    iframe = getIframeUnsafe url
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

    # in case the user navigated within the iframe
    if data.page != data.iframeSrc
        if isHomestuckUrl data.page
            removeFromCache data.iframeSrc  # this iframe is wrong
            hash = makeHash data.page
            updateFromHash hash  # navigate to what the user navigated to in the iframe
            history.pushState({}, 'MORE HOMESTUCK', hash) # set the browserURL without leaving this page

    #find out about the size of the iframe content. (requires a message from the iframe content)
    if data.contentHeight
        # console.log "#{ data.page } -->  #{ data.contentHeight }"
        getIframe(data.page).attr('contentHeight', data.contentHeight)
        setLinks()



# communicate with the iframe (note: window.onmessage handles the response)
sendMessageToIframe = (url) ->
    message = {
        'messagetype': 'your iframeSrc is'
        'iframeSrc': url
    }
    getIframe(url)[0].contentWindow.postMessage(message, '*')

activateIframe = (url) ->
    iframe = getIframe(url)
    iframe.load ->
        setTimeout(sendMessageToIframe, 0, url)  # js WAT

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

    console.assert isHomestuckUrl targetUrl

    # figure out which urls we want in the cache
    urlsToCache = [targetUrl]
    url = targetUrl
    for i in [0..cacheSize_forward]
        url = nextUrl url
        urlsToCache.push(url)

    # prepend any missing pages that are logically before any element in the cache
    for i in [urlsToCache.length-1 .. 0] by -1
        url = urlsToCache[i]
        if (not inCache(url)) and inCache(nextUrl(url)) and not isFlashPage url
            prependToCache url

    # special case for flash as they don't get preloaded
    if isFlashPage url
        prependToCache targetUrl

    # append any urls that are still missing to the cache
    for url in urlsToCache
        if (not inCache(url)) and not isFlashPage url
            appendToCache url

    # mark the current page (so that currentUrl() works)

    $('#current-page').removeAttr('id')
    getIframe(targetUrl).attr('id', 'current-page')


    # move hold-your-horses below the current page
    $('#hold-your-horses').detach().insertAfter(getIframe(targetUrl))

    # trim the cache
    $('.stuckpage').each ->
        url = $(@).attr('src')
        if url not in urlsToCache or (isFlashPage(url) and url != targetUrl)
            removeFromCache(url)

    # try to make browser navigation work
    document.title = 'ReadHomestuck #' + getPageNumber(targetUrl)
    setLinks()

    console.assert inCache currentUrl()




# a convenience wrapper for $(window.top).scrollTop()
scroll = (topOrNot) ->
    if topOrNot?
        $("html, body").stop()
        $(window).scrollTop(topOrNot)
    else
        $(window).scrollTop()

# deals with scrolling to a location on the current page or updating to a new page
updateFromHash = (hash) ->

    # make the browser remember this hash to go back to
    expiry = new Date()
    expiry.setDate(expiry.getDate() + 36000)  # set the cookie expiry date to be way in the future
    document.cookie = "hash=#{ hash }; expires=#{ expiry.toUTCString() }"

    hashParts = hash.split('#')

    url = defaultURL
    if hashParts.length > 1
        url = hashParts[1]

    top = 0
    if url.startsWith('http://www.mspaintadventures.com/?s=6&p=')
        top = 29  # for standard pages skip the top bar

    if hashParts.length > 2
        top = Math.max(top, parseInt(hashParts[2]))


    if url == currentUrl()
        # smooth scrolling to where we want to be
        $("html, body").animate({ scrollTop: top });
    else
        # move the view to top. skip the little bar at the top for standard pages
        scroll top  # hard/fast scrolling
        update url


# given a homestuck url, returns the what the url-ending should be for the ReadHomestuck page
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
    updateFromHash document.location.hash


scrollAmount = () -> 0.6 * window.innerHeight - 20

# sets the links on the buttons to point to the correct hashes
setLinks = () ->
    if scroll() <= 30
        prevhash = makeHash prevUrl currentUrl()
    else
        prevhash = makeHash(currentUrl(), scroll() - scrollAmount())

    # if the bottom of the view is below the bottom of the content, go to the next page
    contentBottom = parseInt(getIframe(currentUrl()).attr('contentHeight')) - 15
    if scroll() + $(window).height() > contentBottom
        nexthash = makeHash nextUrl currentUrl()
    else
        nexthash = makeHash(currentUrl(), Math.min(
            contentBottom + 5 - $(window).height(),
            scroll() + scrollAmount()
        ))

    $('#prevlink').attr('href', prevhash)
    $('#nextlink').attr('href', nexthash)




main = () ->

    # old browser ECMA6 compatibility
    if not String.prototype.startsWith?
        String.prototype.startsWith = (str) ->
            @indexOf(str) == 0

    $(window).scroll(setLinks)

    hash = document.location.hash
    if not hash.startsWith('#') and document.cookie.startsWith('hash=#')
        hash = document.cookie.split(';')[0].split('hash=')[1]
    updateFromHash hash

main()
