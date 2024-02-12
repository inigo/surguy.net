
---
title: Rediscovering JavaScript (2006)
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: Why JavaScript is fun
#toc:
---


## Abstract

This article is about JavaScript – probably the most disliked and misunderstood major
programming language, yet also probably the most widespread, and which can be one of
the more enjoyable languages to use.


First I’ll describe some general features of JavaScript and the tools and libraries I
use for writing it. Then, I’ll examine in detail the development of a JavaScript
utility for sorting tables, showing how those features, tools and libraries can be
used in practice. Finally, I’ll list some of the new developments in JavaScript.


By the end of the article, I hope you’ll have an idea of some of the ways that
JavaScript can be useful, some techniques to make it easy to develop and debug, and
that it can be fun to develop in.


## Audience

This article is primarily intended for developers who are, or will be, using
JavaScript, but may not have been keeping track of all the changes to the language
and libraries in the last few years. It assumes a basic knowledge of HTML and CSS,
and some programming experience, and is slanted towards Java developers (but doesn’t
require any Java knowledge).


## Developing in JavaScript

### Language features

I find developing in JavaScript a lot more fun than writing in most languages – it’s
more like writing Python than it is like Java or C#. Partly this is because it’s a
very interactive language that encourages writing code directly into an interpreter,
and partly because it has powerful features that let you get a lot done with very
little duplicated or “boilerplate” code.


As a language, JavaScript is more sophisticated than most people give it credit for.
Like Java, it has object-orientation, garbage collection, exception handling, and
regular expression support. However, it also has powerful features that are not
available in Java, such as support for functions as first-class objects, higher
order functions, closures, continuations, and direct support for creating and
querying XML. I’ll be giving examples of how most of these features work later in
this article. 


### Development environment

There don’t seem to be any very good integrated JavaScript development environments,
certainly not of the quality of modern Java environments. The most promising is
IntelliJ IDEA, which supports code-completion, some refactorings, and via the
Inspection-JS plugin has FindBugs-style static inspections for common JavaScript
bugs. The others I’ve looked at do little more than syntax highlighting.


Instead, I use a combination of a text-editor (Vim, in my case), and some Firefox
tools. 


Absolutely essential is the “shell” bookmarklet from the “Jesse’s Bookmarklet” site
(see references), which opens up an interactive JavaScript shell with a context that
is the current page. You can type in code that directly manipulates the current
page, use Tab to autocomplete names and see what methods are available on an object,
inspect variables, and test out code interactively. When I’m writing code, I do it
interactively in the shell first, then copy it to a script file once I’m happy that
it works correctly; the immediate feedback this gives makes me much more productive.
(Jesse’s “Edit Styles” bookmarklet is also very useful, and does the same thing for
CSS).


I’ve also recently started using “Firebug”, which is a Firefox plugin for JavaScript
debugging. It shows the JavaScript errors on a page and will record XML
conversations send from JavaScript via the XMLHttpRequest object. It also provides a
shortcut to the DOM Inspector (built in to Firefox) which is useful for
disentangling complicated web pages and working out where each page element comes
from.


There is a free JavaScript debugger for Mozilla – Venkman – which is fairly good, but
heavy and clunky to use. VS.NET also has a JScript debugger which has the same
problems. In practice I don’t use either often; I generally find that keeping code
simple and putting in log messages is more effective than using a debugger.


### Logging

The traditional way of doing logging in JavaScript is to sprinkle “alert(‘Some
value’)” calls through the code, and then comment them out before the code is used
in production. This is not a good idea. It’s a hassle to enable and disable the
logging, hard to find relevant log messages, and easy to accidentally lock up the
browser by calling alert 1000 times in succession. It’s even worse than using
System.out.println for logging in Java.


A much better approach is to use a logging library. I’ve tried a number of them, and
the best one I’ve used so far is “log4javascript”. This works in a similar way to
Log4J in Java – you log messages at “debug”, “info”, “error”, etc. levels, and
configure one or more appenders to display these messages – typically to a pop-up
window, but also to an in-window frame, or even to a web service on the server
(which is useful to catch infrequent errors in production systems). The logging
calls can be left in the code, just with the logger disabled, and the log messages
can easily be filtered by log level and by their text.


### The “Prototype” library

JavaScript uses prototype-based object-orientation. This means that it’s possible to
add functions to any object (including the built-in ones such as Array and String)
by using that object’s “prototype”. For example:

        String.prototype.startsWith = function(s) { return this.indexOf(s)==0; }

