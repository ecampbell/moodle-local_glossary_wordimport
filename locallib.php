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

require_once($CFG->dirroot . '/mod/glossary/lib.php');

use moodle_exception;
use \booktool_wordimport\wordconverter;

/**
 * Convert the Word file into Glossary XML and import it into the current glossary.
 *
 * @param string $wordfilename Word file to be processed into XML
 * @param stdClass $glossary Glossary to import into
 * @param context_module $context Current course context
 * @param bool $includecategories Import categories
 * @param bool $convertgifs Convert GIF images to PNG
 * @return array Array with 2 elements $importedentries and $rejectedentries
 */
function local_glossary_wordimport_import(string $wordfilename, stdClass $glossary, context_module $context,
                            bool $includecategories, bool $convertgifs) {
    global $CFG, $DB, $USER;

    // Overrides to default XSLT parameters used for conversion.
    $xsltparameters = array('pluginname' => 'local_glossary_wordimport',
            'heading1stylelevel' => 1, // Map "Heading 1" style to <h1> element.
            'imagehandling' => 'embedded' // Embed image data directly into the generated Moodle Glossary XML.
        );

    // Pass 1 - convert the Word file content into XHTML and an array of images.
    $imagesforzipping = array();
    $word2xml = new wordconverter($xsltparameters['pluginname']);
    $word2xml->set_heading1styleoffset($xsltparameters['heading1stylelevel']);
    $word2xml->set_imagehandling($xsltparameters['imagehandling']);
    $xhtmlcontent = $word2xml->import($wordfilename, $imagesforzipping, $convertgifs);
    $xhtmlcontent = $word2xml->htmlbody($xhtmlcontent);

    // Convert the returned array of images, if any, into a string.
    $imagestring = "";
    foreach ($imagesforzipping as $imagename => $imagedata) {
        $filetype = strtolower(pathinfo($imagename, PATHINFO_EXTENSION));
        $base64data = base64_encode($imagedata);
        $filedata = 'data:image/' . $filetype . ';base64,' . $base64data;
        // Embed the image name and data into the HTML.
        $imagestring .= '<img title="' . $imagename . '" src="' . $filedata . '"/>';
    }

    // Pass 2 - convert the initial XHTML into Moodle Glossary XML using localised table cell labels.
    // XSLT stylesheet to convert generic XHTML into Moodle Glossary XML.
    $importstylesheet = __DIR__ . DIRECTORY_SEPARATOR . "xhtml2glossary.xsl";

    $xmlcontainer = "<pass2Container>\n<glossary>" . $xhtmlcontent . "</glossary>\n" .
        "<imagesContainer>\n" . $imagestring . "</imagesContainer>\n" .
        local_glossary_wordimport_get_text_labels() . "\n</pass2Container>";
    $glossaryxml = $word2xml->xsltransform($xmlcontainer, $importstylesheet, $xsltparameters);
    $glossaryxml = str_replace('<GLOSSARY xmlns="http://www.w3.org/1999/xhtml"', '<GLOSSARY', $glossaryxml);
    // Could use debug_write here for debugging.

    // Convert the Glossary XML into an internal structure for importing into database.
    // This code is copied from /mod/glossary/import.php line 187 onwards.
    $importedentries = 0;
    $importedcats    = 0;
    $entriesrejected = 0;
    $rejections      = '';
    $glossarycontext = $context;

    if ($xml = glossary_read_imported_file($glossaryxml)) {
        $xmlentries = $xml['GLOSSARY']['#']['INFO'][0]['#']['ENTRIES'][0]['#']['ENTRY'];
        $sizeofxmlentries = is_array($xmlentries) ? count($xmlentries) : 0;
        for ($i = 0; $i < $sizeofxmlentries; $i++) {
            // Inserting the entries.
            $xmlentry = $xmlentries[$i];
            $newentry = new stdClass();
            $newentry->concept = trim($xmlentry['#']['CONCEPT'][0]['#']);
            $definition = $xmlentry['#']['DEFINITION'][0]['#'];
            if (!is_string($definition)) {
                throw new \moodle_exception(get_string('errorparsingxml', 'glossary'));
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

                if ($includecategories) {
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
                if (glossary_xml_import_files($xmlentry['#'], 'ATTACHMENTFILES', $glossarycontext->id, 'attachment',
                        $newentry->id)) {
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
        // Return the number of imported and rejected entries.
        return array($importedentries, $entriesrejected, $importedcats);
    } else {
        // Return special number to indicate parsing failure.
        return array(-1, -1, -1);
    }
}

/**
 * Export HTML pages to a Word file
 *
 * @param stdClass $glossary Glossary to export
 * @param string $exportformat Encoded or embedded images
 * @return string
 */
function local_glossary_wordimport_export(stdClass $glossary, string $exportformat) {
    global $CFG;

    // Export the current glossary into Glossary XML, then into XHTML, and write to a Word file.
    $glossaryxml = glossary_generate_export_file($glossary, null, 0); // Include categories.
    $glossaryxml = preg_replace('/<\?xml version="1.0" ([^>]*)>/', "", $glossaryxml);
    $moodlelabels = local_glossary_wordimport_get_text_labels();

    // Pass 1 - convert the Glossary XML into XHTML and an array of images.
    // Stylesheet to convert Moodle Glossary XML into generic XHTML.
    $exportstylesheet = __DIR__ . "/glossary2xhtml.xsl";
    // Assemble the glossary contents and localised labels to a single XML string for easier XSLT processing.
    $pass1input = "<pass1Container>\n" . $glossaryxml . $moodlelabels . "\n</pass1Container>";

    $word2xml = new wordconverter('local_glossary_wordimport');
    $glossaryhtml = $word2xml->xsltransform($pass1input, $exportstylesheet);
    $glossaryhtml = preg_replace('/<\?xml version="1.0" ([^>]*)>/', "", $glossaryhtml);

    // Pass 2 - convert XHTML into Word-compatible XHTML using localised table cell labels.
    $pass2input = "<html>\n" . $glossaryhtml .   "\n</html>";
    // Convert the XHTML string into a Word-compatible version, with images converted to Base64 data.
    $glossaryword = $word2xml->export($pass2input, 'glossary_wordimport', $moodlelabels, $exportformat);
    return $glossaryword;
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
        'glossary' => array('aliases', 'casesensitive', 'concept',  'categories', 'definition', 'displayformat',
                        'displayformatcontinuous', 'displayformatdefault', 'displayformatdictionary',
                        'displayformatencyclopedia', 'displayformatentrylist', 'displayformatfullwithauthor',
                        'displayformatfullwithoutauthor',
                        'entryusedynalink', 'fullmatch', 'glossarytype', 'linking',
                        'mainglossary', 'pluginname', 'secondaryglossary'),
        'local_glossary_wordimport' => array('wordinstructions_help', 'teacherentry'),
        'moodle' => array('description', 'no', 'yes', 'tags'),
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
