
// point the browser at the ReadHomestuck page
function openReadHomestuckPage() {
    chrome.tabs.create({
        url: "http://DomNomNom.com/BetterHomestuck/",
        active: true,
    });
}

// execute the above when the extension's icon is clicked
chrome.browserAction.onClicked.addListener(openReadHomestuckPage);

// execute on install (but not update)
chrome.runtime.onInstalled.addListener(function (details) {
    if (details.reason === "install") {
        openReadHomestuckPage();
    }
});
