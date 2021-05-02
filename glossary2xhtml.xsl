<?xml version="1.0" encoding="UTF-8"?>
<!--
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

 * XSLT stylesheet to wrap glossary terms formatted as HTML tables with a Word-compatible wrapper that defines the styles, metadata, etc.
 *
 * @package    local_glossary_wordimport
 * @copyright  2010-2015 Eoin Campbell
 * @author     Eoin Campbell
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later (5)
-->
<xsl:stylesheet exclude-result-prefixes="htm"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:htm="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    version="1.0">

<xsl:param name="course_name"/>
<xsl:param name="course_id"/>
<xsl:param name="author_name"/>
<xsl:param name="author_id"/>
<xsl:param name="institution_name"/>
<xsl:param name="moodle_language" select="'en'"/> <!-- Interface language for user -->
<xsl:param name="moodle_release"/> <!-- 1.9 or 2.x -->
<xsl:param name="moodle_textdirection" select="'ltr'"/> <!-- ltr/rtl, ltr except for Arabic, Hebrew, Urdu, Farsi, Maldivian (who knew?) -->
<xsl:param name="moodle_username"/> <!-- Username for login -->
<xsl:param name="moodle_url"/>      <!-- Location of Moodle site -->
<xsl:param name="debug_flag" select="'0'"/>      <!-- Debugging on or off -->

<xsl:output method="xml" version="1.0" indent="yes" omit-xml-declaration="yes"/>

<!-- Text labels from translated Moodle files - now stored in the input XML file -->
<xsl:variable name="moodle_labels" select="/pass1Container/moodlelabels"/>


<xsl:variable name="ucase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
<xsl:variable name="lcase" select="'abcdefghijklmnopqrstuvwxyz'" />

<!-- Convert Moodle release numbers such as "2.4" to "24" for easier numerical comparisons, to decide what question heading rows to include -->
<xsl:variable name="moodle_release_number" select="translate(substring($moodle_release, 1, 3), '.', '')"/>

<!-- Handle colon usage in French -->
<xsl:variable name="colon_string">
    <xsl:choose>
    <xsl:when test="starts-with($moodle_language, 'fr')"><xsl:text> :</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>:</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="blank_cell" select="'&#160;'"/>

<!-- Create the list of labels from text strings in Moodle, to maximise familiarity of Word file labels -->
<xsl:variable name="casesensitive_label" select="concat($moodle_labels/data[@name = 'glossary_casesensitive'], $colon_string)"/>
<xsl:variable name="categories_label" select="concat($moodle_labels/data[@name = 'glossary_categories'], $colon_string)"/>
<xsl:variable name="concept_label" select="concat($moodle_labels/data[@name = 'glossary_concept'], $colon_string)"/>
<xsl:variable name="definition_label" select="concat($moodle_labels/data[@name = 'glossary_definition'], $colon_string)"/>
<xsl:variable name="displayformat_label" select="concat($moodle_labels/data[@name = 'glossary_displayformat'], $colon_string)"/>
<xsl:variable name="entryusedynalink_label" select="concat($moodle_labels/data[@name = 'glossary_entryusedynalink'], $colon_string)"/>
<xsl:variable name="fullmatch_label" select="concat($moodle_labels/data[@name = 'glossary_fullmatch'], $colon_string)"/>
<xsl:variable name="keywords_label" select="concat($moodle_labels/data[@name = 'glossary_aliases'], $colon_string)"/>
<xsl:variable name="linking_label" select="concat($moodle_labels/data[@name = 'glossary_linking'], $colon_string)"/>
<xsl:variable name="no_label" select="$moodle_labels/data[@name = 'moodle_no']"/>
<xsl:variable name="pluginname_label" select="concat($moodle_labels/data[@name = 'glossary_pluginname'], $colon_string)"/>
<xsl:variable name="tags_label" select="concat($moodle_labels/data[@name = 'moodle_tags'], $colon_string)"/>
<xsl:variable name="teacherentry_label" select="concat($moodle_labels/data[@name = 'local_glossary_wordimport_teacherentry'], $colon_string)"/>
<xsl:variable name="wordinstructions_help" select="$moodle_labels/data[@name = 'local_glossary_wordimport_wordinstructions_help']"/>
<xsl:variable name="yes_label" select="$moodle_labels/data[@name = 'moodle_yes']"/>


