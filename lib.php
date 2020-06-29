<?php
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

/**
 * Definition of the library class for the Microsoft Word (.docx) file conversion plugin.
 *
 * @package   local_glossary_wordimport
 * @copyright 2020 Eoin Campbell
 * @license   http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

global $CFG;
require_once($CFG->dirroot . '/lib/editor/atto/plugins/wordimport/xslemulatexslt.inc');
require_once($CFG->libdir . '/xmlize.php');

/**
 * General definitions
 */

/**
 * Add import/export commands to the Glossary settings block
 *
 * @param navigation_node $navigation The navigation node to extend
 * @param stdClass $course The course to object for the report
 * @param stdClass $context The context of the course
 */

function local_glossary_wordimport_extend_navigation_course($navigation, $course, $context) {
    global $PAGE;

    if (!$PAGE->cm || $PAGE->cm->modname !== 'glossary') {
        return;
    }

    $params = $PAGE->url->params();
    if (empty($params['id']) and empty($params['cmid'])) {
        return;
    }

    if (empty($PAGE->cm->context)) {
        $PAGE->cm->context = get_context_module::instance($PAGE->cm->instance);
    }

    if (!(has_capability('mod/glossary:manageentries', $PAGE->cm->context) and
        has_capability('mod/glossary:import', $PAGE->cm->context))) {
        return;
    }

    // Configure Import link, and pass in the current glossary in case the insert should happen here rather than at the end.
    if (has_capability('mod/glossary:import', $PAGE->cm->context)) {
        $url1 = new moodle_url('/local/glossary_wordimport/index.php', array('id' => $PAGE->cm->id, 'action' => 'import'));
        $navigation->add(get_string('wordimport', 'local_glossary_wordimport'), $url1, navigation_node::TYPE_SETTING, null, null,
                new pix_icon('f/document', '', 'moodle', array('class' => 'iconsmall', 'title' => '')));
    }

    // Configure Export links for current glossary.
    if (has_capability('mod/glossary:export', $PAGE->cm->context)) {
        $url2 = new moodle_url('/local/glossary_wordimport/index.php', array('id' => $PAGE->cm->id, 'action' => 'export'));
        $navigation->add(get_string('wordexport', 'local_glossary_wordimport'), $url2, navigation_node::TYPE_SETTING,
            null, null, new pix_icon('f/document', '', 'moodle', array('class' => 'iconsmall', 'title' => '')));
    }

}

