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
 * Import Word file language strings.
 *
 * @package    local_glossary_wordimport
 * @copyright  2016 Eoin Campbell
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();


$string['cannotopentempfile'] = 'Cannot open temporary file <b>{$a}</b>';
$string['exportglossary'] = 'Export to Microsoft Word';
$string['importglossary'] = 'Import from Microsoft Word';
$string['noglossary'] = 'No glossary found, so unable to export to Microsoft Word.';
$string['pluginname'] = 'Microsoft Word file Import/Export';
$string['privacy:metadata']      = 'The Microsoft Word file import/export tool for glossarys does not store personal data.';
$string['replaceglossary'] = 'Replace glossary';
$string['replaceglossary_help'] = 'Delete the current content of glossary before importing';
// Strings used in settings.
$string['settings'] = 'Word file import settings';
$string['stylesheetunavailable'] = 'XSLT Stylesheet <b>{$a}</b> is not available';
$string['transformationfailed'] = 'XSLT transformation failed (<b>{$a}</b>)';
$string['wordfile'] = 'Microsoft Word file';
$string['wordfile_help'] = 'Upload <i>.docx</i> file saved from Microsoft Word or LibreOffice';
$string['wordimport:export'] = 'Export Microsoft Word file';
$string['wordimport:import'] = 'Import Microsoft Word file';
$string['xsltunavailable'] = 'You need the XSLT library installed in PHP to save this Word file';

