
# this file contains logic to deal with url strings of he comic

baseURL = 'http://www.mspaintadventures.com'

# a list of special connections in the comic
specialPageChains = [
    [136, 171]

    [4298, 4300]
    [4937, 4939]
    [4987, 4989]
    [9801, 9805]
    [6720, 6724] # jane flash game
    [6725, 6727] # jane flash game2
    # [6716]
]

# pages where both the forward/backward button should take you to the second page in the list
oneWayLinks = {
    6721: 6720
    6722: 6720
    6723: 6720
    6726: 6725
}



# these two will get initialized at the bottom of this file
# so we can use functions
specialNextLinks = {}
specialPrevLinks = {}


# when the comics start and end
comicNumRanges = {
 #s=.   . <= p <= .
    1: [   2,    135]
    2: [ 136,    216]
    3: [ 217,    217]
    4: [ 219,   1892]
    5: [1893,   1900]
    6: [1901,  10000]
}
# special pages that do not have "s=.&p=......" in them
specialPages_reverse = {
    # "#{ baseURL }?s=3":
    "#{ baseURL }":       1901
    "#{ baseURL }/":      1901
    "#{ baseURL }?s=6":   1901
    # "#{ baseURL }/?s=6":  1901
    "#{ baseURL }/DOTA/": 6715
    "#{ baseURL }/007680/007680.html": 7680
}
# all starting pages can be accessed in a special way
for comicNum, beginEnd of comicNumRanges
    specialPages_reverse["#{ baseURL }/?s=#{ comicNum }"] = beginEnd[0]

specialPages = {}
for url, pageNum of specialPages
    specialPages[pageNum] = url


# padds a integer with zeroes so it is of string length 6
# 1902 --> '001902'
pad6 = (pageNum) ->
  pad = '000000'
  str = '' + pageNum
  return pad.substring(0, pad.length - str.length) + str

# finds the comic (?s=comicNum) that contains the given page number
findComicNum = (pageNum) ->
    for comicNum, beginEnd of comicNumRanges
        if beginEnd[0] <= pageNum and pageNum <= beginEnd[1]
            return comicNum

    console.error("could not find a comic number for page number: #{ pageNum }")
    return 6

# hussie <3<
isA6A5A1X2COMBO = (pageNum) -> return 7688 <= pageNum <= 7824

# returns the full url given the number of a page
makeUrl = (pageNum) ->
    console.assert typeof(pageNum) == 'number'

    if pageNum == 1900  # deal with the case of people trying to go backwards on the starting page
        pageNum = 1901

    php = ''
    if pageNum of specialPages       then return specialPages[pageNum]
    else if pageNum == 6009          then php = 'cascade.php'
    else if pageNum == 5982          then php = 'sbahj.php'
    else if 5664 <= pageNum <= 5981  then php = 'scratch.php'
    else if 8375 <= pageNum <= 8430  then php = 'ACT6ACT6.php'
    # else if 8750 <= pageNum <= 8802  then php = 'ACT6ACT6.php'
    else if 8753 <= pageNum <= 8802  then php = 'ACT6ACT6.php'
    else if 9309 <= pageNum <= 9347  then php = 'ACT6ACT6.php'
    else if 7614 <= pageNum <= 7677  then php = 'trickster.php'
    else if isA6A5A1X2COMBO(pageNum) then php = 'ACT6ACT5ACT1x2COMBO.php'

    comicNum = findComicNum(pageNum)

    # eg. http://www.mspaintadventures.com/index.php?s=6&p=001913
    return "#{ baseURL }/#{ php }?s=#{ comicNum }&p=#{ pad6(pageNum) }"

containsPageNumber = (url) ->
    if url of specialPages_reverse then return true
    return /p=(\d+)/.exec(url).length > 0


window.getPageNumber = (url) ->
    if url of specialPages_reverse
        return specialPages_reverse[url]
    return parseInt(/p=(\d+)/.exec(url)[1])


# checks whether the page number is the first page of a comic
isBegin = (pageNum) ->
    for comicNum, beginEnd of comicNumRanges
        if beginEnd[0] == pageNum
            return true
    return false
isEnd = (pageNum) ->  # same as above, just for the last page
    for comicNum, beginEnd of comicNumRanges
        if beginEnd[1] == pageNum
            return true
    return false

# gets the URL for the next page given the current one
window.nextUrl = (url) ->
    if url of specialNextLinks
        return specialNextLinks[url]
    pageNum = getPageNumber url
    if not isEnd(pageNum)
        if isA6A5A1X2COMBO pageNum
            pageNum += 2
        else
            pageNum += 1
    return makeUrl pageNum

# gets the URL for the next page given the current one
window.prevUrl = (url) ->
    if url of specialPrevLinks
        return specialPrevLinks[url]
    pageNum = getPageNumber url
    if not isBegin(pageNum)
        if isA6A5A1X2COMBO pageNum
            pageNum -= 2
        else
            pageNum -= 1
    return makeUrl pageNum

# returns true if the page should not be preloaded
window.isFlashPage = (url) ->
    if not containsPageNumber url
        return true
    return pad6(getPageNumber url) of window.flashPages

window.pageRequiresKeyboard = (url) ->
    if not containsPageNumber url
        return false
    pageNum = pad6(getPageNumber url)
    if pageNum not of window.flashPages
        return false
    return window.flashPages[pageNum] & 2  # bitmasking



# validates whether a URL is part of the comic
window.isHomestuckUrl = (url) ->
    if url == baseURL                     then return true
    if not url.startsWith(baseURL + '/')  then return false
    if not containsPageNumber(url)        then return false
    return true



# reddit discussion urls. uses redditPages.js

window.hasRedditDiscussion = (url) ->
    pageNum = getPageNumber url
    return redditDiscussion_min <= pageNum <= redditDiscussion_max

# binary searches the redditDiscussion array (from redditPages.js)
# returnss the discussion with the highest pageNum where pageNum <= targetPageNum
bisectBelow = (bot, top, targetPageNum) ->
    if bot == top
        console.assert(bot <= targetPageNum)
        return redditDiscussions[bot][1]
    mid = (bot + top) // 2
    midPage = redditDiscussions[mid][0]
    if midPage <= targetPageNum
        return bisectBelow(mid+1, top, targetPageNum)
    else
        return bisectBelow(bot,   mid, targetPageNum)

window.getRedditDiscussionUrl = (url) ->
    console.assert hasRedditDiscussion url
    redditExtension = bisectBelow(0, redditDiscussions.length, getPageNumber url)
    return 'https://redd.it/' + redditExtension



# # if the 1st argument is a pageNumber, it is converted into a url
# getUrl = (urlOrPageNum) ->
#     if typeof(urlOrPageNum) == 'string'
#         return urlOrPageNum
#     return makeUrl(urlOrPageNum)

for pageChain in specialPageChains
    for i in [0 .. pageChain.length - 2]
        prev = makeUrl(pageChain[i]  )
        next = makeUrl(pageChain[i+1])
        specialNextLinks[prev] = next
        specialPrevLinks[next] = prev

for from, to of oneWayLinks
    from = makeUrl(parseInt(from))
    to = makeUrl(to)
    specialNextLinks[from] = to
    specialPrevLinks[from] = to