defines a <i>startsWith</i> function to all strings. So:

        “JavaScript”.startsWith(“Java”)

is now possible, and will return true. Using this approach can often make code more
readable, and encapsulates the functions that apply to an object within that object.


The “Prototype” JavaScript library takes its name from this capability, and uses it
to add convenient functions to many built-in objects, such as a <i>stripTags</i>
method that removes HTML tags from a String, and an <i>each</i> method that applies
a function to each item in an array. It also adds functions for getting values from
forms, making Ajax requests, and manipulating the DOM.


It adds about 50kb to the download size for a page – but most of the time, that’s not
very important. We’re building web applications, not websites; with the right
cache-control HTTP headers set up on the web server, the script will only be
downloaded once, and with GZIP compression the size shrinks to 10-20kb.


For this article, I’m using the latest v1.5 Prototype from the Subversion trunk,
rather than the v1.4 which is the version available from the Prototype web site.


### Unobtrusive JavaScript – attaching behaviour through script

“Unobtrusive’ JavaScript is the idea that:

- JavaScript should enhance the user experience, rather than providing essential functionality – and fallback gracefully if JS isn’t available.

- JavaScript shouldn’t be directly inside HTML – so no adding <i>onclick</i> and
  <i>onsubmit</i> attributes to HTML. Instead, it should be in separate JS
  files, and using semantic markup such as IDs and classes to add event handlers
  to the HTML dynamically. This makes it more reusable, and simplifies the
  HTML.


## Applying these ideas – making a table sortable

The simplest way to explain JavaScript’s features is to demonstrate them. I’ve
written a JavaScript library that makes tables sortable, by clicking on the column
headers, and I’ll go through the code and explain how it works and how it evolved.
Unobtrusive sortable tables aren’t an original idea (the first implementation I know
of was by Stuart Langridge at Kryogenix), but it’s useful code and easy to explain.

The full code is available from my website at:

https://surguy.net/code/tableSort.js

and a working version can be seen in action at:

https://surguy.net/code/table.html

(because I’ve left the logging enabled, you’ll have to allow popups on that page for
it to work)


### Adding behaviour to the table headers

The first task is add an <i>onclick</i> event handler to each of the table column
headers. If we weren’t using unobtrusive JavaScript, then this would be done by
directly adding an <i>onclick='sort(this)'</i> attribute to each header cell in the
HTML, but it’s just as easy, and a lot more maintainable, to do it in code:


    var log = log4javascript.getDefaultLogger();

    function init() {
      log.debug("Looking for tables to make sortable");
      $$("table.sortable thead td").each( function(cell) { 
        log.info( "Making column header '"+getText(cell)+"' sortable"); 
  
        cell.innerHTML="&lt;span onclick='sort(this)'&gt;"+cell.innerHTML+"&lt;/span&gt;";
       } );
    }

    Event.observe(window, 'load', init, false);

This uses several features of the Prototype library. The `$$` function returns a
list of elements that are matched by a CSS expression – here, it is returning a list
of table cells (“td”) that are inside the table header (“thead”) of a table that has
the CSS class “sortable” (“table.sortable”).


This list of elements is an HTMLCollection DOM object. Prototype adds an `each`
method to this object, which iterates through every value in the collection,
applying a passed-in function to each. Here, it is being used to add a “span”
element around the contents of each table header cell. I’m defining an anonymous
function to do this. JavaScript allows functions to be defined inline, similarly to
anonymous inner classes in Java.


`Event.observe` is also from Prototype – it’s registering the `init`
function to be called when the window `load` event is triggered (and it
abstracts the differences between the event models in the different browsers). This
is necessary because the JavaScript is processed before the web page is fully loaded
– if there was a direct call to `init` rather than registering it as a
callback, it wouldn’t work because the page it’s trying to manipulate doesn’t yet
exist.


The code is also getting hold of a `log` object, and using it to log events at
“info” and “debug” level. The default logger will display these messages in a pop-up
window.


### Getting the column to be sorted

