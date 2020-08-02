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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.    If not, see <http://www.gnu.org/licenses/>.

 * XSLT stylesheet to transform XHTML derived from Word 2010 files into Moodle Glossary XML
 *
 * @package local_glossary_wordimport
 * @copyright 2020 Eoin Campbell
 * @author Eoin Campbell
 * @license     http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later (5)
-->
<xsl:stylesheet exclude-result-prefixes="htm o w"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:o="urn:schemas-microsoft-com:office:office"
    xmlns:w="urn:schemas-microsoft-com:office:word"
    xmlns:htm="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    version="1.0">

<!-- Settings -->
<xsl:output encoding="UTF-8" method="xml" indent="yes" />

<!-- Top Level Parameters -->
<xsl:param name="debug_flag" select="1" />
<xsl:param name="moodle_release"/>  <!-- The release number of the current Moodle server -->
<xsl:param name="moodle_language"/>  <!-- The current language interface selected by the user -->

<xsl:variable name="ucase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
<xsl:variable name="lcase" select="'abcdefghijklmnopqrstuvwxyz'" />
<!-- Top Level Variables derived from input -->
<xsl:variable name="metadata" select="//htm:html/htm:head"/>
<xsl:variable name="courseID" select="$metadata/htm:meta[@name='moodleCourseID']/@content" />
<!-- Get the Moodle version as a simple 2-digit number, e.g. 2.6.5 => 26 -->
<xsl:variable name="moodleReleaseNumber" select="substring(translate($moodle_release, '.', ''), 1, 2)"/>

<!-- Top Level Parameters -->
<xsl:param name="moodle_labels_file_stub" select="'../htmltemplates/moodle/moodle_gloss'" />



    <!-- Default column numbers-->
    <xsl:variable name="nColumns" select="2"/>
    <xsl:variable name="option_colnum" select="2"/>
    <xsl:variable name="flag_value_colnum" select="2"/>
    <xsl:variable name="specific_feedback_colnum" select="3"/>
    <xsl:variable name="match_colnum" select="3"/>
    <xsl:variable name="generic_feedback_colnum" select="2"/> <!-- 2 because the label cell is a th, not a td -->
    <xsl:variable name="hints_colnum" select="2"/> <!-- 2 because the label cell is a th, not a td -->
    <xsl:variable name="tags_colnum" select="2"/> <!-- 1 because the label cell is a th, not a td -->
    <xsl:variable name="graderinfo_colnum" select="3"/>
    <xsl:variable name="responsetemplate_colnum" select="2"/>

<!-- Handle colon usage in French -->
<xsl:variable name="colon_string">
    <xsl:choose>
    <xsl:when test="starts-with($moodle_language, 'fr')"><xsl:text> :</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>:</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Generic labels -->



<!-- Glossary entry form field labels-->
<xsl:variable name="moodle_labels" select="//moodlelabels"/>
<xsl:variable name="no_label" select="$moodle_labels/data[@name = 'moodle_no']"/>
<xsl:variable name="yes_label" select="$moodle_labels/data[@name = 'moodle_yes']"/>
<xsl:variable name="concept_label" select="$moodle_labels/data[@name = 'glossary_concept']"/>
<xsl:variable name="definition_label" select="$moodle_labels/data[@name = 'glossary_definition']"/>
<xsl:variable name="categories_label" select="$moodle_labels/data[@name = 'glossary_categories']"/>
<xsl:variable name="keywords_label" select="$moodle_labels/data[@name = 'glossary_aliases']"/>
<xsl:variable name="entryusedynalink_label" select="$moodle_labels/data[@name = 'glossary_entryusedynalink']"/>
<xsl:variable name="casesensitive_label" select="$moodle_labels/data[@name = 'glossary_casesensitive']"/>
<xsl:variable name="fullmatch_label" select="$moodle_labels/data[@name = 'glossary_fullmatch']"/>

