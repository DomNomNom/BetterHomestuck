
cacheSize_forward = 4
baseURL = 'http://www.mspaintadventures.com/'

# padds a integer with zeroes so it is of string length 6
# 1902 --> '001902'
pad6 = (pageNum) ->
  pad = '000000'
  str = '' + pageNum
  return pad.substring(0, pad.length - str.length) + str

# hussie <3<
isA6A5A1X2COMBO = (pageNum) -> return 7688 <= pageNum <= 7824

makeUrl = (pageNum) ->
    if pageNum == 1900
        pageNum = 1901

    php = ''
    if pageNum == 7680 then return 'http://www.mspaintadventures.com/007680/007680.html'
    else if pageNum == 6009          then php = 'cascade.php'
    else if pageNum == 5982          then php = 'sbahj.php'
    else if 5664 <= pageNum <= 5981  then php = 'scratch.php'
    else if 8375 <= pageNum <= 8430  then php = 'ACT6ACT6.php'
    else if 7614 <= pageNum <= 7677  then php = 'trickster.php'
    else if isA6A5A1X2COMBO(pageNum) then php = 'ACT6ACT5ACT1x2COMBO.php'

    return baseURL + php + '?s=6&p=' + pad6(pageNum)

containsPageNumber = (url) ->
    if url.startsWith 'http://www.mspaintadventures.com/007680/' then return true
    return /p=(\d+)/.exec(url).length > 0

getPageNumber = (url) ->
    if url.startsWith 'http://www.mspaintadventures.com/007680/' then return 7680  # hussie <3<
    return parseInt(/p=(\d+)/.exec(url)[1])

# gets the URL for the next page given the current one
nextUrl = (url) ->
    pageNum = getPageNumber url
    if isA6A5A1X2COMBO pageNum
        pageNum += 2
    else
        pageNum += 1
    return makeUrl pageNum

prevUrl = (url) ->
    pageNum = getPageNumber url
    if isA6A5A1X2COMBO pageNum
        pageNum -= 2
    else
        pageNum -= 1
    return makeUrl pageNum

window.currentUrl = -> $('#current-page').attr('src')  # note: this is src so that when the user has clicked a flash link, we progress to the page after that

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

# find out about the size of the iframe content. (requires a message from the iframe content)
window.onmessage = (event) ->
    data = event.data
    if data.page != data.iframeSrc
        if isHomestuckUrl data.page
            removeFromCache data.iframeSrc  # this iframe is wrong
            update data.page  # navigate to what the user navigated to in the iframe
    if data.contentHeight
        # console.log "#{ data.page } -->  #{ data.contentHeight }"
        getIframe(data.page).attr('contentHeight', data.contentHeight)


prependToCache = (url) ->
    $('#cache-pages').prepend makeIframe url
    activateIframe url

appendToCache = (url) ->
    $('#cache-pages').append makeIframe url
    activateIframe url

removeFromCache = (url) ->
    getIframe(url).remove()

# validates whether a URL is part of the comic
isHomestuckUrl = (url) -> url.startsWith(baseURL) and containsPageNumber(url)

# a convenience wrapper for $(window.top).scrollTop()
scroll = (topOrNot) ->
    $("html, body").stop()
    if topOrNot?
        $(window).scrollTop(topOrNot)
    else
        $(window).scrollTop()

isFlashPage = (url) ->
    if not containsPageNumber url
        return true
    return pad6(getPageNumber url) of window.flashPages

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

    # move the view to top. skip the little bar at the top for standard pages
    if targetUrl.startsWith('http://www.mspaintadventures.com/?s=6&p=')
        scroll(29)
    else
        scroll(0)  # for special pages


    # move hold-your-horses below the current page
    $('#hold-your-horses').detach().insertAfter(getIframe(targetUrl))

    # trim the cache
    $('.stuckpage').each ->
        url = $(@).attr('src')
        if url not in urlsToCache or (isFlashPage(url) and url != targetUrl)
            removeFromCache(url)
        # for url of cache


    # try to make browser navigation work
    document.title = 'ReadHomestuck #' + getPageNumber(targetUrl)
    setHash targetUrl

    console.assert inCache currentUrl()


scrollAmount = () -> 0.6 * window.innerHeight - 20
goNext = () ->
    contentBottom = parseInt(getIframe(currentUrl()).attr('contentHeight')) + 20
    # if the bottom of the view is below the bottom of the content, go to the next page
    if scroll() + $(window).height() > contentBottom
        update nextUrl currentUrl()
    else
        # scroll(scroll() + 0.75 * window.innerHeight)
        $("html, body").animate({ scrollTop: Math.min(
            contentBottom + 10 - $(window).height(),
            scroll() + scrollAmount()
        )});
        setHash currentUrl()


goPrev = () ->
    if scroll() <= 30
        update prevUrl currentUrl()
    else
        $("html, body").animate({ scrollTop: scroll() - scrollAmount() }, );
        setHash currentUrl()


# sets the browserURL without leaving this page
setHash = (hash) ->
    history.pushState({}, 'MORE HOMESTUCK', '#' + hash);

updateFromHash = (hash) ->
    if hash.startsWith('#' + baseURL)
        update document.location.hash.substring(1)
    else if hash.startsWith('#next') then goNext()
    else if hash.startsWith('#prev') then goPrev()
    else
        update 'http://www.mspaintadventures.com/?s=6&p=001901' #currentUrl()

# any time the url is changed by the browser
window.onpopstate = (event) ->
    updateFromHash document.location.hash



# call displayNextPage() if the user clicked on the background of the page
$('body').mousedown (event) ->
    if event.which != 1 then return  # we only care about the left mouse button

    target = $(event.target)
    if target.is('body>center') or target.is('body')
        event.preventDefault()
        if event.pageX < $(window).width() / 2
            goPrev()
        else
            goNext()


updateFromHash document.location.hash
