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
require_once('lib.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/course/modlib.php');

$id = required_param('id', PARAM_INT); // Course Module ID.
$action = optional_param('action', 'import', PARAM_TEXT);  // Import or export.
$cat = optional_param('cat', 0, PARAM_ALPHANUM); // Include categories.

// Security checks.
list ($course, $cm) = get_course_and_cm_from_cmid($id, 'glossary');
$glossary = $DB->get_record('glossary', array('id' => $cm->instance), '*', MUST_EXIST);
require_course_login($course, true, $cm);

// Check import/export capabilities.
$context = context_module::instance($id);
require_capability('mod/glossary:manageentries', $context);
if ($action == 'import') {
    require_capability('mod/glossary:import', $context);
} else {
    require_capability('mod/glossary:export', $context);
}

// Set up page in case an import has been requested.
$PAGE->set_url('/local/glossary_wordimport/index.php?id=', array('id' => $id));
$PAGE->set_title($glossary->name);
$PAGE->set_heading($course->fullname);

// Display the file upload form.
$mform = new local_glossary_wordimport_form(null, array('id' => $id, 'action' => $action));

// Do some debugging.
$trace = new html_progress_trace();

// If data submitted, then process and store.
if ($mform->is_cancelled()) {
    // Form cancelled, go back.
     $trace->output("Cancelled");
   if (empty($glossary->id)) {
        redirect($CFG->wwwroot . "/mod/glossary/view.php?id=$cm->id");
    }
} else if ($action == 'export') {
    // Export the current glossary into Glossary XML, then into XHTML, and write to a Word file.
    $glossarytext = local_glossary_wordimport_export($glossary, $context);
    $filename = clean_filename(strip_tags(format_string($glossary->name)) . '.doc');
    send_file($glossarytext, $filename, 10, 0, true, array('filename' => $filename));
    die;
} else if ($data = $mform->get_data()) {
    // A Word file has been uploaded, so process it.
    echo $OUTPUT->header();
    echo $OUTPUT->heading($glossary->name);
    echo $OUTPUT->heading(get_string('wordimport', 'local_glossary_wordimport'), 3);

    // Get the uploaded Word file and save it to the file system.
    $fs = get_file_storage();
    $draftid = file_get_submitted_draft_itemid('importfile');
    if (!$files = $fs->get_area_files(context_user::instance($USER->id)->id, 'user', 'draft', $draftid, 'id DESC', false)) {
        redirect($PAGE->url);
    }
    $file = reset($files);

    $trace->output("Saving Word file: " . $tmpfilename);
    // Save the file to a temporary location on the file system.
    if (!$tmpfilename = $file->copy_content_to_temp()) {
        // Cannot save file.
        throw new moodle_exception(get_string('errorcreatingfile', 'error', $package->get_filename()));
    }

    $trace->output("Processing Word file: " . $tmpfilename);
    $trace->finished();
    // Convert the Word file content and import it into the glossary.
    local_glossary_wordimport_import($tmpfilename, $glossary, $context);

    echo $OUTPUT->continue_button(new moodle_url('/mod/glossary/view.php', array('id' => $id)));
    echo $OUTPUT->footer();
    die;
}

echo $OUTPUT->header();
echo $OUTPUT->heading($glossary->name);
$mform->display();
echo $OUTPUT->footer();
