
// point the browser at the BetterHomestuck page
function openBetterHomestuckPage() {
    chrome.tabs.create({
        url: "http://DomNomNom.com/BetterHomestuck/",
        active: true,
    });
}

// execute the above when the extension's icon is clicked
chrome.browserAction.onClicked.addListener(openBetterHomestuckPage);

// execute on install (but not update)
chrome.runtime.onInstalled.addListener(function (details) {
    if (details.reason === "install") {
        openBetterHomestuckPage();
    }
});