<!-- Column widths -->
<xsl:variable name="col1_width" select="'width: 9.0cm'"/>
<xsl:variable name="col2_width" select="'width: 3.0cm'"/>

<!-- Match document root node, and read in and process Word-compatible XHTML template -->
<xsl:template match="/pass1Container">
    <xsl:apply-templates select="GLOSSARY"/>
</xsl:template>

<xsl:template match="GLOSSARY">
    <!-- Export the glossary title and introduction text, then loop through the entries -->
    <div>
        <p class="MsoTitle"><xsl:apply-templates select="INFO/NAME"/></p>
        <xsl:apply-templates select="INFO/INTRO"/>
        <xsl:apply-templates select="INFO/DISPLAYFORMAT"/>

        <xsl:apply-templates select="INFO/ENTRIES/ENTRY"/>
    </div>
</xsl:template>

<!-- Throw away extra wrapper elements included in container XML -->
<xsl:template match="/pass1Container/moodlelabels"/>

<xsl:template match="ENTRY">
    <!-- Loop through each Glossary entry -->
    <div>
        <h1 class="MsoHeading1"><xsl:value-of select="CONCEPT"/></h1>
        <table border="1" dir="{$moodle_textdirection}" class="m2w_metatable">
        <thead>
            <tr>
                <td style="{$col1_width}"><p class="Cell"><xsl:apply-templates select="DEFINITION"/></p></td>
                <td style="{$col2_width}"><p class="QFType">GL</p></td>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$keywords_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="ALIASES"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$categories_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="CATEGORIES"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$entryusedynalink_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="USEDYNALINK"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$casesensitive_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="CASESENSITIVE"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$fullmatch_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="FULLMATCH"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$teacherentry_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="TEACHERENTRY"/></p></td>
            </tr>
            <tr>
                <td style="{$col1_width}"><p class="TableRowHead"><xsl:value-of select="$tags_label"/></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:apply-templates select="TAGS"/></p></td>
            </tr>
            <!-- Instructions row -->
            <tr>
                <td style="{$col1_width}"><p class="Cell"><i><xsl:value-of select="$wordinstructions_help"/></i></p></td>
                <td style="{$col2_width}"><p class="Cell"><xsl:value-of select="$blank_cell"/></p></td>
            </tr>
        </tbody>
        </table>
        <p class="MsoBodyText"><xsl:value-of select="$blank_cell"/></p>
    </div>
</xsl:template>

<xsl:template match="DISPLAYFORMAT">
    <xsl:variable name="displayformat_type" select="concat('glossary_displayformat', normalize-space(.))"/>
    <xsl:variable name="displayformat_value" select="$moodle_labels/data[@name = $displayformat_type]"/>
    <!-- <p><xsl:value-of select="concat('Format: ', ., '; Type: ', $displayformat_type)"/></p> -->

    <p class="MsoBodyText"><b><xsl:value-of select="$displayformat_label"/></b><xsl:text> </xsl:text><xsl:value-of select="$displayformat_value"/></p>
</xsl:template>


<!-- Handle definition elements, which may consist only of a CDATA section -->
<xsl:template match="DEFINITION|INTRO">
    <xsl:variable name="text_string">
        <xsl:variable name="raw_text" select="normalize-space(.)"/>

        <xsl:choose>
        <!-- If the string is wrapped in <p>...</p>, get rid of it -->
        <xsl:when test="starts-with($raw_text, '&lt;p&gt;')">
            <!-- 7 = string-length('<p>') + string-length('</p>') </p> -->
            <xsl:value-of select="substring($raw_text, 4, string-length($raw_text) - 7)"/>
        </xsl:when>
        <xsl:when test="starts-with($raw_text, '&lt;table')">
            <!-- Add a blank paragraph before the table, -->
            <xsl:value-of select="concat('&lt;p&gt;', $blank_cell, '&lt;/p&gt;', $raw_text)"/>
        </xsl:when>
        <xsl:when test="$raw_text = ''"><xsl:value-of select="$blank_cell"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$raw_text"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$text_string" disable-output-escaping="yes"/>
