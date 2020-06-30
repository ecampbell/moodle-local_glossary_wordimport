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
<xsl:stylesheet version="1.0" exclude-result-prefixes="dc wd"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:wd="http://www.xmlw.ie/webdoc/"
>

<!-- Settings -->
<xsl:output encoding="UTF-8" method="xml" indent="yes" />

<!-- Top Level Keys -->
<xsl:key name="footnotes" match="div[@class = 'footnotes']/p" use="a/@name" />

<!-- Top Level Parameters -->
<xsl:param name="moodle_labels_file_stub" select="'../htmltemplates/moodle/moodle_gloss'" />

<!-- Top Level Variables derived from input -->
<xsl:variable name="courseID" select="/webdoc/head/wordmeta/meta[@name='moodleCourseID']/@content" />
<xsl:variable name="moodleRelease" select="/webdoc/head/wordmeta/meta[@name='moodleRelease']/@content" />
<xsl:variable name="moodleReleaseNumber">
    <xsl:choose>
    <xsl:when test="$moodleRelease = ''"><xsl:text>0</xsl:text></xsl:when> <!-- Original version which doesn't include the release number in a custom property -->
    <xsl:when test="starts-with($moodleRelease, '1')"><xsl:text>1</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.0')"><xsl:text>23</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.1')"><xsl:text>23</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.2')"><xsl:text>23</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.3')"><xsl:text>23</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.4')"><xsl:text>24</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.5')"><xsl:text>25</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.6')"><xsl:text>26</xsl:text></xsl:when>
    <xsl:when test="starts-with($moodleRelease, '2.7')"><xsl:text>27</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>0</xsl:text></xsl:otherwise> <!-- 2.5, 2.6 and higher are considered the same for the moment -->
    </xsl:choose>
</xsl:variable>

<xsl:variable name="interfaceLanguage">
    <xsl:variable name="moodleLanguage" select="/webdoc/head/wordmeta/meta[@name='moodleLanguage']/@content" />
    <xsl:choose>
    <xsl:when test="$moodleLanguage = ''"><xsl:value-of select="'en'"/></xsl:when>
    <xsl:when test="contains($moodleLanguage, '_')"><xsl:value-of select="substring-before($moodleLanguage, '_')"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$moodleLanguage"/></xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="language_labels_file">
    <xsl:variable name="moodle_release_suffix">
    <xsl:if test="$moodleReleaseNumber = '1'">
        <xsl:text>1</xsl:text>
    </xsl:if>
    </xsl:variable>
    <xsl:choose>
    <xsl:when test="$interfaceLanguage != ''"><xsl:value-of select="concat($moodle_labels_file_stub, $moodle_release_suffix, '_', $interfaceLanguage, '.xml')"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="concat($moodle_labels_file_stub, $moodle_release_suffix, '_', 'en.xml')"/></xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="moodle_labels" select="document($language_labels_file)/moodlelabels" />

    <!-- Default column numbers-->
    <xsl:variable name="nColumns" select="2"/>
    <xsl:variable name="option_colnum" select="2"/>
    <xsl:variable name="flag_value_colnum" select="1"/>
    <xsl:variable name="specific_feedback_colnum" select="3"/>
    <xsl:variable name="match_colnum" select="3"/>
    <xsl:variable name="generic_feedback_colnum" select="2"/> <!-- 2 because the label cell is a th, not a td -->
    <xsl:variable name="hints_colnum" select="2"/> <!-- 2 because the label cell is a th, not a td -->
    <xsl:variable name="tags_colnum" select="1"/> <!-- 1 because the label cell is a th, not a td -->
    <xsl:variable name="graderinfo_colnum" select="3"/>
    <xsl:variable name="responsetemplate_colnum" select="2"/>

<!-- Handle colon usage in French -->
<xsl:variable name="colon_string">
    <xsl:choose>
    <xsl:when test="starts-with($interfaceLanguage, 'fr')"><xsl:text> :</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>:</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Generic labels -->
<xsl:variable name="no_label" select="$moodle_labels/data[@name = 'moodle_no']"/>
<xsl:variable name="yes_label" select="$moodle_labels/data[@name = 'moodle_yes']"/>

<!-- Import form flags -->
<xsl:variable name="destination_label" select="$moodle_labels/data[@name = 'glossary_destination']"/>
<xsl:variable name="currentglossary_label" select="$moodle_labels/data[@name = 'glossary_currentglossary']"/>
<xsl:variable name="newglossary_label" select="$moodle_labels/data[@name = 'glossary_newglossary']"/>
<xsl:variable name="importcategories_label" select="$moodle_labels/data[@name = 'glossary_importcategories']"/>

