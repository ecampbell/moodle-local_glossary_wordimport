<?php
// This file is part of Moodle - http://moodle.org/
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Import/Export Microsoft Word files library.
 *
 * @package    local_glossary_wordimport
 * @copyright  2020 Eoin Campbell
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die;
// Development: turn on all debug messages and strict warnings.
define('DEBUG_WORDIMPORT', E_ALL);
// @codingStandardsIgnoreLine define('DEBUG_WORDIMPORT', 0);

require_once(__DIR__.'/lib.php');
require_once($CFG->dirroot.'/course/lib.php');


/**
 * Convert the Word file into a glossary XML string.
 *
 * A string containing Glossary XML data is returned
 *
 * @param string $wordfilename Word file to be processed into XML
 * @param stdObject $glossary Glossary object
 * @param stdObject $context Context
 * @return string glossary data in an internal structure
 */
function local_glossary_wordimport_import_word(string $wordfilename, stfObject $glossary, stdObject $context) {
    global $CFG;

    // Convert the Word file content into XHTML and an array of images.
    $imagesforzipping = array();
    $word2xml = new wordconverter();
    $word2xml->set_heading1styleOffset(1); // Map "Heading 1" styles to <h1>.
    $htmlcontent = $word2xml->import($wordfilename, $imagesforzipping);
    $htmlcontent = $word2xml->body_only($htmlcontent);

    // Split the single HTML file into multiple concepts based on h1 elements.
    $h1matches = null;
    // Grab title and contents of each 'Heading 1' section, which is mapped to h1.
    $h1matches = preg_split('#<h1>.*</h1>#isU', $htmlcontent);

    // Initialise the glossary metadata with general defaults.
    $glossxml = "<GLOSSARY><INFO><NAME>" . $glossary->name . "</NAME><INTRO></INTRO><INTROFORMAT>1</INTROFORMAT>" .
        "<ALLOWDUPLICATEDENTRIES>0</ALLOWDUPLICATEDENTRIES><DISPLAYFORMAT>dictionary</DISPLAYFORMAT>" .
        "<SHOWSPECIAL>1</SHOWSPECIAL><SHOWALPHABET>1</SHOWALPHABET><SHOWALL>1</SHOWALL><ALLOWCOMMENTS>0</ALLOWCOMMENTS>" .
        "<USEDYNALINK>1</USEDYNALINK><DEFAULTAPPROVAL>1</DEFAULTAPPROVAL><GLOBALGLOSSARY>0</GLOBALGLOSSARY>" .
        "<ENTBYPAGE>10</ENTBYPAGE><ENTRIES>";

    $trace = new html_progress_trace();
    // Create a separate Glossary entry for each concept in the content.
    for ($i = 1; $i < count($h1matches); $i++) {
        // Remove any tags from heading, as it prevents proper import of the chapter title.
        $concept = strip_tags($h1matches[1][$i - 1]);
        $definition = $h1matches[$i];

        // Remove the closing HTML markup from the last section.
        if ($i == (count($h1matches) - 1)) {
            $definition = substr($definition, 0, strpos($definition, "</div>"));
        }
        $trace->output("concept[$concept]($i) = " . $definition);
        $glossxml .= "<ENTRY><CONCEPT>" . $concept . "</CONCEPT><DEFINITION>" . $definition . "</DEFINITION>" .
            "<FORMAT>1</FORMAT><USEDYNALINK>1</USEDYNALINK><CASESENSITIVE>1</CASESENSITIVE><FULLMATCH>1</FULLMATCH>" .
            "<TEACHERENTRY>1</TEACHERENTRY>" .
            "</ENTRY>";
    }

    // Close the glossary XML.
    $glossxml .= "</ENTRIES></INFO></GLOSSARY>";
    // Parse the glossary XML into an internal structure.
    $glossdata = glossary_read_imported_file($glossxml);
    return $glossdata;
}

/**
 * Get all the text strings needed to fill in the Word file labels in a language-dependent way
 *
 * A string containing XML data, populated from the language folders, is returned
 *
 * @return string
 */
