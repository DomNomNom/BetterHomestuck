
cacheSize_forward = 4
baseURL = 'http://www.mspaintadventures.com/'

cache = {}  # the set of urls that are currently in iframes
for iframe in $('iframe')
    cache[$(iframe).attr('src')] = 1


# padds a integer with zeroes so it is of string length 6
# 1902 --> '001902'
pad6 = (pageNum) ->
  pad = '000000'
  str = '' + pageNum
  return pad.substring(0, pad.length - str.length) + str

# gets the URL for the next page given the current one
nextUrl = (currentUrl) ->
    pageNum  = parseInt(/p=(\d+)/.exec(currentUrl)[1])
    comicNum = parseInt(/s=(\d+)/.exec(currentUrl)[1])
    return baseURL + '?s=' + comicNum + '&p=' + pad6(pageNum + 1)
prevUrl = (currentUrl) ->
    pageNum  = parseInt(/p=(\d+)/.exec(currentUrl)[1])
    comicNum = parseInt(/s=(\d+)/.exec(currentUrl)[1])
    return baseURL + '?s=' + comicNum + '&p=' + pad6(pageNum - 1)

# link = document.querySelector('font[size='5'] a')
# if link
#     url_next = $(link).attr('href').trim()
# document.location = url_next

currentUrl = -> $('#current-page').attr('src')

getIframe = (url) ->
    iframe = $("""iframe[src="#{url}"]""")
    console.assert iframe.length == 1
    return iframe

makeIframe = (url) -> """<iframe class="stuckpage" src="#{ url }"></iframe>"""

prependToCache = (url) ->
    $('.cache-pages').prepend makeIframe url
    cache[url] = 1

appendToCache = (url) ->
    $('.cache-pages').append makeIframe url
    cache[url] = 1

removeFromCache = (url) ->
    getIframe(url).remove()
    delete cache[url]



# deals with going to a new page in the comic
update = (targetUrl) ->

    console.assert targetUrl.startsWith baseURL

    # figure out which urls we want in the cache
    urlsToCache = [targetUrl]
    url = targetUrl
    for i in [0..cacheSize_forward]
        url = nextUrl url
        urlsToCache.push(url)

    # prepend any missing pages that are logically before any element in the cache
    for i in [urlsToCache.length-1 .. 0] by -1
        url = urlsToCache[i]
        if url not of cache and nextUrl(url) of cache and url not of flashPages
            prependToCache url

    # special case for flash as they don't get preloaded
    if targetUrl of flashPages
        prependToCache targetUrl

    # append any urls that are still missing to the cache
    for url in urlsToCache
        if url not of cache and url not of flashPages
            appendToCache url

    # mark the current page (so that currentUrl() works)
    getIframe(targetUrl).attr('id', 'current-page')

    # move the view to look at the top iframe
    $(window).scrollTop(0)


    # move hold-your-horses below the current page
    $('#hold-your-horses').detach().insertAfter(getIframe(targetUrl))

    # trim the cache
    for url of cache
        if url not in urlsToCache
            removeFromCache(url)


    # try to make browser navigation work
    history.pushState({'page': targetUrl}, 'MORE HOMESTUCK', '#' + targetUrl);

    # set the links on the buttons
    basePage = document.location.href.split('#')[0]
    $('.nextlink').attr('href', '#' + nextUrl(targetUrl))
    $('.prevlink').attr('href', '#' + prevUrl(targetUrl))


# any time the url is changed by the browser
window.onpopstate = (event) ->
    # window.eventa = event
    # url = event.state.page
    url = '' + document.location
    url = url.split('#')[1]
    console.log "back: " + url
    update url


# call displayNextPage() if the user clicked on the background of the page
$('body').mousedown (event) ->
    target = $(event.target)
    if target.is('body>center') or target.is('body')
        update nextUrl currentUrl()
        event.preventDefault()


if document.location.hash.startsWith('#' + baseURL)
    update document.location.hash.substring(1)
else
    update currentUrl()

console.assert currentUrl() of cache