</xsl:template>

<xsl:template match="CATEGORIES">
    <xsl:choose>
    <xsl:when test="CATEGORY = ''">
        <!-- tag element present but empty -->
        <xsl:value-of select="$blank_cell"/>
    </xsl:when>
    <xsl:when test="CATEGORY">
        <!-- tag element present and not empty -->
            <xsl:for-each select="CATEGORY/NAME">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$blank_cell"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ALIASES">
    <xsl:choose>
    <xsl:when test="ALIAS = ''">
        <!-- tag element present but empty -->
        <xsl:value-of select="$blank_cell"/>
    </xsl:when>
    <xsl:when test="ALIAS">
        <!-- tag element present and not empty -->
            <xsl:for-each select="ALIAS/NAME">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$blank_cell"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="USEDYNALINK">
    <xsl:choose>
    <xsl:when test=". = '1'"><xsl:value-of select="$yes_label"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$no_label"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="CASESENSITIVE">
    <xsl:choose>
    <xsl:when test=". = '1'"><xsl:value-of select="$yes_label"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$no_label"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="FULLMATCH">
    <xsl:choose>
    <xsl:when test=". = '1'"><xsl:value-of select="$yes_label"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$no_label"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="TEACHERENTRY">
    <xsl:choose>
    <xsl:when test=". = '1'"><xsl:value-of select="$yes_label"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$no_label"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="TAGS">
    <xsl:choose>
    <xsl:when test="TAG = ''">
        <!-- tag element present but empty -->
        <xsl:value-of select="$blank_cell"/>
    </xsl:when>
    <xsl:when test="TAG">
        <!-- tag element present and not empty -->
            <xsl:for-each select="TAG">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$blank_cell"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Handle images associated with '@@PLUGINFILE@@' keyword by including them in temporary supplementary paragraphs in whatever component they occur in -->
<xsl:template match="FILE">
    <xsl:param name="image_id"/>

    <xsl:variable name="image_file_suffix">
        <xsl:value-of select="translate(substring-after(@name, '.'), $ucase, $lcase)"/>
    </xsl:variable>
    <xsl:variable name="image_format">
        <xsl:value-of select="concat('data:image/', $image_file_suffix, ';', @encoding, ',')"/>
    </xsl:variable>
    <xsl:variable name="alt_text">
        <xsl:value-of select="concat('data:image/', $image_file_suffix, ';', @encoding, ',')"/>
    </xsl:variable>

    <div class="ImageFile">
        <img title="{@name}" src="{concat($image_format, .)}">
            <xsl:if test="$image_id != ''">
                <xsl:attribute name="id"><xsl:value-of select="$image_id"/></xsl:attribute>
            </xsl:if>
        </img>
    </div>
</xsl:template>

<!-- got to preserve comments for style definitions -->
<xsl:template match="comment()">
    <xsl:comment><xsl:value-of select="."/></xsl:comment>
</xsl:template>

<!-- Identity transformations -->
<xsl:template match="*">
    <xsl:element name="{name()}">
        <xsl:call-template name="copyAttributes" />
        <xsl:apply-templates select="node()"/>
    </xsl:element>
</xsl:template>

<xsl:template name="copyAttributes">
    <xsl:for-each select="@*">
        <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
</xsl:template>

<!-- Include debugging information in the output -->
<xsl:template name="debugComment">
    <xsl:param name="comment_text"/>
    <xsl:param name="inline" select="'false'"/>
    <xsl:param name="condition" select="'true'"/>

    <xsl:if test="boolean($condition) and $debug_flag != 0">
        <xsl:if test="$inline = 'false'"><xsl:text>&#x0a;</xsl:text></xsl:if>
        <xsl:comment><xsl:value-of select="concat('Debug: ', $comment_text)"/></xsl:comment>
        <xsl:if test="$inline = 'false'"><xsl:text>&#x0a;</xsl:text></xsl:if>
    </xsl:if>
</xsl:template>
</xsl:stylesheet>
