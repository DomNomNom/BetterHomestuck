
// center the document if we don't have enough width
function centerView() {
  document.body.scrollLeft = (document.body.scrollWidth - document.body.clientWidth) / 2;
}
$(centerView())
$(window).resize(centerView)

function docScratchReadability() {
  // kudos to https://github.com/murgatroid99/doc-scratch-readability-extension/blob/master/js/content_script.js
  // although the code as been make much nicer with jquery
  function setupHoverBehaviour() {
    this.style.background = "transparent";
    // these colours are more more true to character but don't look as good in context: #2cff4b #0e4603
    this.onmouseover = function(){  this.style.background="green";  };
    this.onmouseout  = function(){  this.style.background="transparent";  };
  }
  $('.spoiler span[style*="color: #FFFFFF"]').each(setupHoverBehaviour)
  $('.spoiler span[style*="color: #ffffff"]').each(setupHoverBehaviour)
}
docScratchReadability();


if (document.location.toString().indexOf("p=007326") < 0) {  // special case, because hussie
  $('.spoiler').attr('style', '')  // show the chat logs
  $('.button').attr('style', 'display: none;')  // hide the "hide/show" buttons

  // I think this padding is unnecessary
  $('img[src="http://cdn.mspaintadventures.com/images/v2_blanksquare2.gif"]').remove()
  $('img[src="http://cdn.mspaintadventures.com/images/v2_blanksquare3.gif"]').remove()
}


// remove empty paragraphs
$('p').each(function() {
  if ($(this).html().trim() === "") {
    $(this).remove()
  }
})



// communicate with our container
window.onmessage = function (event) {
  if (event.data.messagetype == 'your iframeSrc is') {
    $(function () {


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

      var interaction = mainTable.find('embed, canvas')
      if (interaction) interaction.focus()

      var message = {
        // 'messagetype': 'pageload',
        'page': document.location+'',
        'contentHeight': contentHeight,
        'iframeSrc': event.data.iframeSrc,
        'interactive': interaction.length !== 0 // Needs a better test since the 'choose your path' flashes aren't really that interactive
      }


      nextLink = $('font[size="5"] a')
      if (nextLink.length === 1) {
        message.nextLink = nextLink.attr('href').trim()
      }

      window.top.postMessage(message, '*')  // send a reply with some information about this page
    })
  }
  else {
    console.log("got a bad message:")
    console.log(event.data)
    return;
  }

}