When a column header is clicked on, it will call the `sort` function, and pass
in the span of text that was clicked. `sort` needs to get a reference to the
table, and the rows to be sorted, and find the values within it to be sorted. Then
it needs to work out how to sort them and finally do the sorting. 


    function sort(span) {
     log.info("Sorting table column '"+getText(span)+"'");
     var table = getAncestor(span, "table");

`getAncestor` is a function I’ve written that gets the ancestor of the current
element with the specified name – in this case, the “table” element that the
clicked-on span of text is inside.


     var rows = $A(table.rows);
     var bodyRows = rows.without(rows.first());
     log.debug("There are "+bodyRows.length+" rows to be sorted");

I’m assuming that the table has a single header row, and everything apart from that
should be sorted – and putting all of the rows to be sorted in the `bodyRows`
variable.


`$A` is a Prototype function for converting a list of items (in this case, a DOM
HTMLCollection of the rows in the table) into a proper JavaScript array, which makes
it easier to manipulate. The `without` function is an array method that returns
all the members of the array except for the one specified – in this case it will
make a list `bodyRows` that contains all but the first item in the table’s list
of rows. 


Within the body rows, the values that will be used as the keys to sort the table are
the text of each cell that’s in the same column as the header cell:

     var position = getAncestor(span, "td").cellIndex;
     var getCellText = function(row) { return getText($A(row.getElementsByTagName("td"))[position]); }

JavaScript functions are first-class objects – which means that they can be assigned
to variables, passed around, returned from functions, and so on. Here, the function
for getting the text of a row in a given column is being assigned to the
`getCellText` variable. This can now be passed to other functions which
take a function as an argument.


It’s useful for debugging to print out the current values in the column before
sorting it:


     var columnValues = bodyRows.map(getCellText);
     log.debug("Current column values order is "+columnValues);

This is using the Prototype array method `map`, which applies a function to each
value within an array, and returns a new array containing the results of that
function. 


### Evolution of a comparison function

The JavaScript `Array.sort` function takes an argument which is a function,
which it calls for each pair of objects to be sorted to determine the order that
they should be placed in, and is expected to return -1, 0, or 1, to signify which
object is greater or that they are equal. This is very similar to the Java
`Collections.sort` method, which takes an object that implements the
`Comparator` interface.


This section shows how this comparison function was incrementally improved from a
very simple implementation to one that handles numbers, text and dates. The code
within it (or at least, the final version of the code) is still within the
`sort` function defined above.


The simplest form of this comparison function is one that uses the built in
greater-than, equal-to and less-than operators:


    function simpleCompare(a,b) {
     if (a &lt; b) { return -1; }
     if (a==b) { return 0; }
     return 1;
    }

This is defining `simpleCompare` as a separate function, that can be called from
anywhere within the current JavaScript file or any other. It’s a good idea to limit
the scope of functions and variables so that they’re only accessible where they’re
actually used – the closest equivalent in Java is making them private members. In
JavaScript, you can do this by assigning the function to a variable, rather than
using a global function definition:


    var simpleCompare = function(a,b) {
     if (a &lt; b) { return -1; }
     if (a==b) { return 0; }
     return 1;
    }

I can make this terser by using the ternary operator, which is the same in JavaScript
as it is in Java i.e. `(predicate)` ? `ifTrue` : `ifFalse`. Because
this definition will be repeated a lot in the rest of this section, I’ll use the
condensed form even though it is less readable:


    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };

This does a simple ASCII-based comparison – so ‘A’ comes before ‘Z’, but ‘Z’ comes
before ‘a’. To make it case-insensitive, which is usually correct for text, then
I’ll lower-case both arguments before the comparison.

    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };
    var textCompare = function(a,b) { 
      return a.toLowerCase() &lt; b.toLowerCase() ? -1 : a.toLowerCase() == b.toLowerCase() ? 0 : 1; 
    };

This is duplicating logic; it would be better for the `textCompare` function to
do the lower-casing and then call on to the `simpleCompare` function:

    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };
    var textCompare = function(a,b) { return simpleCompare(a.toLowerCase(), b.toLowerCase()); };

This is still duplicating logic, though – the `toLowerCase` call shouldn’t be
written out twice. It’s not important in this case, but with a more complicated
compare function, it could lead to problems and the two calls getting out of step.
There should be two orthogonal functions – one of which does the lower-casing, and
one of which does the comparison. This would remove the duplication, and also allows
the individual functions to be reused in more places since they have a single, clear
purpose.

In Java, this would be an implementation of the Strategy pattern, but in more
functional languages like LISP and JavaScript, there’s more direct language support
for most of the GOF patterns. JavaScript supports higher-order functions – i.e.
functions that return functions – and this is an ideal use for them:

    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };
    var compareComposer = function(normalizeFn) { 
      return function(a,b) {
        return simpleCompare(normalizeFn(a), normalizeFn(b) ) 
      }; 
    }
    var textCompare = compareComposer(function(a) { return a.toLowerCase(); });
    var nonInternetExplorerTextCompare = compareComposer(String.toLowerCase);

