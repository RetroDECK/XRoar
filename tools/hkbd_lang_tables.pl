#!/usr/bin/perl -wT
use strict;

# Generate keyboard language tables for XRoar.  These will only be used if a)
# key symbol data cannot be queried, or b) the user explicitly specifies a
# keyboard language.
#
# Source data adapted from Xkb rules files.
#
# The approach to minimising table sizes here is very shonky.  For each
# language, only tables earlier in the list are considered for inheritence,
# purely to avoid recursive dependencies the easy way.  Might do it properly
# some time.

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my @langs = ( 'default', 'be', 'br', 'de', 'dk', 'es', 'fi', 'fr', 'fr_CA', 'gb', 'is', 'it', 'jp', 'nl', 'no', 'pl', 'pl_QWERTZ', 'se', 'us', 'dvorak' );

my %lang = ();

$lang{'base'} = [
	'Escape',	[ 'Escape' ],
	'F1',		[ 'F1' ],
	'F2',		[ 'F2' ],
	'F3',		[ 'F3' ],
	'F4',		[ 'F4' ],
	'F5',		[ 'F5' ],
	'F6',		[ 'F6' ],
	'F7',		[ 'F7' ],
	'F8',		[ 'F8' ],
	'F9',		[ 'F9' ],
	'F10',		[ 'F10' ],
	'F11',		[ 'F11' ],
	'F12',		[ 'F12' ],

	'grave',	[ 'grave',	'asciitilde',	'notsign',	'notsign' ],
	'BackSpace',	[ 'BackSpace' ],

	'Tab',		[ 'Tab' ],
	'backslash',	[ 'backslash', 'bar' ],

	'Caps_Lock',	[ 'Caps_Lock' ],
	'Return',	[ 'Return' ],

	'Shift_L',	[ 'Shift_L' ],
	'Shift_R',	[ 'Shift_R' ],

	'Control_L',	[ 'Control_L' ],
	'Alt_L',	[ 'Alt_L' ],
	'Super_L',	[ 'Super_L' ],
	'space',	[ 'space' ],
	'Super_R',	[ 'Super_R' ],
	'Alt_R',	[ 'Alt_R' ],
	'Control_R',	[ 'Control_R' ],
	'Application',	[ 'Menu' ],

	'Print',	[ 'Print' ],
	'Scroll_Lock',	[ 'Scroll_Lock' ],
	'Pause',	[ 'Pause' ],

	'Insert',	[ 'Insert' ],
	'Delete',	[ 'Delete' ],
	'Home',		[ 'Home' ],
	'End',		[ 'End' ],
	'Page_Up',	[ 'Page_Up' ],
	'Page_Down',	[ 'Page_Down' ],

	'Up',		[ 'Up' ],
	'Left',		[ 'Left' ],
	'Down',		[ 'Down' ],
	'Right',	[ 'Right' ],

	'Num_Lock',	[ 'Num_Lock' ],
	'KP_Divide',	[ 'KP_Divide' ],
	'KP_Multiply',	[ 'KP_Multiply' ],
	'KP_Subtract',	[ 'KP_Subtract' ],
	'KP_Add',	[ 'KP_Add' ],
	'KP_Enter',	[ 'KP_Enter' ],
	'KP_Decimal',	[ 'KP_Decimal' ],
	'KP_Equal',	[ 'KP_Equal' ],
	'KP_Separator',	[ 'KP_Separator' ],
	'KP_0',		[ 'KP_0' ],
	'KP_1',		[ 'KP_1' ],
	'KP_2',		[ 'KP_2' ],
	'KP_3',		[ 'KP_3' ],
	'KP_4',		[ 'KP_4' ],
	'KP_5',		[ 'KP_5' ],
	'KP_6',		[ 'KP_6' ],
	'KP_7',		[ 'KP_7' ],
	'KP_8',		[ 'KP_8' ],
	'KP_9',		[ 'KP_9' ],
];

$lang{'latin'} = [
	'1',		[ '1',		'exclam',	'onesuperior',	'exclamdown' ],
	'2',		[ '2',		'at',		'twosuperior',	'oneeighth' ],
	'3',		[ '3',		'numbersign',	'threesuperior','sterling' ],
	'4',		[ '4',		'dollar',	'onequarter',	'dollar' ],
	'5',		[ '5',		'percent',	'onehalf',	'threeeighths' ],
	'6',		[ '6',		'asciicircum',	'threequarters', 'fiveeighths' ],
	'7',		[ '7',		'ampersand',	'braceleft',	'seveneighths' ],
	'8',		[ '8',		'asterisk',	'bracketleft',	'trademark' ],
	'9',		[ '9',		'parenleft',	'bracketright',	'plusminus' ],
	'0',		[ '0',		'parenright',	'braceright',	'degree' ],
	'minus',	[ 'minus',	'underscore',	'backslash',	'questiondown' ],
	'equal',	[ 'equal',	'plus',		'dead_cedilla',	'dead_ogonek' ],

	'q',		[ 'q',		'Q',		'at',		'Greek_OMEGA' ],
	'w',		[ 'w',		'W',		'0x017f',	'section' ],
	'e',		[ 'e',		'E',		'e',		'E' ],
	'r',		[ 'r',		'R',		'paragraph',	'registered' ],
	't',		[ 't',		'T',		'tslash',	'Tslash' ],
	'y',		[ 'y',		'Y',		'leftarrow',	'yen' ],
	'u',		[ 'u',		'U',		'downarrow',	'uparrow' ],
	'i',		[ 'i',		'I',		'rightarrow',	'idotless' ],
	'o',		[ 'o',		'O',		'oslash',	'Oslash' ],
	'p',		[ 'p',		'P',		'thorn',	'THORN' ],
	'bracketleft',	[ 'bracketleft', 'braceleft',	'dead_diaeresis', 'dead_abovering' ],
	'bracketright',	[ 'bracketright', 'braceright',	'dead_tilde',	'dead_macron' ],

	'a',		[ 'a',		'A',		'ae',		'AE' ],
	's',		[ 's',		'S',		'ssharp',	'0x1e9e' ],
	'd',		[ 'd',		'D',		'eth',		'ETH' ],
	'f',		[ 'f',		'F',		'dstroke',	'ordfeminine' ],
	'g',		[ 'g',		'G',		'eng',		'ENG' ],
	'h',		[ 'h',		'H',		'hstroke',	'Hstroke' ],
	'j',		[ 'j',		'J',		'dead_hook',	'dead_horn' ],
	'k',		[ 'k',		'K',		'kra',		'ampersand' ],
	'l',		[ 'l',		'L',		'lstroke',	'Lstroke' ],
	'semicolon',	[ 'semicolon',	'colon',	'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'apostrophe',	'quotedbl',	'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'grave',	'asciitilde',	'notsign',	'notsign' ],

	'backslash_nonUS', [ 'backslash', 'bar',	'dead_grave',	'dead_breve' ],
	'z',		[ 'z',		'Z',		'guillemetleft',  'less' ],
	'x',		[ 'x',		'X',		'guillemetright', 'greater' ],
	'c',		[ 'c',		'C',		'cent',		'copyright' ],
	'v',		[ 'v',		'V', 'doublelowquotemark',   'singlelowquotemark' ],
	'b',		[ 'b',		'B', 'leftdoublequotemark',  'leftsinglequotemark' ],
	'n',		[ 'n',		'N', 'rightdoublequotemark', 'rightsinglequotemark' ],
	'm',		[ 'm',		'M',		'mu',		'masculine' ],
	'comma',	[ 'comma',	'less',		'0x2022',	'multiply' ],
	'period',	[ 'period',	'greater',	'periodcentered', 'division' ],
	'slash',	[ 'slash',	'question',	'dead_belowdot',  'dead_abovedot' ],
];