<!-- Glossary entry form field labels (unused) -->
<xsl:variable name="attachment_label" select="$moodle_labels/data[@name = 'glossary_attachment']"/>
<xsl:variable name="attachments_label" select="$moodle_labels/data[@name = 'glossary_attachments']"/>

<!-- Throw away the extra wrapper elements, now we've read them into variables -->
<xsl:template match="//moodlelabels"/>
<!--    Template Matches        -->

<xsl:template match="/pass2Container">
    <xsl:apply-templates/>
</xsl:template>
<xsl:template match="//glossary">
    <GLOSSARY>
        <INFO>
            <NAME><xsl:value-of select="p[@class = 'title'][1]"/>
            </NAME>
            <INTRO>
            </INTRO>
            <INTROFORMAT>1</INTROFORMAT>
            <ALLOWDUPLICATEDENTRIES>0</ALLOWDUPLICATEDENTRIES>
            <DISPLAYFORMAT>dictionary</DISPLAYFORMAT>
            <SHOWSPECIAL>1</SHOWSPECIAL>
            <SHOWALPHABET>1</SHOWALPHABET>
            <SHOWALL>1</SHOWALL>
            <ALLOWCOMMENTS>0</ALLOWCOMMENTS>
            <USEDYNALINK>1</USEDYNALINK>
            <DEFAULTAPPROVAL>1</DEFAULTAPPROVAL>
            <GLOBALGLOSSARY>1</GLOBALGLOSSARY>
            <ENTBYPAGE>10</ENTBYPAGE>
            <ENTRIES>
                <xsl:for-each select="//h1">
                    <!--
                    <xsl:comment>concept: <xsl:value-of select="."/></xsl:comment>
                    <xsl:comment>definition: <xsl:value-of select="../table[1]/thead/tr[1]/th[1]"/></xsl:comment>
                    -->
                    <xsl:call-template name="termConcept">
                        <xsl:with-param name="table_root" select="following-sibling::table" />
                        <xsl:with-param name="concept" select="." />
                    </xsl:call-template>
                </xsl:for-each>
            </ENTRIES>
        </INFO>
    </GLOSSARY>
</xsl:template>