`compareComposer` is a function that takes a normalizing function as an
argument, and returns a function that will apply that normalization to both of its
arguments, and then call on to the `simpleCompare` function.

Initially I wrote the function `nonInternetExplorerTextCompare` above – which
references the `String.toLowerCase` function rather than creating its own
function. When I tested in IE, this didn’t work – IE doesn’t have an explicit
`String` object with its functions directly referenceable, so instead I had
to write an anonymous wrapper for it (`textCompare` above).

So far, this will sort text alphabetically, but it should also sort numerically and
by date. Table columns that are to be sorted numerically may still contain text, for
example “Time 23 min.” should have the “23” extracted and used to sort by.
JavaScript supports regular expressions, which is the easiest way to get the numeric
part, and then it can be converted to a number to be compared:


    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };


    var compareComposer = function(normalizeFn) { 
      return function(a,b) {
        return simpleCompare(normalizeFn(a), normalizeFn(b) ) 
      }; 
    }

    var textCompare = compareComposer(function(a) { return a.toLowerCase(); });
    var numericCompare = compareComposer(function(a) { return parseInt(a.replace(/^.*?(\d+).*$/,"$1")) });
    var shortDateCompare = compareComposer(function(a) { 
      return Date.parse(a.replace(/^(\d+)\s*(\w+)\s*(\d+:\d+)$/,"$1 $2 2000 $3")); 
    })


The regex `a.replace(/^.*?(\d+).*$/,"$1"))` extracts the first numeric part of a
string. The `shortDateCompare` regex turns a date in the form “13 MAR 13:42”
into an ISO date format that can be understood by the standard JavaScript
`Date.parse` function.


So far, there’s no way to decide which compare function should be used for a
particular table column. The most straightforward way to do this is by using a CSS
class attached to the column header to determine what type of data it stores, and
then using that to look up the compare function in a hashtable. Since JavaScript
functions are first-class objects, they can be stored as values in a hashtable just
like any other object.


    var simpleCompare = function(a,b) { return a &lt; b ? -1 : a == b ? 0 : 1; };
    var compareComposer = function(normalizeFn) { return function(a,b) {
      return simpleCompare(normalizeFn(a), normalizeFn(b) ) }; }

    var compareFunctions = {
     "caseSensitive" : simpleCompare ,
     "text" : compareComposer(function(a) { return a.toLowerCase(); }) ,
     "numeric" : compareComposer(function(a) { return parseInt(a.replace(/^.*?(\d+).*$/,"$1")) }) ,
     "shortDate" : compareComposer(function(a) { return Date.parse(a.replace(/^(\d+)\s*(\w+)\s*(\d+:\d+)$/,"$1 $2 2000 $3")); })
    }

    var className = getAncestor(span, "td").className;
    log.debug("Cell's CSS class is "+className);

    var comparefn = (compareFunctions[className]!=null) ? compareFunctions[className] : compareFunctions["text"] ;


The `span` variable is the span within the table header cell that’s been clicked
on, as defined earlier in the function.

So, the code above will set the variable `comparefn` to be a comparison function
that is appropriate for the table column that’s been clicked on.


### Sorting the column

The final task is to use the comparison function to sort the table, and update the
HTML page accordingly. The column should swap between ascending and descending order
by clicking on the column header again.


    var order = (span.className=="ascending") ? 1 : -1;
    span.className= (order==-1) ? "ascending" : "descending";
    bodyRows.sort(function(rowA, rowB) { return order * comparefn( getCellText(rowA), getCellText(rowB) ); });
    bodyRows.each(function(row) { table.tBodies[0].appendChild(row); })
    log.debug("Table sorted");

The code above uses the `class` attribute of the span to determine whether the
column is already sorted in ascending or descending order, and then swap that value.
The comparison function will be returning 1, 0, or -1, as described above.
Multiplying the result of that comparison by 1 or -1 will invert it – so the sort
order can be reversed if necessary.

JavaScript functions are closures – they have references to all the variables within
the scope that they were defined in. In this case, this means that the anonymous
function that is being passed to `bodyRows.sort` has access to the `order`
and `comparefn` variables that were defined above. Even if the function is
passed out of its original scope, then it still has access to these variables – this
can be very useful.

The `sort` function on `bodyRows` sorts it in place. Then, for each row, it
needs to be put into the table in the appropriate order – which is done using the
DOM method `appendChild`. Conveniently, the DOM only allows a node to exist in
one place – so by adding the node to a new location in the table, it’s automatically
removed from its original position without having to do so explicitly.