$lang{'latin_type2'} = [
	'!lang', 'latin',

	'1',		[ '1',		'exclam',	'exclamdown',	'onesuperior' ],
	'2',		[ '2',		'quotedbl',	'at',		'twosuperior' ],
	'3',		[ '3',		'numbersign',	'sterling',	'threesuperior' ],
	'4',		[ '4',		'currency',	'dollar',	'onequarter' ],
	'5',		[ '5',		'percent',	'onehalf',	'cent' ],
	'6',		[ '6',		'ampersand',	'yen',		'fiveeighths' ],
	'7',		[ '7',		'slash',	'braceleft',	'division' ],
	'8',		[ '8',		'parenleft',	'bracketleft',	'guillemetleft' ],
	'9',		[ '9',		'parenright',	'bracketright',	'guillemetright' ],
	'0',		[ '0',		'equal',	'braceright',	'degree' ],

	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],
	'r',		[ 'r',		'R',		'registered',	'registered' ],
	't',		[ 't',		'T',		'thorn',	'THORN' ],
	'o',		[ 'o',		'O',		'oe',		'OE' ],
	'bracketleft',	[ 'aring',	'Aring',	'dead_diaeresis', 'dead_abovering' ],
	'bracketright',	[ 'dead_diaeresis', 'dead_circumflex', 'dead_tilde', 'dead_caron' ],

	'a',		[ 'a',		'A',		'ordfeminine',	'masculine' ],

	'c',		[ 'c',		'C',		'copyright',	'copyright' ],
	'comma',	[ 'comma',	'semicolon',	'dead_cedilla',	'dead_ogonek' ],
	'period',	[ 'period',	'colon',	'periodcentered', 'dead_abovedot' ],
	'slash',	[ 'minus',	'underscore',	'dead_belowdot', 'dead_abovedot' ],
];

$lang{'latin_type3'} = [
	'!lang', 'latin',

	'q',		[ 'q',		'Q',		'backslash',	'Greek_OMEGA' ],
	'w',		[ 'w',		'W',		'bar',		'section' ],
	'y',		[ 'z',		'Z',		'leftarrow',	'yen' ],

	'f',		[ 'f',		'F',		'bracketleft',	'ordfeminine' ],
	'g',		[ 'g',		'G',		'bracketright',	'ENG' ],
	'k',		[ 'k',		'K',		'lstroke',	'ampersand' ],

	'z',		[ 'y',		'Y',		'guillemetleft', 'less' ],
	'v',		[ 'v',		'V',		'at',		'grave' ],
	'b',		[ 'b',		'B',		'braceleft',	'apostrophe' ],
	'n',		[ 'n',		'N',		'braceright',	'acute' ],
	'm',		[ 'm',		'M',		'section',	'masculine' ],
	'comma',	[ 'comma',	'semicolon',	'less',		'multiply' ],
	'period',	[ 'period',	'colon',	'greater',	'division' ],
];

$lang{'latin_type4'} = [
	'!lang', 'latin',

	'2',		[ '2',		'quotedbl',	'at',		'oneeighth' ],
	'6',		[ '6',		'ampersand',	'notsign',	'fiveeighths' ],
	'7',		[ '7',		'slash',	'braceleft',	'seveneighths' ],
	'8',		[ '8',		'parenleft',	'bracketleft',	'trademark' ],
	'9',		[ '9',		'parenright',	'bracketright',	'plusminus' ],
	'0',		[ '0',		'equal',	'braceright',	'degree' ],

	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],

	'comma',	[ 'comma',	'semicolon',	'0x2022',	'multiply' ],
	'period',	[ 'period',	'colon',	'periodcentered', 'division' ],
	'slash',	[ 'minus',	'underscore',	'dead_belowdot', 'dead_abovedot' ],
];

$lang{'default'} = [
	'!text', 'Default symbol table',
	'!lang', 'base',
	'!lang', 'latin',
];

$lang{'be'} = [
	'!text', 'be, Belgian, AZERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'twosuperior', 'threesuperior', 'notsign',	'notsign' ],
	'1',		[ 'ampersand',	'1',		'bar',		'exclamdown' ],
	'2',		[ 'eacute',	'2',		'at',		'oneeighth' ],
	'3',		[ 'quotedbl',	'3',		'numbersign',	'sterling' ],
	'4',		[ 'apostrophe',	'4',		'onequarter',	'dollar' ],
	'5',		[ 'parenleft',	'5',		'onehalf',	'threeeighths' ],
	'6',		[ 'section',	'6',		'asciicircum',	'fiveeighths' ],
	'7',		[ 'egrave',	'7',		'braceleft',	'seveneighths' ],
	'8',		[ 'exclam',	'8',		'bracketleft',	'trademark' ],
	'9',		[ 'ccedilla',	'9',		'braceleft',	'plusminus' ],
	'0',		[ 'agrave',	'0',		'braceright',		'degree' ],
	'minus',	[ 'parenright',	'degree',	'backslash',	'questiondown' ],
	'equal',	[ 'minus',	'underscore',	'dead_cedilla',	'dead_ogonek' ],

	'q',		[ 'a',		'A',		'ae',		'AE' ],
	'w',		[ 'z',		'Z',		'guillemetleft', 'less' ],
	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],
	'o',		[ 'o',		'O',		'oe',		'OE' ],
	'bracketleft',	[ 'dead_circumflex', 'dead_diaeresis', 'bracketleft', 'dead_abovering' ],
	'bracketright',	[ 'dollar',	'asterisk',	'bracketright',	'dead_macron' ],

	'a',		[ 'q',		'Q',		'at',		'Greek_OMEGA' ],
	'semicolon',	[ 'm',		'M',		'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'ugrave',	'percent',	'dead_acute',	'dead_caron' ],
	'numbersign_nonUS', [ 'mu',	'sterling',	'dead_grave',	'dead_breve' ],

	'backslash_nonUS', [ 'less',	'greater',	'backslash',	'backslash' ],
	'z',		[ 'w',		'W',		'guillemetleft', 'less' ],
	'm',		[ 'comma',	'question',	'dead_cedilla',	'masculine' ],
	'comma',	[ 'semicolon',	'period',	'0x2022',	'multiply' ],
	'period',	[ 'colon',	'slash',	'periodcentered', 'division' ],
	'slash',	[ 'equal',	'plus',		'dead_tilde',	'dead_abovedot' ],
];

