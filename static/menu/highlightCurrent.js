
function getLeaf(url) {
  return url.substring(url.lastIndexOf("/")+1);
}

function highlightCurrentMenuItem() {
  var currentLocation = getLeaf(document.location.href);
  var menu = document.getElementById("mainmenu");
  links = menu.getElementsByTagName("a");

  for (i=0; i<links.length; i++) {
    var currentHref = links[i].getAttribute("href");
    var currentLeafName = getLeaf(currentHref);
    if (currentLeafName==currentLocation) { 
      // Setting class is needed for Mozilla compatibility - className appears to be correct 
      // according to the DOM spec
      links[i].setAttribute("class", "current");
      links[i].setAttribute("className", "current");

      // More obvious to use parentNode.parentNode.firstChild, but this
      // may give a whitespace text node.
      var menuHeader = links[i].parentNode.parentNode.getElementsByTagName("div").item(0);
      menuHeader.setAttribute("class", "current");
      menuHeader.setAttribute("className", "current");
    }
  }
}

