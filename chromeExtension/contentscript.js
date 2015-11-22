// $(window).scrollTop(20) // ignore the top bar
document.body.scrollLeft = (document.body.scrollWidth - document.body.clientWidth) / 2



$('.spoiler').attr('style', '')  // show the chat logs
$('.button').attr('style', 'display: none;')  // hide the "hide/show" buttons


// communicate with our container
window.onmessage = function (event) {
  $(function (){

    if (event.data.messagetype != 'your iframeSrc is') {
      console.log("got a bad message:")
      console.log(event.data)
      return;
    }

    // console.log("we are not in an iframe");
    var contentHeight = 401


    mainTable = $('body table table table table')  // hussie pls
    if (mainTable) {
      contentHeight = mainTable.height()
    }

    var url = ('' + document.location)
    // special cases for special pages
    if (url.indexOf('scratch.php') > 0) {
      tables = $('body table table')
      contentHeight = -20
      contentHeight += $(tables[0]).height()
      contentHeight += $(tables[1]).height()
    }
    else if (url.indexOf('ACT6ACT5ACT1x2COMBO.php') > 0) {
      contentHeight += 50
    }

    var message = {
      // 'messagetype': 'pageload',
      'page': document.location+'',
      'contentHeight': contentHeight,
      'iframeSrc': event.data.iframeSrc,
    }


    nextLink = $('font[size="5"] a')
    if (nextLink.length === 1) {
      message.nextLink = nextLink.attr('href').trim()
    }

    window.top.postMessage(message, '*')  // send a reply with some information about this page
  })
}















// padds a integer with zeroes so it is of string length 6
function pad6(intVal) {
  var str = '' + intVal;
  var pad = '000000';
  return pad.substring(0, pad.length - str.length) + str;
}
// create the "nextPage" and "prevPage" functions.
var pageNum, url_prev, url_next, nextPage, prevPage, comicNum;
var path = 'http://www.mspaintadventures.com/';
// if (!document.querySelector("embed")) {
pageNum = parseInt(/p=(\d+)/.exec(document.location.search)[1]);
comicNum = parseInt(/s=(\d+)/.exec(document.location.search)[1]);
url_prev = path + "?s=" + comicNum + "&p=" + pad6(pageNum - 1);
url_next = path + "?s=" + comicNum + "&p=" + pad6(pageNum + 1);
prevPage = function(){
  document.location = url_prev;
};
var link = document.querySelector('font[size="5"] a');
if (link) {
  url_next = $(link).attr('href').trim()
}
nextPage = function(){
  document.location = url_next;
}
// } else {
//   prevPage = function(){};
//   nextPage = function(){};
// }

// prerender
// html_prerender = (
//   '<link rel="prerender" href="' +
//   url_next +
//   '" />'
// )
// $("body").append(html_prerender)


// $("a").each(function () {
//   url = $(this).attr("href").trim()
//   if (url.indexOf("s=6") >= 0) {
//     // console.log($(this))
//     console.log("adding: " + html)

//     return false; // break
//   }
// })
// })


// var buttons = $('.button');
// var showButton = buttons[0];
// var hideButton = buttons[1];
// if (showButton) {
//   showButton.click()
// }

function toggleSpoiler(){
  if(showButton.parentNode.style.display === "none") {
    hideButton.click();
  } else {
    showButton.click();
  }
};

document.body.onkeydown = function(event){
  switch(event.keyCode){
    case 17:
    case 76: toggleSpoiler(); break;
    // case 39: nextPage(); break;
    // case 37: prevPage(); break;
    // case 65: scroll(); break;
  }
};





// $('a').click(function () {
//   'messagetype': 'pageleave',
// })