$lang{'br'} = [
	'!text', 'br, Brazil, QWERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'apostrophe',	'quotedbl',	'notsign',	'notsign' ],
	'2',		[ '2',		'at',		'twosuperior',	'onehalf' ],
	'3',		[ '3',		'numbersign',	'threesuperior', 'threequarters' ],
	'4',		[ '4',		'dollar',	'sterling',	'onequarter' ],
	'5',		[ '5',		'percent',	'cent',		'threeeighths' ],
	'6',		[ '6',		'dead_diaeresis', 'notsign',	'diaeresis' ],
	'equal',	[ 'equal',	'plus',		'section',	'dead_ogonek' ],

	'q',		[ 'q',		'Q',		'slash',	'slash' ],
	'w',		[ 'w',		'W',		'question',	'question' ],
	'e',		[ 'e',		'E',		'degree',	'degree' ],
	'r',		[ 'r',		'R',		'registered',	'registered' ],
	'bracketleft',	[ 'dead_acute',	'dead_grave',	'acute',	'grave' ],
	'bracketright',	[ 'bracketleft', 'braceleft',	'ordfeminine',	'dead_macron' ],

	'semicolon',	[ 'ccedilla',	'Ccedilla',	'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'dead_tilde',	'dead_circumflex', 'asciitilde', 'asciicircum' ],
	'numbersign_nonUS', [ 'bracketright', 'braceright', 'masculine', 'masculine' ],

	'backslash_nonUS', [ 'backslash', 'bar',	'dead_caron',	'dead_breve' ],
	'c',		[ 'c',		'C',		'copyright',	'copyright' ],
	'm',		[ 'm',		'M',		'mu',		'mu' ],
	'slash',	[ 'semicolon',	'colon',	'dead_belowdot', 'dead_abovedot' ],
	'International1', [ 'slash',	'question',	'degree',	'questiondown' ],
];

$lang{'de'} = [
	'!text', 'de, German, QWERTZ',
	'!lang', 'base',
	'!lang', 'latin_type4',

	'grave',	[ 'dead_circumflex', 'degree',	'0x2032',	'0x2033' ],
	'2',		[ '2',		'quotedbl',	'twosuperior',	'oneeighth' ],
	'3',		[ '3',		'section',	'threesuperior','sterling' ],
	'4',		[ '4',		'dollar',	'onequarter',	'currency' ],
	'minus',	[ 'ssharp',	'question',	'backslash',	'questiondown' ],
	'equal',	[ 'dead_acute',	'dead_grave',	'dead_cedilla',	'dead_ogonek' ],

	'e',		[ 'e',		'E',		'EuroSign',	'EuroSign' ],
	'y',		[ 'z',		'Z',		'leftarrow',	'yen' ],
	'bracketleft',	[ 'udiaeresis', 'Udiaeresis',	'dead_diaeresis', 'dead_abovering' ],
	'bracketright',	[ 'plus',	'asterisk',	'asciitilde',	'macron' ],

	's',		[ 's',		'S',		'0x017f',	'0x1e9e' ],
	'j',		[ 'j',		'J',		'dead_belowdot', 'dead_abovedot' ],
	'semicolon',	[ 'odiaeresis',	'Odiaeresis',	'dead_doubleacute', 'dead_belowdot' ],
	'apostrophe',	[ 'adiaeresis',	'Adiaeresis',	'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'numbersign', 'apostrophe', 'rightsinglequotemark', 'dead_breve' ],

	'backslash_nonUS', [ 'less',	'greater',	'bar',		'dead_belowmacron' ],
	'z',		[ 'y',		'Y',		'guillemetright', '0x203a' ],
	'x',		[ 'x',		'X',		'guillemetleft', '0x2039' ],
	'comma',	[ 'comma',	'semicolon',	'periodcentered', 'multiply' ],
	'period',	[ 'period',	'colon',	'0x2026',	'division' ],
	'slash',	[ 'minus',	'underscore',	'endash',	'emdash' ],
];

$lang{'dk'} = [
	'!text', 'dk, Danish, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type2',

	'grave',	[ 'onehalf',	'section',	'threequarters', 'paragraph' ],
	'minus',	[ 'plus',	'question',	'plusminus',	'questiondown' ],
	'equal',	[ 'dead_acute',	'dead_grave',	'bar',		'brokenbar' ],

	'semicolon',	[ 'ae',		'AE',		'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'oslash',	'Oslash',	'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'apostrophe', 'asterisk',	'dead_doubleacute', 'multiply' ],

	'backslash_nonUS', [ 'less',	'greater',	'backslash',	'notsign' ],
];

$lang{'es'} = [
	'!text', 'es, Spanish, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type4',

	'grave',	[ 'masculine',	'ordfeminine',	'backslash',	'backslash' ],
	'1',		[ '1',		'exclam',	'bar',		'exclamdown' ],
	'3',		[ '3',		'periodcentered', 'numbersign',	'sterling' ],
	'4',		[ '4',		'dollar',	'asciitilde',	'dollar' ],
	'minus',	[ 'apostrophe',	'question',	'backslash',	'questiondown' ],
	'equal',	[ 'exclamdown',	'questiondown',	'dead_cedilla',	'dead_ogonek' ],

	'bracketleft',	[ 'dead_grave',	'dead_circumflex', 'bracketleft', 'dead_abovering' ],
	'bracketright',	[ 'plus',	'asterisk',	'bracketright',	'dead_macron' ],

	'semicolon',	[ 'ntilde',	'Ntilde',	'dead_tilde',	'dead_doubleacute' ],
	'apostrophe',	[ 'dead_acute',	'dead_diaeresis', 'braceleft',	'dead_caron' ],
	'numbersign_nonUS', [ 'ccedilla', 'Ccedilla',	'braceright',	'dead_breve' ],
];

$lang{'fi'} = [
	'!text', 'fi, Finnish, QWERTY',
	'!lang', 'base',

	'grave',	[ 'section',	'onehalf',	'dead_stroke',	'None' ],
	'1',		[ '1',		'exclam',	'None',		'exclamdown' ],
	'2',		[ '2',		'quotedbl',	'at',		'rightdoublequotemark' ],
	'3',		[ '3',		'numbersign',	'sterling',	'guillemetright' ],
	'4',		[ '4',		'currency',	'dollar',	'guillemetleft' ],
	'5',		[ '5',		'percent',	'permille',	'leftdoublequotemark' ],
	'6',		[ '6',		'ampersand',	'singlelowquotemark', 'doublelowquotemark' ],
	'7',		[ '7',		'slash',	'braceleft',	'None' ],
	'8',		[ '8',		'parenleft',	'bracketleft',	'less' ],
	'9',		[ '9',		'parenright',	'bracketright',	'greater' ],
	'0',		[ '0',		'equal',	'braceright',	'degree' ],
	'minus',	[ 'plus',	'question',	'backslash',	'questiondown' ],
	'equal',	[ 'dead_acute',	'dead_grave',	'dead_cedilla',	'dead_ogonek' ],

	'q',		[ 'q',		'Q',		'q',		'Q' ],
	'w',		[ 'w',		'W',		'w',		'W' ],
	'e',		[ 'e',		'E',		'EuroSign',	'None' ],
	'r',		[ 'r',		'R',		'r',		'R' ],
	't',		[ 't',		'T',		'thorn',	'THORN' ],
	'y',		[ 'y',		'Y',		'y',		'Y' ],
	'u',		[ 'u',		'U',		'u',		'U' ],
	'i',		[ 'i',		'I',		'idotless',	'bar' ],
	'o',		[ 'o',		'O',		'oe',		'OE' ],
	'p',		[ 'p',		'P',		'dead_horn',	'dead_hook' ],
	'bracketleft',	[ 'aring',	'Aring',	'dead_doubleacute', 'dead_abovering' ],
	'bracketright',	[ 'dead_diaeresis', 'dead_circumflex', 'dead_tilde', 'dead_macron' ],

	'a',		[ 'a',		'A',		'schwa',	'SCHWA' ],
	's',		[ 's',		'S',		'ssharp',	'0x1e9e' ],
	'd',		[ 'd',		'D',		'eth',		'ETH' ],
	'f',		[ 'f',		'F',		'f',		'F' ],
	'g',		[ 'g',		'G',		'g',		'G' ],
	'h',		[ 'h',		'H',		'h',		'H' ],
	'j',		[ 'j',		'J',		'j',		'J' ],
	'k',		[ 'k',		'K',		'kra',		'dead_greek' ],
	'l',		[ 'l',		'L',		'dead_stroke',	'dead_currency' ],
	'semicolon',	[ 'odiaeresis',	'Odiaeresis',	'oslash',	'Oslash' ],
	'apostrophe',	[ 'adiaeresis',	'Adiaeresis',	'ae',		'AE' ],
	'numbersign_nonUS', [ 'apostrophe', 'asterisk',	'dead_caron',	'dead_breve' ],

	'backslash_nonUS', [ 'less',	'greater',	'bar',		'None' ],
	'z',		[ 'z',		'Z',		'ezh',		'EZH' ],
	'x',		[ 'x',		'X',		'multiply',	'periodcentered' ],
	'c',		[ 'c',		'C',		'c',		'C' ],
	'v',		[ 'v',		'V',		'v',		'V' ],
	'b',		[ 'b',		'B',		'b',		'B' ],
	'n',		[ 'n',		'N',		'eng',		'ENG' ],
	'm',		[ 'm',		'M',		'mu',		'emdash' ],
	'comma',	[ 'comma',	'semicolon',	'rightsinglequotemark', 'leftsinglequotemark' ],
	'period',	[ 'period',	'colon',	'dead_belowdot', 'dead_abovedot' ],
	'slash',	[ 'minus',	'underscore',	'endash',	'dead_belowcomma' ],

	'space',	[ 'space',	'space',	'space',	'0x202f' ],
];

$lang{'fr'} = [
	'!text', 'fr, French, AZERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'twosuperior', 'asciitilde',	'notsign',	'notsign' ],
	'1',		[ 'ampersand',	'1',		'onesuperior',	'exclamdown' ],
	'2',		[ 'eacute',	'2',		'asciitilde',	'oneeighth' ],
	'3',		[ 'quotedbl',	'3',		'numbersign',	'sterling' ],
	'4',		[ 'apostrophe',	'4',		'braceleft',	'dollar' ],
	'5',		[ 'parenleft',	'5',		'bracketleft',	'threeeighths' ],
	'6',		[ 'minus',	'6',		'bar',		'fiveeighths' ],
	'7',		[ 'egrave',	'7',		'grave',	'seveneighths' ],
	'8',		[ 'underscore',	'8',		'backslash',	'trademark' ],
	'9',		[ 'ccedilla',	'9',		'asciicircum',	'plusminus' ],
	'0',		[ 'agrave',	'0',		'at',		'degree' ],
	'minus',	[ 'parenright',	'degree',	'bracketright',	'questiondown' ],
	'equal',	[ 'equal',	'plus',		'braceright',	'dead_ogonek' ],

	'q',		[ 'a',		'A',		'ae',		'AE' ],
	'w',		[ 'z',		'Z',		'guillemetleft', 'less' ],
	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],
	'bracketleft',	[ 'dead_circumflex', 'dead_diaeresis', 'dead_diaeresis', 'dead_abovering' ],
	'bracketright',	[ 'dollar',	'sterling',	'currency',	'dead_macron' ],

	'a',		[ 'q',		'Q',		'at',		'Greek_OMEGA' ],
	'semicolon',	[ 'm',		'M',		'mu',		'masculine' ],
	'apostrophe',	[ 'ugrave',	'percent',	'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'asterisk',	'mu',	'dead_grave',	'dead_breve' ],

	'z',		[ 'w',		'W',		'lstroke',	'Lstroke' ],
	'm',		[ 'comma',	'question',	'dead_acute',	'dead_doubleacute' ],
	'comma',	[ 'semicolon',	'period',	'0x2022',	'multiply' ],
	'period',	[ 'colon',	'slash',	'periodcentered',  'division' ],
	'slash',	[ 'exclam',	'section',	'dead_belowdot',   'dead_abovedot' ],
];

$lang{'fr_CA'} = [
	'!text', 'fr_CA, French Canadian, QWERTY',
	'!lang', 'base',

	'grave',	[ 'numbersign',	'bar',		'backslash' ],
	'1',		[ '1',		'exclam',	'plusminus' ],
	'2',		[ '2',		'quotedbl',	'at' ],
	'3',		[ '3',		'slash',	'sterling' ],
	'4',		[ '4',		'dollar',	'cent' ],
	'5',		[ '5',		'percent',	'currency' ],
	'6',		[ '6',		'question',	'notsign' ],
	'7',		[ '7',		'ampersand',	'brokenbar' ],
	'8',		[ '8',		'asterisk',	'twosuperior' ],
	'9',		[ '9',		'parenleft',	'threesuperior' ],
	'0',		[ '0',		'parenright',	'onequarter' ],
	'minus',	[ 'minus',	'underscore',	'onehalf' ],
	'equal',	[ 'equal',	'plus',		'threequarters' ],

	'q',		[ 'q',		'Q' ],
	'w',		[ 'w',		'W' ],
	'e',		[ 'e',		'E',	'EuroSign' ],
	'r',		[ 'r',		'R' ],
	't',		[ 't',		'T' ],
	'y',		[ 'y',		'Y',	'yen' ],
	'u',		[ 'u',		'U' ],
	'i',		[ 'i',		'I' ],
	'o',		[ 'o',		'O',	'section' ],
	'p',		[ 'p',		'P',	'paragraph' ],
	'bracketleft',	[ 'dead_circumflex', 'dead_circumflex',	'bracketleft' ],
	'bracketright',	[ 'dead_cedilla', 'dead_diaeresis',	'bracketright' ],

	'a',		[ 'a',		'A' ],
	's',		[ 's',		'S' ],
	'd',		[ 'd',		'D' ],
	'f',		[ 'f',		'F' ],
	'g',		[ 'g',		'G' ],
	'h',		[ 'h',		'H' ],
	'j',		[ 'j',		'J' ],
	'k',		[ 'k',		'K' ],
	'l',		[ 'l',		'L' ],
	'semicolon',	[ 'semicolon',	'colon',	'asciitilde' ],
	'apostrophe',	[ 'dead_grave',	'dead_grave',	'braceleft' ],
	'numbersign_nonUS', [ 'less',	'greater',	'braceright' ],

	'backslash_nonUS', [ 'guillemetleft', 'guillemetright', 'degree' ],
	'z',		[ 'z',		'Z' ],
	'x',		[ 'x',		'X' ],
	'c',		[ 'c',		'C' ],
	'v',		[ 'v',		'V' ],
	'b',		[ 'b',		'B' ],
	'n',		[ 'n',		'N' ],
	'm',		[ 'm',		'M',		'mu' ],
	'comma',	[ 'comma',	'apostrophe',	'macron' ],
	'period',	[ 'period',	'period',	'hyphen' ],
	'slash',	[ 'eacute',	'Eacute',	'dead_acute' ],

	'space',	[ 'space',	'space',	'nobreakspace' ],
];

$lang{'gb'} = [
	'!text', 'gb, Great Britain, QWERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'grave',	'notsign',	'bar',		'bar' ],
	'2',		[ '2',		'quotedbl',	'twosuperior',	'oneeighth' ],
	'3',		[ '3',		'sterling',	'threesuperior', 'sterling' ],
	'4',		[ '4',		'dollar',	'EuroSign',	'onequarter' ],

	'apostrophe',	[ 'apostrophe',	'at',		'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'numbersign', 'asciitilde', 'dead_grave',	'dead_breve' ],

	'backslash_nonUS', [ 'backslash', 'bar',	'bar',		'brokenbar' ],
];

$lang{'is'} = [
	'!text', 'is, Icelandic, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type4',

	'grave',	[ 'dead_abovering', 'dead_diaeresis', 'notsign', 'hyphen' ],
	'2',		[ '2',		'quotedbl',	'twosuperior',	'oneeighth' ],
	'4',		[ '4',		'dollar',	'onequarter',	'currency' ],
	'minus',	[ 'odiaeresis',	'Odiaeresis',	'backslash',	'questiondown' ],
	'equal',	[ 'minus',	'underscore',	'dead_cedilla',	'dead_ogonek' ],

	'p',		[ 'p',		'P',		'bar',		'Greek_pi' ],
	'bracketleft',	[ 'eth',	'ETH',		'dead_diaeresis', 'dead_abovering' ],
	'bracketright',	[ 'apostrophe',	'question',	'asciitilde',	'dead_macron' ],

	'd',		[ 'd',		'D',		'0x201e',	'0x201c' ],
	'semicolon',	[ 'ae',		'AE',		'asciicircum',	'dead_doubleacute' ],
	'apostrophe',	[ 'dead_acute',	'dead_acute',	'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'plus',	'asterisk',	'grave',	'dead_breve' ],

	'slash',	[ 'thorn',	'THORN',	'dead_belowdot', 'dead_abovedot' ],
];

$lang{'it'} = [
	'!text', 'it, Italian, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type4',

	'grave',	[ 'backslash',	'bar',		'notsign',	'brokenbar' ],
	'2',		[ '2',		'quotedbl',	'twosuperior',	'dead_doubleacute' ],
	'3',		[ '3',		'sterling',	'threesuperior', 'dead_tilde' ],
	'4',		[ '4',		'dollar',	'onequarter',	'oneeighth' ],
	'0',		[ '0',		'equal',	'braceright',	'dead_ogonek' ],
	'minus',	[ 'apostrophe',	'question',	'grave',	'questiondown' ],
	'equal',	[ 'igrave',	'asciicircum',	'asciitilde',	'dead_circumflex' ],

	'bracketleft',	[ 'egrave',	'eacute',	'bracketleft',	'braceleft' ],
	'bracketright',	[ 'plus',	'asterisk',	'bracketright',	'braceright' ],

	'semicolon',	[ 'ograve',	'ccedilla',	'at',		'dead_cedilla' ],
	'apostrophe',	[ 'agrave',	'degree',	'numbersign',	'dead_abovering' ],
	'numbersign_nonUS', [ 'ugrave',	'section',	'dead_grave',	'dead_breve' ],

	'backslash_nonUS', [ 'less',	'greater',	'guillemetleft', 'guillemetright' ],
	'v',		[ 'v',		'V',		'leftdoublequotemark', 'leftsinglequotemark' ],
	'b',		[ 'b',		'B',		'rightdoublequotemark', 'rightsinglequotemark' ],
	'n',		[ 'n',		'N',		'ntilde',		'Ntilde' ],
	'comma',	[ 'comma',	'semicolon',	'dead_acute',	'multiply' ],
	'period',	[ 'period',	'colon',	'periodcentered', 'dead_diaeresis' ],
	'slash',	[ 'minus',	'underscore',	'dead_macron',	'division' ],
];

$lang{'jp'} = [
	'!text', 'jp, Japanese, QWERTY (JIS)',
	'!lang', 'base',

	'Lang5',	[ 'Zenkaku_Hankaku', 'Kanji' ],
	'1',		[ '1',		'exclam' ],
	'2',		[ '2',		'quotedbl' ],
	'3',		[ '3',		'numbersign' ],
	'4',		[ '4',		'dollar' ],
	'5',		[ '5',		'percent' ],
	'6',		[ '6',		'ampersand' ],
	'7',		[ '7',		'apostrophe' ],
	'8',		[ '8',		'parenleft' ],
	'9',		[ '9',		'parenright' ],
	'0',		[ '0' ],
	'minus',	[ 'minus',	'equal' ],
	'equal',	[ 'asciicircum', 'asciitilde' ],
	'International3', [ 'yen',	'bar' ],

	'q',		[ 'q',		'Q' ],
	'w',		[ 'w',		'W' ],
	'e',		[ 'e',		'E' ],
	'r',		[ 'r',		'R' ],
	't',		[ 't',		'T' ],
	'y',		[ 'y',		'Y' ],
	'u',		[ 'u',		'U' ],
	'i',		[ 'i',		'I' ],
	'o',		[ 'o',		'O' ],
	'p',		[ 'p',		'P' ],
	'bracketleft',	[ 'at',		'grave' ],
	'bracketright',	[ 'bracketleft', 'braceleft' ],

	'Caps_Lock',	[ 'Eisu_toggle', 'Caps_Lock' ],
	'a',		[ 'a',		'A' ],
	's',		[ 's',		'S' ],
	'd',		[ 'd',		'D' ],
	'f',		[ 'f',		'F' ],
	'g',		[ 'g',		'G' ],
	'h',		[ 'h',		'H' ],
	'j',		[ 'j',		'J' ],
	'k',		[ 'k',		'K' ],
	'l',		[ 'l',		'L' ],
	'semicolon',	[ 'semicolon',	'plus' ],
	'apostrophe',	[ 'colon',	'asterisk' ],
	'numbersign_nonUS', [ 'bracketright', 'braceright' ],

	'z',		[ 'z',		'Z' ],
	'x',		[ 'x',		'X' ],
	'c',		[ 'c',		'C' ],
	'v',		[ 'v',		'V' ],
	'b',		[ 'b',		'B' ],
	'n',		[ 'n',		'N' ],
	'm',		[ 'm',		'M' ],
	'comma',	[ 'comma',	'less' ],
	'period',	[ 'period',	'greater' ],
	'slash',	[ 'slash',	'question' ],
	'International1', [ 'backslash', 'underscore' ],

	'International5', [ 'Muhenkan' ],
	'International4', [ 'Henkan' ],
	'International2', [ 'Hiragana_Katakana', 'Romaji' ],
];

$lang{'nl'} = [
	'!text', 'nl, Dutch, QWERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'at',		'section',	'notsign',	'notsign' ],
	'2',		[ '2',		'quotedbl',	'twosuperior',	'oneeighth' ],
	'6',		[ '6',		'ampersand',	'threequarters', 'fiveeighths' ],
	'7',		[ '7',		'underscore',	'sterling',	'seveneighths' ],
	'8',		[ '8',		'parenleft',	'braceleft',	'bracketleft' ],
	'9',		[ '9',		'parenright',	'braceright',	'bracketright' ],
	'0',		[ '0',		'apostrophe',	'degree',	'trademark' ],
	'minus',	[ 'slash',	'question',	'backslash',	'questiondown' ],
	'equal',	[ 'degree',	'dead_tilde',	'dead_cedilla',	'dead_ogonek' ],

	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],
	't',		[ 't',		'T',		'thorn',	'THORN' ],
	'y',		[ 'y',		'Y',		'ydiaeresis',	'yen' ],
	'u',		[ 'u',		'U',		'udiaeresis',	'Udiaeresis' ],
	'i',		[ 'i',		'I',		'idiaeresis',	'Idiaeresis' ],
	'o',		[ 'o',		'O',		'ograve',	'Ograve' ],
	'p',		[ 'p',		'P',		'paragraph',	'THORN' ],
	'bracketleft',	[ 'dead_diaeresis', 'dead_circumflex', 'asciitilde', 'asciicircum' ],
	'bracketright',	[ 'asterisk',	'bar',		'dead_tilde',	'dead_macron' ],

	'a',		[ 'a',		'A',		'aacute',	'Aacute' ],
	'f',		[ 'f',		'F',		'ordfeminine',	'ordfeminine' ],
	'semicolon',	[ 'plus',	'plusminus',	'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'dead_acute',	'dead_grave',	'apostrophe',	'grave' ],
	'numbersign_nonUS', [ 'less',	'greater',	'dead_grave',	'dead_breve' ],

	'backslash_nonUS', [ 'bracketright', 'bracketleft', 'bar',	'brokenbar' ],
	'v',		[ 'v',		'V',		'leftdoublequotemark', 'leftsinglequotemark' ],
	'b',		[ 'b',		'B',		'rightdoublequotemark',	'rightsinglequotemark' ],
	'n',		[ 'n',		'N',		'ntilde',	'Ntilde' ],
	'm',		[ 'm',		'M',		'Greek_mu',	'masculine' ],
	'comma',	[ 'comma',	'semicolon',	'cedilla',	'guillemetleft' ],
	'period',	[ 'period',	'colon',	'periodcentered', 'guillemetright' ],
	'slash',	[ 'minus',	'equal',	'hyphen',	'dead_abovedot' ],
];

$lang{'no'} = [
	'!text', 'no, Norwegian, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type2',

	'grave',	[ 'bar',	'section',	'brokenbar',	'paragraph' ],
	'5',		[ '5',		'percent',	'onehalf',	'permille' ],
	'minus',	[ 'plus',	'question',	'plusminus',	'questiondown' ],
	'equal',	[ 'backslash',	'dead_grave',	'dead_acute',	'notsign' ],

	'r',		[ 'r',		'R',		'registered',	'trademark' ],
	'p',		[ 'p',		'P',		'Greek_pi',	'Greek_PI' ],

	'semicolon',	[ 'oslash',	'Oslash',	'dead_acute',	'dead_doubleacute' ],
	'apostrophe',	[ 'ae',		'AE',		'dead_circumflex', 'dead_caron' ],
	'numbersign_nonUS', [ 'apostrophe', 'asterisk',	'dead_doubleacute', 'multiply' ],

	'backslash_nonUS', [ 'less',	'greater',	'onehalf',	'threequarters' ],
	'comma',	[ 'period',	'colon',	'ellipsis',	'periodcentered' ],
	'period',	[ 'minus',	'underscore',	'endash',	'emdash' ],
];

$lang{'pl'} = [
	'!text', 'pl, Polish, QWERTY',
	'!lang', 'base',
	'!lang', 'latin',

	'grave',	[ 'grave',	'asciitilde',	'notsign',	'logicalor' ],
	'1',		[ '1',		'exclam',	'notequal',	'exclamdown' ],
	'2',		[ '2',		'at',		'twosuperior',	'questiondown' ],
	'4',		[ '4',		'dollar',	'cent',		'onequarter' ],
	'5',		[ '5',		'percent',	'EuroSign',	'permille' ],
	'6',		[ '6',		'asciicircum',	'onehalf',	'logicaland' ],
	'7',		[ '7',		'ampersand',	'section',	'0x2248' ],
	'8',		[ '8',		'asterisk',	'periodcentered', 'threequarters' ],
	'9',		[ '9',		'parenleft',	'guillemetleft', 'plusminus' ],
	'0',		[ '0',		'parenright',	'guillemetright', 'degree' ],
	'minus',	[ 'minus',	'underscore',	'endash',	'emdash' ],

	'q',		[ 'q',		'Q',		'Greek_pi',	'Greek_OMEGA' ],
	'w',		[ 'w',		'W',		'oe',		'OE' ],
	'e',		[ 'e',		'E',		'eogonek',	'Eogonek' ],
	'r',		[ 'r',		'R',		'copyright',	'registered' ],
	't',		[ 't',		'T',		'ssharp',	'trademark' ],
	'i',		[ 'i',		'I',		'rightarrow',	'0x2194' ],
	'o',		[ 'o',		'O',		'oacute',	'Oacute' ],

	'a',		[ 'a',		'A',		'aogonek',	'Aogonek' ],
	's',		[ 's',		'S',		'sacute',	'Sacute' ],
	'f',		[ 'f',		'F',		'ae',		'AE' ],
	'h',		[ 'h',		'H',		'rightsinglequotemark', '0x2022' ],
	'j',		[ 'j',		'J',		'schwa',	'SCHWA' ],
	'k',		[ 'k',		'K',		'ellipsis',	'dead_stroke' ],

	'z',		[ 'z',		'Z',		'zabovedot',	'Zabovedot' ],
	'x',		[ 'x',		'X',		'zacute',	'Zacute' ],
	'c',		[ 'c',		'C',		'cacute',	'Cacute' ],
	'v',		[ 'v',		'V',		'doublelowquotemark', 'leftsinglequotemark' ],
	'b',		[ 'b',		'B',		'rightdoublequotemark', 'leftdoublequotemark' ],
	'n',		[ 'n',		'N',		'nacute',	'Nacute' ],
	'm',		[ 'm',		'M',		'mu',		'infinity' ],
	'comma',	[ 'comma',	'less',		'lessthanequal', 'multiply' ],
	'period',	[ 'period',	'greater',	'greaterthanequal', 'division' ],

	'space',	[ 'space',	'space',	'nobreakspace',	'nobreakspace' ],
];

$lang{'pl_QWERTZ'} = [
	'!text', 'pl_QWERTZ, Polish, QWERTZ',
	'!lang', 'base',
	'!lang', 'latin_type3',

	'grave',	[ 'abovedot',	'dead_ogonek',	'notsign',	'notsign' ],
	'1',		[ '1',		'exclam',	'asciitilde',	'exclamdown' ],
	'2',		[ '2',		'quotedbl',	'dead_caron',	'oneeighth' ],
	'3',		[ '3',		'numbersign',	'dead_circumflex', 'sterling' ],
	'4',		[ '4',		'dollar',	'dead_breve',	'dollar' ],
	'5',		[ '5',		'percent',	'degree',	'threeeighths' ],
	'6',		[ '6',		'ampersand',	'dead_ogonek',	'fiveeighths' ],
	'7',		[ '7',		'slash',	'dead_grave',	'seveneighths' ],
	'8',		[ '8',		'parenleft',	'dead_abovedot', 'trademark' ],
	'9',		[ '9',		'parenright',	'dead_acute',	'plusminus' ],
	'0',		[ '0',		'equal',	'dead_doubleacute', 'degree' ],
	'minus',	[ 'plus',	'question',	'dead_diaeresis', 'questiondown' ],
	'equal',	[ 'apostrophe',	'asterisk',	'dead_cedilla',	'dead_ogonek' ],

	'w',		[ 'w',		'W',		'bar',		'Greek_SIGMA' ],
	'e',		[ 'e',		'E',		'EuroSign',	'cent' ],
	'bracketleft',	[ 'zabovedot',	'nacute',	'division',	'dead_abovering' ],
	'bracketright',	[ 'sacute',	'cacute',	'multiply',	'dead_macron' ],

	's',		[ 's',		'S',		'dstroke',	'section' ],
	'd',		[ 'd',		'D',		'Dstroke',	'ETH' ],
	'k',		[ 'k',		'K',		'kra',		'ampersand' ],
	'l',		[ 'l',		'L',		'lstroke',	'Lstroke' ],
	'semicolon',	[ 'lstroke',	'Lstroke',	'dollar',	'dead_doubleacute' ],
	'apostrophe',	[ 'aogonek',	'eogonek',	'ssharp',	'dead_caron' ],
	'numbersign_nonUS', [ 'oacute',	'zacute',	'dead_grave',	'dead_breve' ],

	'c',		[ 'c',		'C',		'cent',		'copyright' ],
	'slash',	[ 'minus',	'underscore',	'dead_belowdot', 'dead_abovedot' ],
];

$lang{'se'} = [
	'!text', 'se, Swedish, QWERTY',
	'!lang', 'base',
	'!lang', 'latin_type2',

	'grave',	[ 'section',	'onehalf',	'paragraph',	'threequarters' ],
	'5',		[ '5',		'percent',	'EuroSign',	'permille' ],
	'6',		[ '6',		'ampersand',	'yen',		'radical' ],
	'minus',	[ 'plus',	'question',	'backslash',	'questiondown' ],
	'equal',	[ 'dead_acute',	'dead_grave',	'plusminus',	'notsign' ],

	'q',		[ 'q',		'Q',		'Greek_omega',	'Greek_OMEGA' ],
	'w',		[ 'w',		'W',		'Greek_sigma',	'Greek_SIGMA' ],
	'r',		[ 'r',		'R',		'registered',	'trademark' ],
	'p',		[ 'p',		'P',		'Greek_pi',	'Greek_PI' ],

	'k',		[ 'k',		'K',		'kra',		'dagger' ],
	'semicolon',	[ 'odiaeresis',	'Odiaeresis',	'oslash',	'Oslash' ],
	'apostrophe',	[ 'adiaeresis',	'Adiaeresis',	'ae',		'AE' ],
	'numbersign_nonUS', [ 'apostrophe', 'asterisk',	'acute',	'multiply' ],

	'backslash_nonUS', [ 'less',	'greater',	'bar',		'brokenbar' ],
	'c',		[ 'c',		'C',		'copyright',	'copyright' ],  # 4=0x1f12f, copyleft!
	'period',	[ 'period',	'colon',	'periodcentered', 'ellipsis' ],

	'space',	[ 'space',	'space',	'space',	'nobreakspace' ],
];

$lang{'us'} = [
	'!text', 'us, USA, QWERTY',
	'!lang', 'base',
	'!lang', 'latin',
];

$lang{'dvorak'} = [
	'!text', 'DVORAK',
	'!lang', 'base',

	'grave',	[ 'grave',	'asciitilde',	'dead_grave',	'dead_tilde' ],
	'1',		[ '1',		'exclam' ],
	'2',		[ '2',		'at' ],
	'3',		[ '3',		'numbersign' ],
	'4',		[ '4',		'dollar' ],
	'5',		[ '5',		'percent' ],
	'6',		[ '6',		'asciicircum',	'dead_circumflex', 'dead_circumflex' ],
	'7',		[ '7',		'ampersand' ],
	'8',		[ '8',		'asterisk' ],
	'9',		[ '9',		'parenleft',	'dead_grave',	'dead_breve' ],
	'0',		[ '0',		'parenright' ],
	'minus',	[ 'bracketleft', 'braceleft' ],
	'equal',	[ 'bracketright', 'braceright',	'dead_tilde'],

	'q',		[ 'apostrophe',	'quotedbl',	'dead_acute',	'dead_diaeresis' ],
	'w',		[ 'comma',	'less',		'dead_cedilla',	'dead_caron' ],
	'e',		[ 'period',	'greater',	'dead_abovedot', 'periodcentered' ],
	'r',		[ 'p',		'P' ],
	't',		[ 'y',		'Y' ],
	'y',		[ 'f',		'F' ],
	'u',		[ 'g',		'G' ],
	'i',		[ 'c',		'C' ],
	'o',		[ 'r',		'R' ],
	'p',		[ 'l',		'L' ],
	'bracketleft',	[ 'slash',	'question' ],
	'bracketright',	[ 'equal',	'plus' ],

	'a',		[ 'a',		'A' ],
	's',		[ 'o',		'O' ],
	'd',		[ 'e',		'E' ],
	'f',		[ 'u',		'U' ],
	'g',		[ 'i',		'I' ],
	'h',		[ 'd',		'D' ],
	'j',		[ 'h',		'H' ],
	'k',		[ 't',		'T' ],
	'l',		[ 'n',		'N' ],
	'semicolon',	[ 's',		'S' ],
	'apostrophe',	[ 'minus',	'underscore' ],
	'numbersign_nonUS', [ 'backslash', 'bar' ],

	'backslash_nonUS', [ 'backslash', 'bar' ],
	'z',		[ 'semicolon',	'colon',	'dead_ogonek',	'dead_doubleacute' ],
	'x',		[ 'q',		'Q' ],
	'c',		[ 'j',		'J' ],
	'v',		[ 'k',		'K' ],
	'b',		[ 'x',		'X' ],
	'n',		[ 'b',		'B' ],
	'm',		[ 'm',		'M' ],
	'comma',	[ 'w',		'W' ],
	'period',	[ 'v',		'V' ],
	'slash',	[ 'z',		'Z' ],
];

my @sym_flags = (
	undef,
	"HKL_SYM1",
	"HKL_SYM2",
	"HKL_SYM12",
	"HKL_SYM3",
	"HKL_SYM1 | HKL_SYM3",
	"HKL_SYM2 | HKL_SYM3",
	"HKL_SYM12 | HKL_SYM3",
	"HKL_SYM4",
	"HKL_SYM1 | HKL_SYM4",
	"HKL_SYM2 | HKL_SYM4",
	"HKL_SYM12 | HKL_SYM4",
	"HKL_SYM34",
	"HKL_SYM1 | HKL_SYM34",
	"HKL_SYM2 | HKL_SYM34",
	"HKL_SYM1234",
);

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %tables = ();
my %table_text = ();

for my $l (@langs) {
	$tables{$l} = {};
	$table_text{$l} = add_table($tables{$l}, $lang{$l});
}

print <<__EOF__;
// Automatically generated by lang_tables.pl

#include <stdint.h>

// Keyboard language tables

// All symbols are 16 bits, consisting of FLAGS|CODE symbol followed by data.

// FLAGS|CODE   top 8 bits flags, bottom 8 bits scancode, all zeros to end
//      [LANG]    language dependency if LANG inherit flag set
//      [SYM1]    level 1 sym if SYM1 flag set
//      [SYM2]    level 2 sym if SYM2 flag set
//      [SYM3]    level 3 sym if SYM3 flag set
//      [SYM4]    level 4 sym if SYM4 flag set

// Flags are processed in this order:
#define HKL_LANG  (1 << 15)      // inherit language
#define HKL_CLR   (1 << 14)      // clear all levels
#define HKL_SYM1  (1 << 8)       // level 1 sym
#define HKL_SYM2  (1 << 9)       // level 2 sym
#define HKL_SYM3  (1 << 10)      // level 3 sym
#define HKL_SYM4  (1 << 11)      // level 4 sym
#define HKL_DUP1  (1 << 12)      // copy level 1 to level 2
#define HKL_DUP12 (1 << 13)      // copy levels 1 & 2 to levels 3 & 4

// Convenience macros:
#define HKL_SYM12 (HKL_SYM1 | HKL_SYM2)
#define HKL_SYM34 (HKL_SYM3 | HKL_SYM4)
#define HKL_SYM1234 (HKL_SYM12 | HKL_SYM34)
#define HKL_END (0)

__EOF__

my @have_langs = ();

my $src = {};
my $total_sum = 0;
for my $l (@langs) {
	my $data = delta_table($src, $tables{$l});
	my $min_base;
	my $min_size = data_size($data);
	for my $ll (@have_langs) {
		my $tmp_data = delta_table($tables{$ll}, $tables{$l});
		my $tmp_size = data_size($tmp_data);
		if ($tmp_size < $min_size) {
			#print "// $l: $ll ($tmp_size) < $min_base ($min_size)\n";
			$data = $tmp_data;
			$min_size = $tmp_size;
			$min_base = $ll;
		}
	}
	if (defined $min_base) {
		unshift @{$data->[0]}, "HKL_LANG";
		unshift @{$data->[1]}, "hk_lang_${min_base}";
	}
	print_data($data, $l, $table_text{$l});
	$total_sum += $min_size;
	push @have_langs, $l if ($l ne 'default');
	$src = $tables{'default'};
}

print <<__EOF__;
// Language tables, indexed by hk_lang_*

static const uint16_t *lang_table[] = {
__EOF__

print "\t".join(", ", map { "lang_${_}" } @langs)."\n";

print "};\n";

exit 0;

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub add_table {
	my ($table, $script) = @_;

	my $text = "";

	my $scripti = 0;
	while (defined $script->[$scripti]) {
		my $tok = $script->[$scripti++];
		if ($tok =~ /^!/) {
			if ($tok eq '!lang') {
				my $deplang = $script->[$scripti++];
				add_table($table, $lang{$deplang});
			} elsif ($tok eq '!text') {
				$text = $script->[$scripti++];
			}
		} else {
			my $syms = $script->[$scripti++];
			if (ref $syms ne 'ARRAY') {
				die "bad data for $tok\n";
			}
			for my $i (0..scalar(@{$syms})-1) {
				$table->{$tok}->{$i} = $syms->[$i];
			}
			if (scalar(@{$syms}) == 1) {
				if (!exists $table->{$tok}->{1} || $table->{$tok}->{1} eq 'None') {
					$table->{$tok}->{1} = $table->{$tok}->{0};
				}
			}
			if (scalar(@{$syms}) == 2) {
				if (!exists $table->{$tok}->{2} || $table->{$tok}->{2} eq 'None') {
					$table->{$tok}->{2} = $table->{$tok}->{0};
				}
				if (!exists $table->{$tok}->{3} || $table->{$tok}->{3} eq 'None') {
					$table->{$tok}->{3} = $table->{$tok}->{1};
				}
			}
		}
	}
	return $text;
}

sub syms_for {
	my ($table, $code) = @_;
	my @syms = ();
	for my $i (0..3) {
		if (exists $table->{$code}->{$i}) {
			$syms[$i] = $table->{$code}->{$i};
		}
	}
	if (scalar(@syms) < 1) {
		$syms[0] = 'None';
	}
	if (scalar(@syms) < 2) {
		$syms[1] = $syms[0];
	}
	if (scalar(@syms) < 3) {
		$syms[2] = $syms[0];
		$syms[3] = $syms[1];
	}
	if (scalar(@syms) < 4) {
		$syms[3] = 'None';
	}
	return \@syms;
}

sub delta_table {
	my ($t1, $t2) = @_;
	my @result = ();
	my %list = ();
	for (keys %{$t1}) { $list{$_} = 1; }
	for (keys %{$t2}) { $list{$_} = 1; }
	for my $k (sort keys %list) {
		my $syms0 = syms_for($t1, $k);
		my $syms1 = syms_for($t2, $k);
		my $to_none = 0;
		my $to_sym = 0;
		my %changed = ();
		for my $i (0..3) {
			if ($syms0->[$i] ne $syms1->[$i]) {
				if ($syms1->[$i] eq 'None') {
					++$to_none;
				} else {
					++$to_sym;
				}
				$changed{$i} = $syms1->[$i];
			}
		}
		my $dup12 = 0;
		if ((exists $changed{0} || exists $changed{2}) &&
			($syms1->[0] eq $syms1->[2]) &&
			((!exists $changed{1} && !exists $changed{3}) || ($syms1->[1] eq $syms1->[3]))) {
			$dup12 = 1;
		}
		if ((exists $changed{1} || exists $changed{3}) &&
			($syms1->[1] eq $syms1->[3]) &&
			((!exists $changed{0} && !exists $changed{2}) || ($syms1->[0] eq $syms1->[2]))) {
			$dup12 = 1;
		}
		if ($dup12) {
			if (!exists $changed{0} && exists $changed{2}) {
				$changed{0} = $changed{2};
			}
			if (!exists $changed{1} && exists $changed{3}) {
				$changed{1} = $changed{3};
			}
			delete $changed{2};
			delete $changed{3};
		}
		my $dup1 = 0;
		if ((exists $changed{0} || exists $changed{1}) && ($syms1->[0] eq $syms1->[1])) {
			$dup1 = 1;
			if (!exists $changed{0}) {
				$changed{0} = $changed{1};
			}
			delete $changed{1};
		}
		if ($to_none > 0 || $to_sym > 0) {
			my @flags = ();
			my @syms = ();
			if ($dup1) {
				push @flags, "HKL_DUP1";
			}
			if ($dup12) {
				push @flags, "HKL_DUP12";
			}
			if ($to_none > 0 && ($to_none + $to_sym) == 4) {
				push @flags, "HKL_CLR";
				for my $ck (keys %changed) {
					if ($changed{$ck} eq 'None') {
						delete $changed{$ck};
					}
				}
			}
			my $symbits = 0;
			for my $ck (sort keys %changed) {
				$symbits |= (1 << $ck);
				if ($changed{$ck} =~ /^0x/) {
					push @syms, "$changed{$ck}";
				} else {
					push @syms, "hk_sym_$changed{$ck}";
				}
			}
			if (defined $sym_flags[$symbits]) {
				push @flags, $sym_flags[$symbits];
			}

			push @flags, "hk_scan_${k}";
			push @result, \@flags;
			push @result, \@syms;
		}
	}
	return \@result;
}

sub data_size {
	my ($data) = @_;
	my $sum = 0;
	my $i = 0;
	while ($i < scalar(@{$data})) {
		++$i;  # skip flags word
		++$sum;  # but add it to the total
		$sum += scalar(@{$data->[$i++]});  # add number of syms
	}
	++$sum;
	return $sum;
}

sub print_data {
	my ($data, $lang, $text) = @_;
	print "// $text\n\n";
	print "static const uint16_t lang_${lang}[] = {\n";
	while (scalar(@{$data}) > 0) {
		my $flags = shift @{$data};
		my $syms = shift @{$data};
		print "\t".join(" | ", @{$flags});
		if (scalar(@{$syms}) > 0) {
			print ", ";
			print join(", ", @{$syms});
		}
		print ",\n";
	}
	print "\tHKL_END\n";
	print "};\n\n";
}
