
---
title: Technical review of OOXML
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: Notes and code from the UK's BSI technical review of OOXML (Open Office XML, Ecma 376, DIS 29500) for ISO.
#toc:
---




## About OOXML (Open Office XML)

Microsoft's XML file format for Office 2007 has been standardized by Ecma as Ecma 376. It's now being
reviewed by ISO as part of the fast-track process to becoming an ISO standard. My interest is that I'm
on the IST/41/-/1 expert group (chaired by [Alex Brown](http://www.adjb.net/index.php))
that is scrutinising it for the BSI, to inform the UK's response to the ISO ballot. This is happening on
a [public (read-only) wiki](http://www.xmlopen.org/ooxml-wiki/index.php/DIS_29500_Comments).
I'm primarily looking at WordProcessingML, which is about 1800 pages of the nearly 6000 page specification.



## Validation of schema examples


There are approximately 2300 XML examples in the WordProcessingML section. It's clearly not feasible for
the (volunteer) BSI committee to check all of them manually, so I've written some code to automatically
extract the examples from the OOXML source, check them for well-formedness, and for validation errors.
The results are below.


- [Excel spreadsheet of WordProcessingML example errors](http://surguy.net/ooxml/OOXML-WordProcessing-example-errors.xls)
- [Tab-separated text of WordProcessingML example errors](http://surguy.net/ooxml/OOXML-WordProcessing-example-errors.txt)



Approximately 300 of the examples are in error - more than 10%. While a certain number of errors is 
understandable in any large specification, the sheer volume of errors indicates that the specification 
has not been through a rigorous technical review before becoming an Ecma standard, and therefore may not
be suitable for the fast-track process to becoming an ISO standard. The counter-argument is that they're
all relatively simple errors to fix; but it's not the complexity of the errors that worries me, just their
sheer volume.



I haven't yet run the code against the other sections of the specification 
(SpreadsheetML etc.) and because it requires some schema manipulation, it's not a completely
trivial task to do so.


The [Java and XSLT code for validation of examples](http://surguy.net/ooxml/ooxml.zip) is
available and can be modified and distributed under the terms of the GNU General Public License. In particular,
I'd be very happy if reviewers from other ISO national bodies use and improve the code.



*Update and clarification*: I've seen blog posts, and references in email, to this validation
report, claiming that some of the errors should not be counted because it's a legitimate editorial choice to elide attributes and 
elements for additional readability. Actually, I attempted to account for elision (with assistance from my fellow 
committee member Martin Bryan), by removing all the examples from the list that failed 
to validate due to missing content but had ellipses present. I left in those examples that omitted content but didn't signal 
this with ellipses, since I believe those to be confusing (that the majority of examples that omit content do use ellipses seems 
to indicate that the editors of the spec agree with me).



## Other notes - OOXML extensibility and Word 2007


Part 5 of the specification deals with extensibility - how the XML format can evolve without breaking all
existing applications. It defines "Ignorable", "PreserveElements" and "PreserveAttributes" elements that
tell the consuming application how to deal with elements and attributes that it doesn't understand. I'm not
reviewing this section in detail, but a preliminary reading seems to show that it's well thought out and 
sensible.



Unfortunately, Word 2007 doesn't appear to implement this part of the spec - it does ignore elements and attributes
if you tell it to, but it silently deletes them rather than preserving them. I saw this mentioned in 
[a blog
entry on the ODF Converter blog](http://odf-converter.sourceforge.net/blog/index.php?2006/12/07/16-open-xml-and-extensibility), and I've confirmed it with my own tests. This doesn't have any
bearing on whether DIS 29500 should become an ISO standard, but it does mean that Word isn't fully in
compliance with the Ecma 376 standard. It also means that it would be harder to write an interoperable
word processor with Word; a word processor could produce fully conformant OOXML, interspersed with 
its own specific functionality (see the ODF Converter blog entry for an excellent example), but as soon as this
OOXML document was opened in Word, then Word would silently strip out the other word processor's markup.