<!-- Glossary settings form: General labels and flags -->
<xsl:variable name="name_label" select="$moodle_labels/data[@name = 'moodle_name']"/>
<xsl:variable name="description_label" select="$moodle_labels/data[@name = 'moodle_description']"/>
<xsl:variable name="showdescription_label" select="$moodle_labels/data[@name = 'moodle_showdescription']"/>
<xsl:variable name="isglobal_label" select="$moodle_labels/data[@name = 'glossary_isglobal']"/>
<xsl:variable name="type_label" select="$moodle_labels/data[@name = 'glossary_glossarytype']"/>
<xsl:variable name="mainglossary_label" select="$moodle_labels/data[@name = 'glossary_mainglossary']"/>
<xsl:variable name="secondaryglossary_label" select="$moodle_labels/data[@name = 'glossary_secondaryglossary']"/>

<!-- Glossary settings form: Entries flags -->
<xsl:variable name="defaultapproval_label" select="$moodle_labels/data[@name = 'glossary_defaultapproval']"/>
<xsl:variable name="editalways_label" select="$moodle_labels/data[@name = 'glossary_editalways']"/>
<xsl:variable name="allowduplicatedentries_label" select="$moodle_labels/data[@name = 'glossary_allowduplicatedentries']"/>
<xsl:variable name="allowcomments_label" select="$moodle_labels/data[@name = 'glossary_allowcomments']"/>
<xsl:variable name="usedynalink_label" select="$moodle_labels/data[@name = 'glossary_usedynalink']"/>

<!-- Glossary settings form: Appearance flags -->
<xsl:variable name="displayformat_label" select="$moodle_labels/data[@name = 'glossary_displayformat']"/>
<xsl:variable name="displayformatcontinuous_label" select="$moodle_labels/data[@name = 'glossary_displayformatcontinuous']"/>
<xsl:variable name="displayformatdefault_label" select="$moodle_labels/data[@name = 'glossary_displayformatdefault']"/>
<xsl:variable name="displayformatdictionary_label" select="$moodle_labels/data[@name = 'glossary_displayformatdictionary']"/>
<xsl:variable name="displayformatencyclopedia_label" select="$moodle_labels/data[@name = 'glossary_displayformatencyclopedia']"/>
<xsl:variable name="displayformatentrylist_label" select="$moodle_labels/data[@name = 'glossary_displayformatentrylist']"/>
<xsl:variable name="displayformatfaq_label" select="$moodle_labels/data[@name = 'glossary_displayformatfaq']"/>
<xsl:variable name="displayformatfullwithauthor_label" select="$moodle_labels/data[@name = 'glossary_displayformatfullwithauthor']"/>
<xsl:variable name="displayformatfullwithoutauthor_label" select="$moodle_labels/data[@name = 'glossary_displayformatfullwithoutauthor']"/>

<xsl:variable name="approvaldisplayformat_label" select="$moodle_labels/data[@name = 'glossary_approvaldisplayformat']"/>

<xsl:variable name="entbypage_label" select="$moodle_labels/data[@name = 'glossary_entbypage']"/>
<xsl:variable name="showalphabet_label" select="$moodle_labels/data[@name = 'glossary_showalphabet']"/>
<xsl:variable name="showall_label" select="$moodle_labels/data[@name = 'glossary_showall']"/>
<xsl:variable name="showspecial_label" select="$moodle_labels/data[@name = 'glossary_showspecial']"/>
<xsl:variable name="allowprintview_label" select="$moodle_labels/data[@name = 'glossary_allowprintview']"/>

<!-- Glossary entry form field labels-->
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


<!--    Template Matches        -->
<xsl:template match="/body">
        <xsl:apply-templates />
</xsl:template>

<!-- Template Matches -->
<xsl:template match="webdoc">


<!-- Import form values -->
<xsl:variable name="destination_value" select="$data/webdoc/body/table[1]/tbody/tr[starts-with(th, $destination_label)]/td[position() = $flag_value_colnum]/*"/>
<xsl:variable name="importcategories_value" select="$moodle_labels/data[@name = 'glossary_importcategories']"/>

<!-- Glossary settings form: General field values -->
<xsl:variable name="name_value" select="$data/webdoc/body/table[1]/tbody/tr[starts-with(th, $name_label)]/td[position() = $flag_value_colnum]/*"/>
<xsl:variable name="description_value" select="$data/webdoc/body/table[1]/tbody/tr[starts-with(th, $description_label)]/td[position() = $flag_value_colnum]/*"/>
<xsl:variable name="showdescription_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $showdescription_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="isglobal_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $isglobal_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="type_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $type_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="defaultapproval_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $defaultapproval_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="editalways_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $editalways_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="allowduplicatedentries_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $allowduplicatedentries_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="allowcomments_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $allowcomments_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="usedynalink_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $usedynalink_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="displayformat_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $displayformat_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="approvaldisplayformat_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $approvaldisplayformat_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="showalphabet_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $showalphabet_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="showall_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $showall_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="showspecial_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $showspecial_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>
<xsl:variable name="allowprintview_value" select="normalize-space(translate($data/webdoc/body/table[1]/tbody/tr[starts-with(th, $allowprintview_label)]/td[position() = $flag_value_colnum]/*, $ucase, $lcase))"/>