<!-- Process a full item -->
<xsl:template name="termConcept">
    <xsl:param name="concept"/>
    <xsl:param name="table_root"/>

    <xsl:variable name="entryusedynalink_value" select="normalize-space(translate($table_root/thead/tr[starts-with(th[1], $entryusedynalink_label)]/th[2], $ucase, $lcase))"/>
    <xsl:variable name="casesensitive_value" select="normalize-space(translate($table_root/thead/tr[starts-with(th[1], $casesensitive_label)]/th[position() = $flag_value_colnum], $ucase, $lcase))"/>
    <xsl:variable name="fullmatch_value" select="normalize-space(translate($table_root/thead/tr[starts-with(th[1], $fullmatch_label)]/th[position() = $flag_value_colnum], $ucase, $lcase))"/>

    <ENTRY>
        <CONCEPT>
            <xsl:value-of select="$concept"/>
        </CONCEPT>
        <DEFINITION>
            <xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes"/>
            <xsl:copy-of select="$table_root/thead/tr[1]/th[1]/*"/>
            <xsl:value-of select="']]>'" disable-output-escaping="yes"/>
        </DEFINITION>

        <!--
        <xsl:comment>categories_label = <xsl:value-of select="$categories_label"/></xsl:comment>
        <xsl:comment>entryusedynalink_value = <xsl:value-of select="$entryusedynalink_value"/></xsl:comment>
        <xsl:comment>casesensitive_value = <xsl:value-of select="$casesensitive_value"/></xsl:comment>
        <xsl:comment>fullmatch_value = <xsl:value-of select="$fullmatch_value"/></xsl:comment>
        -->
        <FORMAT>1</FORMAT>
        <USEDYNALINK><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$entryusedynalink_value"/></xsl:call-template></USEDYNALINK>
        <CASESENSITIVE><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$casesensitive_value"/></xsl:call-template></CASESENSITIVE>
        <FULLMATCH><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$fullmatch_value"/></xsl:call-template></FULLMATCH>

        <!-- Handle any keywords that are included - all in one cell, comma-separated -->
        <xsl:variable name="keywords_row" select="$table_root/thead/tr[starts-with(th[1], $keywords_label)]/th[2]"/>
        <!--
        <xsl:comment>keywords_label = <xsl:value-of select="$keywords_label"/></xsl:comment>
        <xsl:comment>keywords_row = <xsl:value-of select="$keywords_row"/></xsl:comment>
        -->
        <xsl:if test="normalize-space($keywords_row) != '' and normalize-space($keywords_row) != '&#160;' and normalize-space($keywords_row) != '_'">
            <ALIASES>
                <xsl:choose>
                <xsl:when test="contains($keywords_row, ',')">
                    <ALIAS><NAME><xsl:value-of select="normalize-space(substring-before($keywords_row, ','))"/></NAME></ALIAS>
                    <xsl:call-template name="handle_keywords_row">
                        <xsl:with-param name="keywords_row" select="normalize-space(substring-after($keywords_row, ','))"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <ALIAS><NAME><xsl:value-of select="normalize-space($keywords_row)"/></NAME></ALIAS>
                </xsl:otherwise>
                </xsl:choose>
            </ALIASES>
        </xsl:if>

        <!-- Handle any categories that are included - all in one cell, comma-separated -->
        <xsl:variable name="categories_row" select="$table_root/thead/tr[starts-with(th[1], $categories_label)]/th[2]/*"/>
        <xsl:if test="normalize-space($categories_row) != '' and normalize-space($categories_row) != '&#160;' and normalize-space($categories_row) != '_'">
            <CATEGORIES>
                <xsl:choose>
                <xsl:when test="contains($categories_row, ',')">
                    <CATEGORY><NAME><xsl:value-of select="normalize-space(substring-before($categories_row, ','))"/></NAME></CATEGORY>
                    <xsl:call-template name="handle_categories_row">
                        <xsl:with-param name="categories_row" select="normalize-space(substring-after($categories_row, ','))"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <CATEGORY><NAME><xsl:value-of select="normalize-space($categories_row)"/></NAME></CATEGORY>
                </xsl:otherwise>
                </xsl:choose>
            </CATEGORIES>
        </xsl:if>
    </ENTRY>
</xsl:template>

<xsl:template name="handle_categories_row">
    <xsl:param name="categories_row"/>

    <xsl:choose>
    <xsl:when test="contains($categories_row, ',')">
        <CATEGORY><NAME><xsl:value-of select="normalize-space(substring-before($categories_row, ','))"/></NAME></CATEGORY>
        <xsl:call-template name="handle_categories_row">
            <xsl:with-param name="categories_row" select="normalize-space(substring-after($categories_row, ','))"/>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <CATEGORY><NAME><xsl:value-of select="normalize-space($categories_row)"/></NAME></CATEGORY>
    </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="handle_keywords_row">
    <xsl:param name="keywords_row"/>

    <xsl:choose>
    <xsl:when test="contains($keywords_row, ',')">
        <ALIAS><NAME><xsl:value-of select="normalize-space(substring-before($keywords_row, ','))"/></NAME></ALIAS>
        <xsl:call-template name="handle_keywords_row">
            <xsl:with-param name="keywords_row" select="normalize-space(substring-after($keywords_row, ','))"/>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <ALIAS><NAME><xsl:value-of select="normalize-space($keywords_row)"/></NAME></ALIAS>
    </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- This template converts 'Yes'/'No' and variants to 0/1 -->
<xsl:template name="convert_value_to_number">
    <xsl:param name="string_value"/>

    <xsl:variable name="string_value_normalized" select="normalize-space(translate($string_value, $ucase, $lcase))"/>

    <xsl:choose>
    <xsl:when test="starts-with($string_value_normalized, normalize-space(translate($yes_label, $ucase, $lcase)))">
        <xsl:text>1</xsl:text>
    </xsl:when>
    <xsl:when test="starts-with($string_value_normalized, normalize-space(translate($no_label, $ucase, $lcase)))">
        <xsl:text>0</xsl:text>
    </xsl:when>
    <xsl:otherwise>
        <xsl:text>0</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