### Browser incompatibilities

For years, the biggest problem with client-side JavaScript was the different levels
of support it had in different browsers; Netscape 4 was the worst offender.
Nowadays, the situation isn’t nearly so bad: modern browsers only vary slightly in
their JavaScript implementations; libraries like Prototype cover up most of the
differences anyway; and the “unobtrusive JavaScript” style means that it’s
acceptable for the JavaScript not to run on old browsers because no vital behaviour
depends on it.

I originally wrote and tested this code in Firefox. This is usually the best approach – 
Firefox is easier to develop in than IE, and if the code works in Firefox it’s
likely to work in other modern browsers with few or no changes. 

When the script was complete, I tested it in IE 6. It didn’t work. However, the debug
logging output showed where it was going wrong, and why. I just had to fix the
`getText` function to use IE’s `innerText` property as well as the DOM
standard `textContent`, and change the `textCompare` function as described
above. This made it work in IE 6 and IE 5.5. It still doesn’t work in IE 5 (and nor
does the Prototype library).


I also tested in Safari, which didn’t show any errors, but didn’t sort the columns
correctly. Again, the logging showed what was wrong: a bug in Safari means that it
always returns 0 for the `cellIndex` property, so it was always sorting the
first column not the clicked-on column. The solution was to write a function to work
out which column the cell is in, rather than using the `cellIndex` DOM
property:

    function getCellIndex(td) { return $A(td.parentNode.cells).indexOf(td) }

Using a proper logger saved a lot of time here: it allowed me to see immediately
where things were going wrong. Without the logging, I’d have had to spend some time
peppering my code with alert messages (and removing them afterwards), or stepping
through in a debugger. 


### Unit testing

I wrote unit tests for the code in JSUnit - a port of JUnit to JavaScript that uses
the same approach of testX functions, assertions, a test harness, and green and red
bars. The main advantage of JSUnit is that it can be automated via Ant to run tests
against multiple browsers and aggregate their results – it can even be set-up to run
browsers on separate servers, such as Safari on a Mac or Konqueror on a Linux
server, and collect the test results in one place. Using JSUnit, JavaScript testing
can be integrated as part of a standard continuous build process.


## Other fun things to do with JavaScript

### Ajax

Ajax is “Asynchronous Javascript and XML” – a technique for updating parts of web
pages dynamically by making background requests to web services. It’s become very
popular recently, since Google started using it in GMail, but it has been around for
years. It can be used to make a much richer, more usable, more interactive interface
than a static web page allows.


Ajax requires work on both the client-side and the server-side to implement – the
server-side needs to provide a web-services interface that the client-side
JavaScript can consume. It works best if the server-side has been written using a
Service-Oriented Architecture approach.


Canonical examples of the use of Ajax are in GMail, where it’s used for saving drafts
of emails, sending mail attachments to be virus-checked by a server-side process,
and checking for new mail; and Google Maps, in which map tiles are incrementally
loaded as the user moves around the map.


### Mustang and Rhino – Java 6

The difference between Java and JavaScript has always confused a lot of people. Later
this year, it will become more confusing – because the Java 6 “Mustang” release
makes a JavaScript implementation part of the standard JDK (as part of JSR-223).
It’s using Rhino, which is an Open Source JavaScript implementation written in Java.
In a similar way to the .NET platform’s support for multiple languages, you can call
Java classes from within JavaScript, and vice-versa. 


A particularly interesting feature of Rhino is its support for continuations.
Continuations have been supported in languages like Scheme and Smalltalk for years,
but are now becoming more mainstream – C# and Python have limited continuation
support via the `yield` keyword, and Ruby has the `callcc` keyword.
Continuations let you save the current state of a function, and come back to it
later. In Rhino (used via Cocoon’s FlowScript), this lets you “save” the current
state of a function used to generate a web form, and “resume” it when the user
submits that form, for example. This means that the developer doesn’t have to do any
explicit management of state, and that it automatically handles users navigating via
multiple browser frames and using the back button.


### E4X – direct language support for XML

Rhino and Firefox 1.5 support E4X, an ECMA standard for embedding XML directly within
JavaScript (similar to Microsoft’s forthcoming XLINQ in VB.NET 9.0). With E4X, you
can create and query XML documents inline:

    var myXML = <someXML>
       <p class=”animal”>kitten</p>
       <p class=”mineral”>rock</p>
       <p class=”animal”>cow</p>
     </someXML>;
    var animals = myXML.p.(@class=”animal”);