<xsl:variable name="entbypage_value" select="$data/webdoc/body/table[1]/tbody/tr[starts-with(th, $entbypage_label)]/td[position() = $flag_value_colnum]/*"/>


    <GLOSSARY>
        <INFO>
            <NAME>
                <xsl:value-of select="$name_value"/>
            </NAME>
            <INTRO>
                <xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes"/>
                <xsl:copy-of select="$data/webdoc/body/table[1]/tbody/tr[starts-with(th, $description_label)]/td[position() = $flag_value_colnum]/*"/>
                <xsl:value-of select="']]>'" disable-output-escaping="yes"/>
            </INTRO>
            <INTROFORMAT><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$showdescription_value"/></xsl:call-template></INTROFORMAT>
            <ALLOWDUPLICATEDENTRIES><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$allowduplicatedentries_value"/></xsl:call-template></ALLOWDUPLICATEDENTRIES>
            <DISPLAYFORMAT><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$displayformat_value"/></xsl:call-template></DISPLAYFORMAT>
            <SHOWSPECIAL><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$showspecial_value"/></xsl:call-template></SHOWSPECIAL>
            <SHOWALPHABET><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$showalphabet_value"/></xsl:call-template></SHOWALPHABET>
            <SHOWALL><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$showall_value"/></xsl:call-template></SHOWALL>
            <ALLOWCOMMENTS><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$allowcomments_value"/></xsl:call-template></ALLOWCOMMENTS>
            <USEDYNALINK><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$usedynalink_value"/></xsl:call-template></USEDYNALINK>
            <DEFAULTAPPROVAL><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$defaultapproval_value"/></xsl:call-template></DEFAULTAPPROVAL>
            <GLOBALGLOSSARY><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$isglobal_value"/></xsl:call-template></GLOBALGLOSSARY>
            <ENTBYPAGE><xsl:value-of select="$entbypage_value"/></ENTBYPAGE>
            <xsl:comment>Course (ID): <xsl:value-of select="concat($data//h1[1], ' (', $courseID, ')')"/></xsl:comment>
            <xsl:comment>maxTerms: <xsl:value-of select="$maxTerms"/></xsl:comment>
            <xsl:comment>language_labels_file: <xsl:value-of select="$language_labels_file"/></xsl:comment>
            <xsl:comment>interfaceLanguage: <xsl:value-of select="$interfaceLanguage"/></xsl:comment>

            <ENTRIES>
            <!-- 2 cases to handle: a) all terms; b) limited number of terms for freebooters -->
            <xsl:choose>
            <!-- If maxTerms not 0, return maxTerms terms only  -->
            <xsl:when test="$maxTerms != 0">

                <xsl:for-each select="$data//div[(position() &lt;= $maxTerms)]">
                    <xsl:call-template name="termConcept">
                        <xsl:with-param name="table_root" select="./table" />
                        <xsl:with-param name="concept" select="./h2" />
                    </xsl:call-template>
                </xsl:for-each>

                <!-- Include a description term with a warning
                    to indicate that remaining terms have not been imported -->
                <xsl:if test="count($data//div) &gt; $maxTerms">
                <ENTRY>
                    <CONCEPT>Term limit reached</CONCEPT>
                    <DEFINITION></DEFINITION>
                    <FORMAT>1</FORMAT>
                    <USEDYNALINK>0</USEDYNALINK>
                    <CASESENSITIVE>0</CASESENSITIVE>
                    <FULLMATCH>0</FULLMATCH>
                    <TEACHERENTRY>0</TEACHERENTRY>
                </ENTRY>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$data//div">
                <xsl:comment>concept: <xsl:value-of select="./h2"/></xsl:comment>
                <xsl:comment>definition: <xsl:value-of select="./table/tbody/tr[1]/td[1]"/></xsl:comment>
                    <xsl:call-template name="termConcept">
                        <xsl:with-param name="table_root" select="./table" />
                        <xsl:with-param name="concept" select="./h2" />
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
            </xsl:choose>
            </ENTRIES>
        </INFO>
    </GLOSSARY>
</xsl:template>