</xsl:template>





<!-- Omit span elements for language, e.g. span/@lang="en-ie" -->
<xsl:template match="span[@lang] | a[starts-with(@name, 'Heading')]">
    <xsl:apply-templates/>
</xsl:template>







<!-- Omit classes beginning with a QF style  -->
<xsl:template match="@class">
    <xsl:choose>
    <xsl:when test="starts-with(., 'QF')"><!-- Omit class --></xsl:when>
    <xsl:when test="starts-with(., 'Body')"><!-- Omit class --></xsl:when>
    <xsl:when test="starts-with(., 'Normal')"><!-- Omit class --></xsl:when>
    <xsl:when test="starts-with(., 'Cell')"><!-- Omit class --></xsl:when>
    <xsl:when test="starts-with(., 'Question')"><!-- Omit class --></xsl:when>
    <xsl:when test="starts-with(., 'Instructions')"><!-- Omit class --></xsl:when>
    <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Text: check if numbering should be removed -->
<xsl:template match="text()">
    <xsl:call-template name="convertUnicode">
        <xsl:with-param name="txt" select="."/>
    </xsl:call-template>
</xsl:template>


<!-- Identity transformations -->
<xsl:template match="*">
    <xsl:element name="{name()}">
        <xsl:call-template name="copyAttributes" />
        <xsl:apply-templates select="node()"/>
    </xsl:element>
</xsl:template>


<!-- Handle text, removing text before tabs, deleting non-significant newlines between elements, etc. -->
<xsl:template name="convertUnicode">
    <xsl:param name="txt"/>

    <xsl:choose>
        <!-- If empty (or newline), do nothing: needed to stop newlines between block elements being turned into br elements -->
        <xsl:when test="normalize-space($txt) = ''">
        </xsl:when>
        <!-- If tab, include only the text after it -->
        <xsl:when test="contains($txt, '&#x9;')">
            <xsl:call-template name="convertUnicode">
                <xsl:with-param name="txt" select="substring-after($txt, '&#x9;')"/>
            </xsl:call-template>
        </xsl:when>
        <!-- If a newline, insert a br element instead -->
        <xsl:when test="contains($txt, '&#x0a;')">
            <xsl:value-of select="substring-before($txt, '&#x0a;')"/>
            <br/>
            <xsl:call-template name="convertUnicode">
                <xsl:with-param name="txt" select="substring-after($txt, '&#x0a;')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$txt"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Handle images in Moodle 2.x to use PLUGINFILE-->

<xsl:template match="img">
        <!-- Moodle 2 images have the data component moved to the file element -->
        <img>
            <xsl:variable name="image_format" select="substring-after(substring-before(@src, ';'), '/')"/>
            <xsl:attribute name="src">
                <xsl:value-of select="concat('@@PLUGINFILE@@/mqimage_', generate-id(), '.', $image_format)"/>
            </xsl:attribute>
            <xsl:if test="@alt and normalize-space(@alt) != '' and normalize-space(@alt) != '&#160;'">
                <xsl:attribute name="alt"><xsl:value-of select="@alt"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="@width">
                <xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="@height">
                <xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute>
            </xsl:if>
        </img>
</xsl:template>



<xsl:template match="img" mode="moodle2pluginfile">
    <xsl:variable name="image_format" select="substring-after(substring-before(@src, ';'), '/')"/>

    <file name="{concat('mqimage_', generate-id(), '.', $image_format)}" encoding="base64">
        <xsl:value-of select="substring-after(@src, 'base64,')"/>
    </file>
</xsl:template>

<xsl:template name="copyAttributes">
    <xsl:for-each select="@*">
        <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
