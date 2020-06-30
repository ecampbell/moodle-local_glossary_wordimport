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
 * Import Word file into glossary.
 *
 * @package    local_glossary_wordimport
 * @copyright  2020 Eoin Campbell
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

require(__DIR__.'/../../config.php');
require_once(__DIR__.'/locallib.php');
require_once(__DIR__.'/import_form.php');

$cmid        = required_param('id', PARAM_INT);           // Course Module ID.
$action    = optional_param('action', 'import', PARAM_TEXT);  // Import or export.
$cat = optional_param('cat',0, PARAM_ALPHANUM); // Include categories.

// Security checks.
$cm = get_coursemodule_from_id('glossary', $cmid, 0, false, MUST_EXIST);
$course = $DB->get_record('course', array('id' => $cm->course), '*', MUST_EXIST);
$glossary = $DB->get_record('glossary', array('id' => $cm->instance), '*', MUST_EXIST);

require_course_login($course, true, $cm);

// Check import/export capabilities.
$context = context_module::instance($cmid);
require_capability('mod/glossary:manageentries', $context);
if ($action == 'import') {
    require_capability('mod/glossary:import', $context);
} else {
    require_capability('mod/glossary:export', $context);
}

// Set up page in case an import has been requested.
$PAGE->set_url('/local/glossary_wordimport/index.php', array('id' => $id, 'action' => $action));
$PAGE->set_title($glossary->name);
$PAGE->set_heading($course->fullname);
$mform = new local_glossary_wordimport_form(null, array('id' => $id, 'action' => $action));

// If data submitted, then process and store.
if ($mform->is_cancelled()) {
    // Form cancelled, go back.
    if (empty($glossary->id)) {
        redirect($CFG->wwwroot."/mod/glossary/view.php?id=$cm->id");
    }
} else if ($action == 'export') {
    // Export the current glossary into a Word file using the glossary name as the name.
    $filename = clean_filename(strip_tags(format_string($glossary->name)) . '.doc');
    $content = glossary_generate_export_file($glossary, NULL, $cat);

    send_file($content, $filename, 0, 0, true, true);
    // Read the title and introduction into a string, embedding images.
    $glossarytext = '<p class="MsoTitle">' . $glossary->name . "</p>\n";
    $glossarytext .= '<div class="chapter" id="intro">' . $glossary->intro;
    $glossarytext .= local_glossary_wordimport_base64_images($context->id, 'intro');
    $glossarytext .= "</div>\n";

    // Append all the chapters to the end of the string, again embedding images.
    foreach ($allchapters as $chapter) {
        $glossarytext .= '<div class="chapter" id="' . $chapter->id . '">';
        // Check if the chapter title is duplicated inside the content, and include it if not.
        if (!$chapter->subchapter and !strpos($chapter->content, "<h1")) {
            $glossarytext .= "<h1>" . $chapter->title . "</h1>\n";
        } else if ($chapter->subchapter and !strpos($chapter->content, "<h2")) {
            $glossarytext .= "<h2>" . $chapter->title . "</h2>\n";
        }
        $glossarytext .= $chapter->content;
        $glossarytext .= local_glossary_wordimport_base64_images($context->id, 'chapter', $chapter->id);
        $glossarytext .= "</div>\n";
    }
    $glossarytext = local_glossary_wordimport_export($glossarytext);
    $filename = clean_filename($glossary->name) . '.doc';
    send_file($glossarytext, $filename, 10, 0, true, array('filename' => $filename));
    die;
} else if ($data = $mform->get_data()) {
    // A Word file has been uploaded, so process it.
    echo $OUTPUT->header();
    echo $OUTPUT->heading($glossary->name);
    echo $OUTPUT->heading(get_string('importchapters', 'local_glossary_wordimport'), 3);

    // Should the Word file split into subchapters on 'Heading 2' styles?
    $splitonsubheadings = property_exists($data, 'splitonsubheadings');

    // Get the uploaded Word file and save it to the file system.
    $fs = get_file_storage();
    $draftid = file_get_submitted_draft_itemid('importfile');
    if (!$files = $fs->get_area_files(context_user::instance($USER->id)->id, 'user', 'draft', $draftid, 'id DESC', false)) {
        redirect($PAGE->url);
    }
    $file = reset($files);

    // Save the file to a temporary location on the file system.
    if (!$tmpfilename = $file->copy_content_to_temp()) {
        // Cannot save file.
        throw new moodle_exception(get_string('errorcreatingfile', 'error', $package->get_filename()));
    }

    // Convert the Word file content and import it into the book.
    local_glossary_wordimport_import_word($tmpfilename, $glossary, $context, $splitonsubheadings);

    echo $OUTPUT->continue_button(new moodle_url('/mod/book/view.php', array('id' => $id)));
    echo $OUTPUT->footer();
    die;
}
    echo $OUTPUT->header();
    echo $OUTPUT->heading($glossary->name);

    $mform->display();

    echo $OUTPUT->footer();
