
---
title: Client-side image generation with SVG and XSLT
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: Explains how to generate images client-side from XML using SVG and XSLT.
#toc:
---

	



This article explains how to use client-side XSLT for image generation with SVG, and why you might want to. It assumes
some knowledge of XSLT and of SVG. 




## What are SVG and XSLT, and why use them for image generation?

SVG is Scalable Vector Graphics - an XML specification for graphics. XSLT is the Extensible Style Language: Transformations - a language for transforming XML into other forms. I'm not going to go into any detail on either of them here, but see the references at the bottom if you want to learn more. XSLT is well suited for automatically generating SVG graphics from XML content, and it's easy to get XML content from databases or other sources.


When XSLT is paired with SVG, it's normally used on the server-side to generate graphics that are sent down to a web-browser client. In this article, I present an alternative - using XSLT client-side to generate XSLT. So, what advantages does that have over server-side SVG generation?


- Image generation is traditionally a processor-intensive task - but generating images with client-side XSLT and SVG requires ***no server side processing time***.
- The server isn't having to send the images themselves at all - just the instructions on how to create them. Much of the time, this means that ***much less bandwith is used***, especially if similar images are displayed multiple times.
- Sending images to the browser normally requires that it make multiple connections to the server, one per image. Each connection has a significant overhead (although less if HTTP keep-alive is used). Using XSLT and SVG requires only two connections total - one for the XML, one for the XSLT, so the ***connection overhead is less***.




## How to do it



For client-side generated XSLT to work, you need to:



- Generate XHTML that uses namespaces to include SVG content.
- To work in IE, you must include the Adobe SVG plugin object.




This isn't particularly hard. Here is a very simple example:



This is the XML:
			
	<?xml-stylesheet type="text/xsl" href="simpleinline.xsl" alternate="no" ?>
	<root />

And this is the XSLT:

	
	<?xml version="1.0" ?>
	<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
		<xsl:template match="/">
		<html xmlns:svg="http://www.w3.org/2000/svg">     
	
		<object id="AdobeSVG"     
		   CLASSID="clsid:78156a80-c6a1-4bbf-8e6a-3cd390eeb4e2">
		</object>
		<xsl:processing-instruction name = "import" >
			namespace="svg" implementation="#AdobeSVG"
		</xsl:processing-instruction> 
		<head><title>SVG Example</title></head>     
		<body>
		<p>
		   Behold SVG mixed with XHTML.
		</p>
	
		<svg:svg width="100px" height="100px" viewBox="0 0 100 100">     
		<svg:circle cx="30" cy="30" r="20" 
			fill="blue" stroke="none"/>
		</svg:svg>
		<p>     
			Admire the blue circle of SVG power!
		</p>
		</body>
		</html>
		</xsl:template>
	
	</xsl:stylesheet>
			
	
This example works in both IE 6 with the Adobe plugin, and in an SVG build of Mozilla.
	
[See it working](/code/simpleinline.xml).




## So what's it doing?


The XSLT:
	
	<object id="AdobeSVG"     
	   CLASSID="clsid:78156a80-c6a1-4bbf-8e6a-3cd390eeb4e2">
	</object>
	<xsl:processing-instruction name = "import" >
		namespace="svg" implementation="#AdobeSVG"
	</xsl:processing-instruction> 
	
generates the HTML output:
	
	<object id="AdobeSVG"     
	   CLASSID="clsid:78156a80-c6a1-4bbf-8e6a-3cd390eeb4e2">
	</object>
	<?import namespace="svg" implementation="#AdobeSVG">
	
which references the Adobe SVG plugin control, and associates the svg namespace with it. The Adobe plugin will now be called to render all content in the svg namespace.

This isn't necessary for the SVG to work in Mozilla - Mozilla recognizes that the svg namespace is used for SVG from the declaration <html xmlns:svg="http://www.w3.org/2000/svg">.


The rest of it is simple SVG or HTML. The SVG:
	
	<svg:svg width="100px" height="100px" viewBox="0 0 100 100">     
	<svg:circle cx="30" cy="30" r="20" 
		fill="blue" stroke="none"/>
	</svg:svg>

just draws a blue circle, with radius 20px.


## Drawing graphs with XSLT and SVG

Drawing blue rectangles is not that useful. A better use for client-side image generation is drawing graphs based on XML data.
	
This example draws bar graphs plotting the weight and height of dinosaurs. The data file that generates the graphs is also used to generate HTML descriptions of the dinosaurs. 
	
It uses four files:

