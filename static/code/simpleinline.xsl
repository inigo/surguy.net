<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="/">
<html xmlns:svg="http://www.w3.org/2000/svg">     

<object id="AdobeSVG"     
   CLASSID="clsid:78156a80-c6a1-4bbf-8e6a-3cd390eeb4e2">
</object>
<xsl:processing-instruction name = "import" > namespace="svg" implementation="#AdobeSVG"</xsl:processing-instruction> 
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
