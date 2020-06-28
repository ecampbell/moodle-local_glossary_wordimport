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
 * Import Microsoft Word file into glossary - settings.
 *
 * @package    local_glossary_wordimport
 * @copyright  2017 Eoin Campbell
 * @license   http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

if ($ADMIN->fulltree) {
    require_once($CFG->dirroot.'/mod/glossary/lib.php');

    // What HTML heading element should be used for the Word Heading 1 style?
    $name = new lang_string('wordimport', 'local_glossary_wordimport');
    $desc = new lang_string('wordimport_desc', 'local_glossary_wordimport');

    $setting = new admin_setting_configselect('booktool_wordimport/heading1stylelevel',
                                              $name,
                                              $desc,
                                              $default,
                                              $options);
    $settings->add($setting);

    $settings->add(new admin_setting_heading('glossary_normal_header', get_string('glossaryleveldefaultsettings', 'glossary'), ''));

    $settings->add(new admin_setting_configtext('glossary_entbypage', get_string('entbypage', 'glossary'),
                       get_string('entbypage', 'glossary'), 10, PARAM_INT));


    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_dupentries', get_string('allowduplicatedentries', 'glossary'),
                       get_string('cnfallowdupentries', 'glossary'), 0));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_allowcomments', get_string('allowcomments', 'glossary'),
                       get_string('cnfallowcomments', 'glossary'), 0));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_linkbydefault', get_string('usedynalink', 'glossary'),
                       get_string('cnflinkglossaries', 'glossary'), 1));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_defaultapproval', get_string('defaultapproval', 'glossary'),
                       get_string('cnfapprovalstatus', 'glossary'), 1));



    $settings->add(new admin_setting_heading('glossary_levdev_header', get_string('entryleveldefaultsettings', 'glossary'), ''));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_linkentries', get_string('usedynalink', 'glossary'),
                       get_string('cnflinkentry', 'glossary'), 0));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_casesensitive', get_string('casesensitive', 'glossary'),
                       get_string('cnfcasesensitive', 'glossary'), 0));

    $settings->add(new admin_setting_configcheckbox('local_glossary_wordimport_fullmatch', get_string('fullmatch', 'glossary'),
                       get_string('cnffullmatch', 'glossary'), 0));


    //Update and get available formats
    $recformats = glossary_get_available_formats();
    $formats = array();
    //Take names
    foreach ($recformats as $format) {
        $formats[$format->id] = get_string("displayformat$format->name", "glossary");
    }
    asort($formats);

    $str = '<table>';
    foreach ($formats as $formatid=>$formatname) {
        $recformat = $DB->get_record('glossary_formats', array('id'=>$formatid));
        $str .= '<tr>';
        $str .= '<td>' . $formatname . '</td>';
        $eicon = "<a title=\"".get_string("edit")."\" href=\"$CFG->wwwroot/mod/glossary/formats.php?id=$formatid&amp;mode=edit\">";
        $eicon .= $OUTPUT->pix_icon('t/edit', get_string('edit')). "</a>";
        if ( $recformat->visible ) {
            $vtitle = get_string("hide");
            $vicon  = "t/hide";
        } else {
            $vtitle = get_string("show");
            $vicon  = "t/show";
        }
        $url = "$CFG->wwwroot/mod/glossary/formats.php?id=$formatid&amp;mode=visible&amp;sesskey=".sesskey();
        $viconlink = "<a title=\"$vtitle\" href=\"$url\">";
        $viconlink .= $OUTPUT->pix_icon($vicon, $vtitle) . "</a>";

        $str .= '<td align="center">' . $eicon . '&nbsp;&nbsp;' . $viconlink . '</td>';
        $str .= '</tr>';
    }
    $str .= '</table>';

    $settings->add(new admin_setting_heading('glossary_formats_header', get_string('displayformatssetup', 'glossary'), $str));
}
