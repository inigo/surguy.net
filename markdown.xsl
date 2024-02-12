<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="text"/>


    <xsl:template match="article">
        ---
        title: <xsl:value-of select="title"/>
        date: 2021-04-03T22:53:58+05:30
        draft: false
        author: <xsl:value-of select="articleinfo/author/firstname"/><xsl:text> </xsl:text><xsl:value-of select="articleinfo/author/surname"/>
        description: <xsl:value-of select="normalize-space(articleinfo/abstract)"/>
        #toc:
        ---
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="articleinfo"/>

    <xsl:template match="section" mode="hash">#</xsl:template>

    <xsl:template match="section/title">
        <xsl:text/>#<xsl:apply-templates select="ancestor::section" mode="hash"/><xsl:text> </xsl:text><xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="para"><xsl:text>
</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="title"/>
    <xsl:template match="emphasis[@role='bold']" priority="1">***<xsl:apply-templates/>***</xsl:template>
    <xsl:template match="emphasis">**<xsl:apply-templates/>**</xsl:template>
    <xsl:template match="ulink">[<xsl:apply-templates/>](<xsl:value-of select="@url" />)</xsl:template>
    <xsl:template match="listitem">- <xsl:apply-templates/></xsl:template>
    <xsl:template match="listitem/para"><xsl:apply-templates/></xsl:template>

    <xsl:template match="itemizedlist"><xsl:text>
</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="lineannotation">***<xsl:apply-templates/>***</xsl:template>

    <xsl:template match="inlinemediaobject">![<xsl:value-of select="textobject/phrase"/>](<xsl:value-of select="imageobject/imagedata/@fileref"/>)</xsl:template>
    <xsl:template match="inlinemediaobject//text()"></xsl:template>

    <xsl:template match="programlisting"><code><pre><xsl:apply-templates/></pre></code></xsl:template>

    <!--    <xsl:template match="text()">
            <xsl:value-of select="replace(concat(normalize-space(.),' '), '(.{0,120}) ', '$1&#xA;')"/>
        </xsl:template>-->
</xsl:stylesheet>