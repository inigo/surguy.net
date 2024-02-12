
---
title: Generating webpage images dynamically from XML
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: Shows how images can be generated from XML by extending XSLT with simple Jython scripts.
#toc:
---

	
	
	
		
One of the promises of XML was that it would make generating appropriately styled webpages from changing content simple.
		
For the most part, XSLT fulfills that promise, but it falls down in one crucial area - image generation.
		
Despite the advantages of text, many page designs require images to be used for headings and menus, so they can be independent of the installed client-side fonts, and have graphical effects applied to them.
		
I will show how images can be generated from XML by extending  XSLT with simple Jython scripts.


## Embedding script in XSLT with BSF

BSF, the [Bean Scripting Framework](http://oss.software.ibm.com/developerworks/projects/bsf), allows scripts in several languages ([ECMAScript](http://www.mozilla.org/rhino/), [TCL](http://tcl.activestate.com/software/tcltk/) and others) to be executed via a common framework. I have found it easiest to use with [Jython](http://www.jython.org/) because it is both powerful and syntactically clear.
		
The [Apache XSL processor Xalan](http://xml.apache.org/xalan-j/) has an extension framework that allows it to execute BSF code embedded in a tag in a stylesheet. Other XSLT processors have similar frameworks, but I only have first-hand experience of Xalan's.
		
This is an example of embedded code taken from the [Xalan website](http://xml.apache.org/xalan-j/extensions.html).
		
The code defines an XSLT extension function, getdate which can be used from within an `<xslt:value-of ... >` statement, and an XSLT extension element, timelapse which can access the document object model around it, in particular its own attributes.
            
        
    <xsl:stylesheet 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
        version="1.0"   
        xmlns:lxslt="http://xml.apache.org/xslt"
        xmlns:my-ext="ext1"
        extension-element-prefixes="my-ext">
    
    <lxslt:component prefix="my-ext" elements="timelapse" functions="getdate">
    <lxslt:script lang="javascript">
    var multiplier=1;
          // The methods or functions that implement extension elements always take 2
          // arguments. The first argument is the XSL Processor context; the second 
          // argument is the element node.
          function timelapse(xslProcessorContext, elem)
          {
            multiplier=parseInt(elem.getAttribute("multiplier"));
            // The element return value is placed in the result tree.
            // If you do not want a return value, return null.
            return null;
          }
          function getdate(numdays)
          {
            var d = new Date();
            var totalDays = parseInt(numdays) * multiplier;
            d.setDate(d.getDate() + totalDays);
            return d.toLocaleString();
          }
        </lxslt:script>
    </lxslt:component>
    
    <xsl:template match="deadline">
    <p><my-ext:timelapse multiplier="2"/>We have logged your enquiry and will 
          respond by <xsl:value-of select="my-ext:getdate(string(@numdays))"/>.</p>
    </xsl:template>
    
    </xsl:stylesheet>

		
The functions are using ECMAScript (via Rhino) to return appropriate information. Note the declaration of namespaces in the xsl:stylesheet element.
		
This is not a tutorial on extending Xalan with BSF - see the [Xalan website](http://xml.apache.org/xalan-j/extensions.html) for more information on the above code.
		
A Jython-specific problem with XSLT is that Jython uses indentation to delimit classes, methods, and other block level elements, rather than the more traditional brackets. With XSLT it's not easy to get all the whitespace in the right places and to have a readable XSLT file. A useful trick is to start the Jython block with an if statement that will always be true; thus: 
		
    <namespace:script lang="Jython">
    # Jython code must begin at the left margin
    if 1=1:
                    # code goes here, indented
                    # to match XSLT indentation
    </namespace:script>



## Using Java 2D from Jython

Java 2D supplies all the necessary classes to generate sophisticated images programmatically. Its flaw is that it can be overcomplicated to perform simple tasks - which is why I've wrapped it in higher level Jython classes.
		
In order to write out the images in some form that a web browser can understand, a codec is necessary. I'm using the PNG codec written by Walter Brameld (bugar@bigfoot.com) and available at his website [http://users.boone.net/wbrameld/pngencoder/](http://users.boone.net/wbrameld/pngencoder/). There are plenty of other codecs that will write JPEG and PNG files (and JDK 1.4 comes with an Image IO library); I'm using his because it's well documented and available under the LGPL.
		
I've kept the majority of the code in Jython, which is put directly into the XSLT stylesheet (it should be possible to include it from another file, but I haven't yet worked out what path Jython expects). The non-Jython code is the PNG codec and a simple class, JLayer that uses it to save and load images.
		
The code which actually generates the images is:

<code><pre>	
*# This is a function called from XSLT*
def doCreateImage(title):
  *# Create a new font style*
  f1 = PFont("Arial", 20)
  *# Set the font color to be red*
  f1.setColor(Color.red)
  *# Create a new fill style - a vertical gradient between green and yellow*
  vPaint = PVGradientPaint(Color.green, Color.yellow)
  *# Create a layer of width 120 and height 30 pixels*
  l = PLayer(120,30)
  *# Apply the fill style to the layer*
  l.fill(vPaint)
  *# Set the font on the layer*
  l.setFont(f1)
  *# Draw the text with the passed in title at position 10, 20*
  l.shadowText( title, 10, 20 )
  *# Save the image and set "filePath" to the path of the saved image*
  filePath = l.saveImage()
  *# Get the filename - the text after the last \ or /*
  fileName = filePath[max(("/"+filePath).rindex("/"), ("/"+filePath).rindex("\\")):]
  *# And return the filename to the calling XSLT*
  return fileName
</pre></code>
		
For the text "graphics", this creates the image

![(Generated image of text 'graphics')](/images/graphics.png)

which may have a few problems from a graphic design point of view, but is a generated image from XSLT.
	

## Download the code


[Download the code](/code/images-from-jython.zip).


## Testing this with Cocoon

For Cocoon, the only problem that I had was putting my classes to be included from Jython somewhere that Xalan could find them. In the end, I resorted to putting them in my {JRE}/lib/ext directory, but this is a somewhat extreme solution, and there may be other ways of doing this.
		
The steps necessary to make the example code work with Cocoon are:


- Copy the *jython_java2d.jar* and the *pngencoder.jar* files to your {JRE}/lib/ext directory.
- Download [Jython](http://www.jython.org/) and copy *jython.jar* to your {TOMCAT}/common/lib directory.
- Copy the sample XML, stylesheet and sitemap to the {COCOON}/mount/graphicstest directory.
- Edit the *sitemap.xmap* to change the temporary directory to the correct one for your machine - this is what Java uses when you call createTempFile().
- Restart Tomcat to pick up the new libraries
- Access via http://{YOUR COCOON URL}/mount/graphicstest/test.html


For this to work, you must be using [Xalan](https://xml.apache.org/xalan-j/) as an XSL processor. This is the default for Cocoon.



## Using SVG for graphics

An alternative is using SVG to generate graphics inline. This is supported by Internet Explorer only through plugins such as the Adobe SVG plugin, and is only supported by Mozilla in an optional add-on. Cocoon does give SVG support - including generating PNG files from SVG - and it is worth looking at, but sometimes generating graphics via script is more appropriate.


## References

Cocoon is an XML publishing framework available from [the Apache project](http://xml.apache.org/cocoon/). It is most easily deployed in the [Tomcat 4 servlet engine](http://jakarta.apache.org/tomcat/).
		
Java2D is the Java 2 2D graphics framework. The best reference I've found for it is the [O'Reilly Java2D book](http://www.oreilly.com/catalog/java2d/).
		
SVG is an XML standard for [Scalable Vector Graphics, documented at the W3C](http://www.w3.org/Graphics/SVG/).
		
The [code examples for this page can be downloaded](/code/images-from-jython.zip) and are covered under the [Gnu General Public License (GPL)](http://www.gnu.org/licenses/gpl.txt).
	