E4X makes XML manipulation much simpler than in most other languages – vastly easier
than manipulating DOM objects.


### Greasemonkey – JavaScript browser plugins for Firefox

Greasemonkey is an extension for Firefox that lets you write JavaScript that is
automatically applied to web pages that you specify. For example, you can use it to
rewrite pages to make them more accessible, change Amazon affiliate links to support
a charity of your choice, or hide posts by specific forum users. 


## Conclusions



- JavaScript should be “unobtrusive” – and using a good framework such as Prototype is the easiest way of making it so.
- JavaScript is a dynamic, interpreted language – so develop it interactively using a JavaScript shell, rather than treating it as a static, compiled, Java-like language.
- JavaScript functions are first-class objects – so you can pass them around, store them in a hashtable, assign them to variables, etc.


- JavaScript supports higher-order functions – that is, functions that return
functions – and using them lets you write small, simple, orthogonal functions
and then compose them into a larger whole.


- JavaScript functions are closures – they can always refer to variables that were
available within the scope in which they were defined, even if they’re being
called from outside that scope.


- It’s possible to add functions to any object, including the built-in ones such
as Array and String, and doing so often makes code more readable.


- A good logging framework is essential for debugging – and allows you to develop
for Firefox first and then easily see what’s broken when you switch to IE.


- With Ajax to call web services and Java 6 including Rhino, JavaScript is
becoming even more relevant to server-side Java developers.




## References


<i>JS Shell</i>; Jesse Ruderman; <a href="http://www.squarefree.com/bookmarklets/webdevel.html" title="">http://www.squarefree.com/bookmarklets/webdevel.html</a>

<i>Firebug</i>; Joe Hewitt; <a href="http://www.joehewitt.com/software/firebug/" title="">http://www.joehewitt.com/software/firebug/</a>

<i>log4javascript</i>; Tim Down; <a href="http://www.timdown.co.uk/log4javascript/" title="">http://www.timdown.co.uk/log4javascript/</a>

<i>Prototype</i>; Sam Stephenson; <a href="http://prototype.conio.net/" title="">http://prototype.conio.net/</a>

<i>sorttable</i>; Stuart Langridge; <a href="http://www.kryogenix.org/code/browser/sorttable/" title="">http://www.kryogenix.org/code/browser/sorttable/</a>

Old versions of Internet Explorer; <a href="http://browsers.evolt.org/?ie/32bit/standalone" title="">http://browsers.evolt.org/?ie/32bit/standalone</a>

<i>JSUnit</i>; Edward Hieatt; <a href="http://www.edwardh.com/jsunit/" title="">http://www.edwardh.com/jsunit/</a>

## Recommended reading

<i>A (Re)-introduction to JavaScript</i>; Simon Willison; <a href="http://simon.incutio.com/slides/2006/etech/javascript/js-tutorial.001.html" title="">http://simon.incutio.com/slides/2006/etech/javascript/js-tutorial.001.html</a>;
a long presentation covering JavaScript’s history and features – including much more
detailed coverage of object-orientation and closures than I have in this article.


<i>Continuations for Curmudgeons</i>; Sam Ruby; <a href="http://www.intertwingly.net/blog/2005/04/13/Continuations-for-Curmudgeons" rel="">http://www.intertwingly.net/blog/2005/04/13/Continuations-for-Curmudgeons</a>; a
(fairly) simple explanation of continuations.


<i>Places to use Ajax</i>; Multiple authors; <a href="http://swik.net/Ajax/Places+To+Use+Ajax" title="">http://swik.net/Ajax/Places+To+Use+Ajax</a>; a wiki page listing some areas
where Ajax can be useful.


<i>Prototype Dissected</i>; Jonathan Snook; <a href="http://www.snook.ca/archives/000531.php" title="">http://www.snook.ca/archives/000531.php</a>; a reference poster of all the
methods introduced by Prototype.


<i>Painless JavaScript using Prototype</i>; Dan Webb; <a href="http://www.sitepoint.com/article/painless-javascript-prototype" title="">http://www.sitepoint.com/article/painless-javascript-prototype</a>; an article
describing some of the methods in Prototype, including form manipulation and Ajax.


## About this document

This article is licensed under a Creative Commons Attribution-NonCommercial-NoDerivs 2.5 license
(<a href="http://creativecommons.org/licenses/by-nc-nd/2.5/">http://creativecommons.org/licenses/by-nc-nd/2.5/</a>)