function local_glossary_wordimport_get_text_labels() {
    global $CFG;

    // Release-independent list of all strings required in the XSLT stylesheets for labels etc.
    $textstrings = array(
        'glossary' => array('concept', 'definition', 'entryusedynalink', 'entryusedynalink_help', 'fullmatch', 'fullmatch_help',
            'keywords', 'linking', 'pluginname', 'pluginnamesummary'),
        'moodle' => array('attachment', 'no', 'yes', 'tags'),
        );

    $expout = "<moodlelabels>\n";
    foreach ($textstrings as $typegroup => $grouparray) {
        foreach ($grouparray as $stringid) {
            $namestring = $typegroup . '_' . $stringid;
            // Clean up question type explanation, in case the default text has been overridden on the site.
            $cleantext = get_string($stringid, $typegroup);
            $expout .= '<data name="' . $namestring . '"><value>' . $cleantext . "</value></data>\n";
        }
    }
    $expout .= "</moodlelabels>";
    $expout = str_replace("<br>", "<br/>", $expout);

    return $expout;
}

/**
 * Import glossary data into the database
 *
 * This code is a stripped-down version of /mod/glossary/import.php copied from
 * @param string $glossdata Glossary data in internal structure
 * @return void
 */
function local_glossary_wordimport_process(string $glossdata) {
    global $CFG, $OUTPUT, $DB, $USER;

    $importedentries = 0;
    $importedcats    = 0;
    $entriesrejected = 0;
    $rejections      = '';
    $glossarycontext = $context;

    $xmlentries = $xml['GLOSSARY']['#']['INFO'][0]['#']['ENTRIES'][0]['#']['ENTRY'];
    $sizeofxmlentries = is_array($xmlentries) ? count($xmlentries) : 0;
    for ($i = 0; $i < $sizeofxmlentries; $i++) {
        // Inserting the entries.
        $xmlentry = $xmlentries[$i];
        $newentry = new stdClass();
        $newentry->concept = trim($xmlentry['#']['CONCEPT'][0]['#']);
        $definition = $xmlentry['#']['DEFINITION'][0]['#'];
        if (!is_string($definition)) {
            print_error('errorparsingxml', 'glossary');
        }
        $newentry->definition = trusttext_strip($definition);
        if (isset($xmlentry['#']['CASESENSITIVE'][0]['#'])) {
            $newentry->casesensitive = $xmlentry['#']['CASESENSITIVE'][0]['#'];
        } else {
            $newentry->casesensitive = $CFG->glossary_casesensitive;
        }

        $permissiongranted = 1;
        if ($newentry->concept and $newentry->definition) {
            if (!$glossary->allowduplicatedentries) {
                // Checking if the entry is valid (checking if it is duplicated when should not be).
                if ($newentry->casesensitive) {
                    $dupentry = $DB->record_exists_select('glossary_entries',
                                    'glossaryid = :glossaryid AND concept = :concept', array(
                                        'glossaryid' => $glossary->id,
                                        'concept'    => $newentry->concept));
                } else {
                    $dupentry = $DB->record_exists_select('glossary_entries',
                                    'glossaryid = :glossaryid AND LOWER(concept) = :concept', array(
                                        'glossaryid' => $glossary->id,
                                        'concept'    => core_text::strtolower($newentry->concept)));
                }
                if ($dupentry) {
                    $permissiongranted = 0;
                }
            }
        } else {
            $permissiongranted = 0;
        }
        if ($permissiongranted) {
            $newentry->glossaryid       = $glossary->id;
            $newentry->sourceglossaryid = 0;
            $newentry->approved         = 1;
            $newentry->userid           = $USER->id;
            $newentry->teacherentry     = 1;
            $newentry->definitionformat = $xmlentry['#']['FORMAT'][0]['#'];
            $newentry->timecreated      = time();
            $newentry->timemodified     = time();

            // Setting the default values if no values were passed.
            if (isset($xmlentry['#']['USEDYNALINK'][0]['#'])) {
                $newentry->usedynalink      = $xmlentry['#']['USEDYNALINK'][0]['#'];
            } else {
                $newentry->usedynalink      = $CFG->glossary_linkentries;
            }
            if (isset($xmlentry['#']['FULLMATCH'][0]['#'])) {
                $newentry->fullmatch        = $xmlentry['#']['FULLMATCH'][0]['#'];
            } else {
                $newentry->fullmatch      = $CFG->glossary_fullmatch;
            }

            $newentry->id = $DB->insert_record("glossary_entries", $newentry);
            $importedentries++;

            $xmlaliases = @$xmlentry['#']['ALIASES'][0]['#']['ALIAS']; // Ignore missing ALIASES.
            $sizeofxmlaliases = is_array($xmlaliases) ? count($xmlaliases) : 0;
            for ($k = 0; $k < $sizeofxmlaliases; $k++) {
                // Importing aliases.
                $xmlalias = $xmlaliases[$k];
                $aliasname = $xmlalias['#']['NAME'][0]['#'];

                if (!empty($aliasname)) {
                    $newalias = new stdClass();
                    $newalias->entryid = $newentry->id;
                    $newalias->alias = trim($aliasname);
                    $newalias->id = $DB->insert_record("glossary_alias", $newalias);
                }
            }

            if (!empty($data->catsincl)) {
                // If the categories must be imported...
                $xmlcats = @$xmlentry['#']['CATEGORIES'][0]['#']['CATEGORY']; // Ignore missing CATEGORIES.
                $sizeofxmlcats = is_array($xmlcats) ? count($xmlcats) : 0;
                for ($k = 0; $k < $sizeofxmlcats; $k++) {
                    $xmlcat = $xmlcats[$k];

                    $newcat = new stdClass();
                    $newcat->name = $xmlcat['#']['NAME'][0]['#'];
                    $newcat->usedynalink = $xmlcat['#']['USEDYNALINK'][0]['#'];
                    if (!$category = $DB->get_record("glossary_categories",
                            array("glossaryid" => $glossary->id, "name" => $newcat->name))) {
                        // Create the category if it does not exist.
                        $category = new stdClass();
                        $category->name = $newcat->name;
                        $category->glossaryid = $glossary->id;
                        $category->id = $DB->insert_record("glossary_categories", $category);
                        $importedcats++;
                    }
                    if ($category) {
                        // Inserting the new relation.
                        $entrycat = new stdClass();
                        $entrycat->entryid    = $newentry->id;
                        $entrycat->categoryid = $category->id;
                        $DB->insert_record("glossary_entries_categories", $entrycat);
                    }
                }
            }

            // Import files embedded in the entry text.
            glossary_xml_import_files($xmlentry['#'], 'ENTRYFILES', $glossarycontext->id, 'entry', $newentry->id);

            // Import files attached to the entry.
            if (glossary_xml_import_files($xmlentry['#'], 'ATTACHMENTFILES', $glossarycontext->id, 'attachment', $newentry->id)) {
                $DB->update_record("glossary_entries", array('id' => $newentry->id, 'attachment' => '1'));
            }

            // Import tags associated with the entry.
            if (core_tag_tag::is_enabled('mod_glossary', 'glossary_entries')) {
                $xmltags = @$xmlentry['#']['TAGS'][0]['#']['TAG']; // Ignore missing TAGS.
                $sizeofxmltags = is_array($xmltags) ? count($xmltags) : 0;
                for ($k = 0; $k < $sizeofxmltags; $k++) {
                    // Importing tags.
                    $tag = $xmltags[$k]['#'];
                    if (!empty($tag)) {
                        core_tag_tag::add_item_tag('mod_glossary', 'glossary_entries', $newentry->id, $glossarycontext, $tag);
                    }
                }
            }

        } else {
            $entriesrejected++;
            if ($newentry->concept and $newentry->definition) {
                // Add to exception report (duplicated entry)).
                $rejections .= "<tr><td>$newentry->concept</td>" .
                               "<td>" . get_string("duplicateentry", "glossary"). "</td></tr>";
            } else {
                // Add to exception report (no concept or definition found)).
                $rejections .= "<tr><td>---</td>" .
                               "<td>" . get_string("noconceptfound", "glossary"). "</td></tr>";
            }
        }
    }

    // Reset caches.
    \mod_glossary\local\concept_cache::reset_glossary($glossary);

}