<!-- Process a full item -->
<xsl:template name="termConcept">
    <xsl:param name="concept"/>
    <xsl:param name="table_root"/>

    <xsl:variable name="entryusedynalink_value" select="normalize-space(translate($table_root/tbody/tr[starts-with(th, $entryusedynalink_label)]/td[position() = $flag_value_colnum], $ucase, $lcase))"/>
    <xsl:variable name="casesensitive_value" select="normalize-space(translate($table_root/tbody/tr[starts-with(th, $entrycasesensitive_label)]/td[position() = $flag_value_colnum], $ucase, $lcase))"/>
    <xsl:variable name="fullmatch_value" select="normalize-space(translate($table_root/tbody/tr[starts-with(th, $fullmatch_label)]/td[position() = $flag_value_colnum], $ucase, $lcase))"/>

    <ENTRY>
        <CONCEPT>
            <xsl:value-of select="$concept"/>
        </CONCEPT>
        <DEFINITION>
            <xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes"/>
            <xsl:copy-of select="$table_root/tbody/tr[1]/td[1]/*"/>
            <xsl:value-of select="']]>'" disable-output-escaping="yes"/>
        </DEFINITION>

            <USEDYNALINK><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$entryusedynalink_value"/></xsl:call-template></USEDYNALINK>
            <CASESENSITIVE><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$casesensitive_value"/></xsl:call-template></CASESENSITIVE>
            <FULLMATCH><xsl:call-template name="convert_value_to_number"><xsl:with-param name="string_value" select="$fullmatch_value"/></xsl:call-template></FULLMATCH>

        <!-- Handle any categories that are included - all in one cell, comma-separated -->
        <xsl:variable name="keywords_row" select="$table_root/tbody/tr[starts-with(th, $keywords_label)]/td[position() = $tags_colnum]"/>
            <xsl:comment>keywords_label = <xsl:value-of select="$keywords_label"/></xsl:comment>
            <xsl:comment>keywords_row = <xsl:value-of select="$keywords_row"/></xsl:comment>
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
        <xsl:variable name="categories_row" select="$table_root/tbody/tr[starts-with(th, $categories_label)]/td[position() = $tags_colnum]"/>
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


<!-- Copy elements as is -->
<xsl:template match="*">
    <xsl:element name="{translate(name(), $ucase, $lcase)}">
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- copy attributes as is -->
<xsl:template match="@*">
    <xsl:attribute name="{translate(name(), $ucase, $lcase)}">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>


<!-- Handle text, removing text before tabs, deleting non-significant newlines between elements, etc. -->
<xsl:template name="convertUnicode">
    <xsl:param name="txt"/>

    <xsl:variable name="cloze_answer_sep_nl" select="concat($answer_separator_1, '&#x0a;')"/>
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
        <!-- If a | followed by newline, remove the newline -->
        <xsl:when test="contains($txt, $cloze_answer_sep_nl)">
            <xsl:value-of select="concat(substring-before($txt, $cloze_answer_sep_nl), $answer_separator_2)"/>

            <xsl:call-template name="convertUnicode">
                <xsl:with-param name="txt" select="substring-after($txt, $cloze_answer_sep_nl)"/>
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
    <xsl:if test="$moodleReleaseNumber &gt;= '20'">
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
    </xsl:if>

</xsl:template>

<xsl:template match="img" mode="moodle1image">
    <xsl:variable name="image_format" select="substring-after(substring-before(@src, ';'), '/')"/>
    <image>
        <xsl:choose>
        <xsl:when test="@alt and contains(@alt, $image_format)">
            <xsl:value-of select="@alt"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat('mq_image_', generate-id(), $image_format)"/>
        </xsl:otherwise>
        </xsl:choose>
    </image>
    <image_base64>
        <xsl:value-of select="substring-after(@src, ',')"/>
    </image_base64>
</xsl:template>

<xsl:template match="img" mode="moodle2pluginfile">
    <xsl:variable name="image_format" select="substring-after(substring-before(@src, ';'), '/')"/>

    <file name="{concat('mqimage_', generate-id(), '.', $image_format)}" encoding="base64">
        <xsl:value-of select="substring-after(@src, 'base64,')"/>
    </file>
</xsl:template>

<!-- Handle rich text content fields in a generic way -->
<xsl:template name="rich_text_content">
    <xsl:param name="content"/>

    <xsl:variable name="content_norm" select="normalize-space($content)"/>

    <text>
        <xsl:if test="$content_norm != '' and $content_norm != '&#160;' and $content_norm != '_'">
            <xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes"/>
            <xsl:apply-templates select="$content"/>
            <xsl:value-of select="']]>'" disable-output-escaping="yes"/>
        </xsl:if>
    </text>
    <!-- Handle embedded images: do nothing in Moodle 1.9, and move to file element in Moodle 2.x -->
    <xsl:if test="$moodleReleaseNumber &gt;= '20'">
        <xsl:apply-templates select="$content//img" mode="moodle2pluginfile"/>
    </xsl:if>

</xsl:template>
</xsl:stylesheet>
