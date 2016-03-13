

baseURL = 'http://mspaintadventures.com/';
baseURL2 = 'http://www.mspaintadventures.com/';

// point the browser at the BetterHomestuck page
// use the current page if we are on a Homestuck page
function openBetterHomestuckPage(tab) {
    if (tab.url.startsWith(baseURL) || tab.url.startsWith(baseURL2)) {
        // we are in a homestuck page
        // take us to the better version of it
        // TODO: sanitize tab.url or use something else to change the page but it looks like an unlikely/ineffective attack vector
        chrome.tabs.executeScript(
            tab.id,
            {
                code: 'window.location.href = "http://better-homestuck.appspot.com/#' + tab.url + '";'
            }
        );
    }
    else {
        // open a new tab with the default URL
        chrome.tabs.create({
            // url: "http://DomNomNom.com/BetterHomestuck/",
            url: 'http://better-homestuck.appspot.com/',
            active: true,
        });
    }
}

// execute the above when the extension's icon is clicked
chrome.browserAction.onClicked.addListener(openBetterHomestuckPage);

// execute on install (but not update)
chrome.runtime.onInstalled.addListener(function (details) {
    if (details.reason === "install") {
        openBetterHomestuckPage();
    }
});