- [dinosaurs.xml](/code/dinosaurs/dinosaurs_no_xsl.xml): The dinosaur data . This references dinosaurgraphs.xsl as its stylesheet.
- [dinosaursgraphs.xsl](/code/dinosaurs/dinosaurgraphs.xsl): The stylesheet that includes the templates for the HTML and calls the graph templates.
- [dinosaurs.xsl](/code/dinosaurs/dinosaurs.xsl): A stylesheet for generating HTML from the dinosaurs.
- [graphtools.xsl](/code/dinosaurs/graphtools.xsl): A utility stylesheet containing graph drawing templates

One of the nice things here is that I wrote the dinosaurs.xml and the dinosaurs.xsl a month or so before the rest of the code (when I was writing *Practical XML for the Web* for Glasshaus), and then I was able to add the two new stylesheets to draw the graphs without having to change the original files. The only change I made was altering dinosaurs.xml to point to a different stylesheet.

The code in dinosaurgraphs.xsl that draws the graphs is:

		
	<xsl:template match="dinosaurs" mode="svgforweights">
	<xsl:param name="maxY">400</xsl:param>
	
	<svg:svg width="400px" height="400px" viewBox="0 0 {$maxX + 1 + $xOffset} {$maxY}">
		<!-- Stylesheets, and styles in general, don't seem to work with inline SVG -->
		<xsl:call-template name="graphStyles" />
		<svg:defs>
		<xsl:call-template name="graphFilters" />
		</svg:defs>
		<!-- Draw grid lines -->
		<xsl:call-template name="drawLines" >
		<xsl:with-param name="title" select="'Dinosaur weight'" />
		<xsl:with-param name="xAxisTitle" select="'Dinosaur'" />
		<xsl:with-param name="yAxisTitle" select="'Weight / tons'" />
		<xsl:with-param name="yOffset" select="$yOffset" />
		<xsl:with-param name="maxX" select="$maxX" />
		<xsl:with-param name="maxY" select="$maxY" />
		</xsl:call-template>
	
		<xsl:for-each select="dinosaur">
		<xsl:call-template name="drawBar">
			<xsl:with-param name="height_condition">
			<xsl:value-of select="number(weight/text())"/>
			</xsl:with-param>
			<xsl:with-param name="maxY" select="$maxY" />
			<xsl:with-param name="yOffset" select="$yOffset" />
		</xsl:call-template>
		</xsl:for-each>
	</svg:svg>
	</xsl:template>

This is calling two templates that are defined in graphtools.xsl. The first, "drawLines", draws the grid lines for the graph. Then, the for-each element steps through each of the dinosaurs defined in the data file, and calls "drawBar" for each of them, passing in a height for the bar based on the weight of the dinosaur.

This example only works in IE 6 with the Adobe SVG plugin. I'm not sure why it doesn't work in Mozilla - as far as I can tell, there's nothing illegal in the XSLT or the generated SVG. ***Update: This sort-of works with the latest SVG builds of Mozilla - it isn't laid out correctly, but it's almost there.***

[See it working](/code/dinosaurs/dinosaurs.xml).


## Where is client-side SVG/XSLT useful?

Well, not as a replacement for images or Flash on websites in general. IE 6 and Mozilla are the only browsers with decent XSLT support, the Adobe SVG plugin is used by less than 1% of browser users, and Mozilla only supports SVG in a branch, not in the main releases.
	    
However, this technique can be useful:


- On an intranet - where there is a standard browser rollout, with standard plugins.
- For web applications - particularly for displaying real-time information in graphs. If these graphs need to be redrawn frequently, then done server-side, they would put a heavy load on the server, but done client-side, they would cause almost no load.

Another benefit of SVG/XSLT is that the processing can be done on either the client-side or the server-side, as appropriate. Using a framework like Apache Cocoon, you can detect what browser versions are accessing your site, and either process the XSLT and SVG on the server to generate XHTML and PNGs, or send down the XML and XSLT to the client. This gives the benefit of reducing server load and bandwidth usage, while still keeping backward compatibility.


## References

There's useful information on the web about SVG at [XML.com](http://www.xml.com/search/index.ncsp?sp-q=svg&search=search), and at the [Protocol 7 SVG wiki](http://www.protocol7.com/svg-wiki/default.asp). For more information, I'd recommend [SVG Essentials](http://www.oreilly.com/catalog/svgess/) published by O'Reilly.

Cocoon is a Java-based server-side publishing framework, available from the [Apache XML project](http://xml.apache.org/cocoon/).

There's online information on XSLT at [XML.com](http://www.xml.com/search/index.ncsp?sp-q=xslt&search=search). The best general purpose book on it is Mike Kay's [XSLT Programmer's Reference](http://www.amazon.com/exec/obidos/tg/detail/-/1861005067) from Wrox Press. If you're interested in client-side XSLT, then I recommend [Practical XML for the Web](http://www.amazon.com/exec/obidos/tg/detail/-/1904151086) from Glasshaus Press, in which I wrote two chapters about it. 

