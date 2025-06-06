#!/usr/bin/perl

# Read xkb_keycodes section, writes mapping table X11 keycode -> HK scancode.
#
# Note: parsing is minimal - it might be easy to break this script - but it
# works ok for the cases I've used in XRoar.

use File::Basename;
use FindBin;

# Most keys are given sensible names or aliases, and so we map those names to
# the corresponding HK scancode names here.  It's fine for more than one Xkb
# name to map to a HK scancode: there are several international keys that X11
# or Linux made keycodes for that USB spec consideres to be the same.
#
# Note numbers reference "HID Usage Tables for USB", chapter 10
# (Keyboard/Keypad Page 0x07).

my %map = (

	### Sun keys

	'<HELP>' => 'Help',
	'<STOP>' => 'Cancel',
	'<AGAI>' => 'Redo',
	# Need 'Props' for <PROP>
	'<UNDO>' => 'Undo',
	# Need 'Front' for <FRNT>
	'<COPY>' => 'Copy',
	# Need 'Open' for <OPEN>
	'<PAST>' => 'Paste',
	'<FIND>' => 'Find',
	'<CUT>' => 'Cut',

	### Main body of keyboard

	# Need 'Blank' for <BLNK>
	'<FK01>' => 'F1',
	'<FK02>' => 'F2',
	'<FK03>' => 'F3',
	'<FK04>' => 'F4',
	'<FK05>' => 'F5',
	'<FK06>' => 'F6',
	'<FK07>' => 'F7',
	'<FK08>' => 'F8',
	'<FK09>' => 'F9',
	'<FK10>' => 'F10',
	'<FK11>' => 'F11',
	'<FK12>' => 'F12',

	'<ESC>' => 'Escape',
	'<AE01>' => '1',
	'<AE02>' => '2',
	'<AE03>' => '3',
	'<AE04>' => '4',
	'<AE05>' => '5',
	'<AE06>' => '6',
	'<AE07>' => '7',
	'<AE08>' => '8',
	'<AE09>' => '9',
	'<AE10>' => '0',
	'<AE11>' => 'minus',
	'<AE12>' => 'equal',
	'<AE13>' => 'International3',  # Note 18
	'<BKSL>' => 'backslash',
	'<TLDE>' => 'grave',
	'<AE00>' => 'grave',

	'<TAB>' => 'Tab',
	'<AD01>' => 'q',
	'<AD02>' => 'w',
	'<AD03>' => 'e',
	'<AD04>' => 'r',
	'<AD05>' => 't',
	'<AD06>' => 'y',
	'<AD07>' => 'u',
	'<AD08>' => 'i',
	'<AD09>' => 'o',
	'<AD10>' => 'p',
	'<AD11>' => 'bracketleft',
	'<AD12>' => 'bracketright',
	'<BKSP>' => 'BackSpace',

	'<LCTL>' => 'Control_L',
	'<AC01>' => 'a',
	'<AC02>' => 's',
	'<AC03>' => 'd',
	'<AC04>' => 'f',
	'<AC05>' => 'g',
	'<AC06>' => 'h',
	'<AC07>' => 'j',
	'<AC08>' => 'k',
	'<AC09>' => 'l',
	'<AC10>' => 'semicolon',
	'<AC11>' => 'apostrophe',
	'<RTRN>' => 'Return',

	'<LFSH>' => 'Shift_L',
	'<AB00>' => 'backslash',
	'<AB01>' => 'z',
	'<AB02>' => 'x',
	'<AB03>' => 'c',
	'<AB04>' => 'v',
	'<AB05>' => 'b',
	'<AB06>' => 'n',
	'<AB07>' => 'm',
	'<AB08>' => 'comma',
	'<AB09>' => 'period',
	'<AB10>' => 'slash',
	'<AB11>' => 'International1',  # Note 15,16
	'<RTSH>' => 'Shift_R',

	'<AC12>' => 'numbersign_nonUS',
	'<LSGT>' => 'backslash_nonUS',

	'<CAPS>' => 'Caps_Lock',
	'<LALT>' => 'Alt_L',
	'<ALT>' => 'Alt_L',
	'<LMTA>' => 'Super_L',
	'<SPCE>' => 'space',
	'<RMTA>' => 'Super_R',
	# Need 'Compose' or 'Multi_key' for <COMP>, <LCMP>, <RCMP>
	'<RALT>' => 'Alt_R',
	'<RCTL>' => 'Control_R',

	'<META>' => 'Super_L',
	'<LWIN>' => 'Super_L',
	'<LAMI>' => 'Super_L',
	'<SUPR>' => 'Super_L',
	'<RWIN>' => 'Super_R',
	'<RAMI>' => 'Super_R',
	'<ALGR>' => 'Alt_R',
	'<LVL3>' => 'Alt_R',

	### TTY keys, etc.

	'<PRSC>' => 'Print',
	'<SCLK>' => 'Scroll_Lock',
	'<PAUS>' => 'Pause',
	# Need 'Break' for <BRE> and <BRK>

	'<INS>' => 'Insert',
	'<HOME>' => 'Home',
	'<PGUP>' => 'Page_Up',

	'<DELE>' => 'Delete',
	'<DEL>' => 'Delete',
	'<END>' => 'End',
	'<PGDN>' => 'Page_Down',

	'<UP>' => 'Up',
	'<LEFT>' => 'Left',
	'<DOWN>' => 'Down',
	'<RGHT>' => 'Right',

	### Media keys

	'<MUTE>' => 'Mute',
	'<VOL->' => 'Volume_Down',
	'<VOL+>' => 'Volume_Up',
	'<POWR>' => 'Power',
	# No standard keycode name for Eject

	### Keypad

	'<NMLK>' => 'Num_Lock',
	'<KPDV>' => 'KP_Divide',
	'<KPMU>' => 'KP_Multiply',
	'<KPSU>' => 'KP_Subtract',

	'<KP7>' => 'KP_7',
	'<KP8>' => 'KP_8',
	'<KP9>' => 'KP_9',
	'<KPAD>' => 'KP_Add',

	'<KP4>' => 'KP_4',
	'<KP5>' => 'KP_5',
	'<KP6>' => 'KP_6',

	'<KP1>' => 'KP_1',
	'<KP2>' => 'KP_2',
	'<KP3>' => 'KP_3',
	'<KPEN>' => 'KP_Enter',

	'<KP0>' => 'KP_0',
	# Should *both* of thse be KP_Decimal?
	'<KPDC>' => 'KP_Decimal',
	'<KPDL>' => 'KP_Decimal',
	'<KPEQ>' => 'KP_Equal',
	# And is this actually that KPPT means?
	'<KPPT>' => 'KP_Separator',

	### Misc

	'<FK13>' => 'F13',
	'<FK14>' => 'F14',
	'<FK15>' => 'F15',
	'<FK16>' => 'F16',
	'<FK17>' => 'F17',
	'<FK18>' => 'F18',
	'<FK19>' => 'F19',
	'<FK20>' => 'F20',
	'<FK21>' => 'F21',
	'<FK22>' => 'F22',
	'<FK23>' => 'F23',
	'<FK24>' => 'F24',
	'<CLR>' => 'Clear',
	'<MENU>' => 'Menu',
	'<SELE>' => 'Select',
	'<EXEC>' => 'Execute',
	# No specific SysRq scancode, but it often shares with Print:
	'<SYRQ>' => 'Print',

	# Various keys from USB spec
	'<HENK>' => 'International4',  # Note 19
	'<HKTG>' => 'International2',  # Note 17
	'<MUHE>' => 'International5',  # Note 20
	'<HNGL>' => 'Lang1',  # Note 24
	'<HJCV>' => 'Lang2',  # Note 25
	'<KATA>' => 'Lang3',  # Note 26
	'<HIRA>' => 'Lang4',  # Note 27
	# Lang5: Note 28:
	#    "Zenkaku/Hankaku key for Japanese USB word-processing keyboards"
	# Lang6-Lang9: Note 29:
	#    "Reserved for language-specific functions, such as Front End
	#     Processors and Input Method Editors."

	### Unsupported for now (see comments)

	'<PROP>' => '',
	'<FRNT>' => '',
	'<OPEN>' => '',
	'<BLNK>' => '',
	'<COMP>' => '',
	'<LCMP>' => '',
	'<RCMP>' => '',
	'<BRK>' => '',
	'<BREA>' => '',
	'<HYPR>' => '',

	### Explicitly unsupported

	'<FK25>' => '',
	'<FK26>' => '',
	'<FK27>' => '',
	'<FK28>' => '',
	'<FK29>' => '',
	'<FK30>' => '',
	'<FK31>' => '',
	'<FK32>' => '',
	'<KPF1>' => '',
	'<KPF2>' => '',
	'<KPF3>' => '',
	'<KPF4>' => '',
	'<LNFD>' => '',

);

my %sections = ();
my $section;

read_dir("/usr/share/X11/xkb/keycodes", "");
read_dir("$FindBin::Bin/keycodes", "");

print "// Tables auto-generated from Xkb keycodes files\n\n";

# Pairs of arguments after the section name passed to print_table() provide
# local overrides for keycodes without good names.  Some are comments in the
# xkb data file, some from what SDL authors already determined.

print_table("evdev(evdev)",
	'<I147>' => 'Menu',
	'<I190>' => 'Redo',
	'<I218>' => 'Print',
	'<I231>' => 'Cancel',
);

print_table("xfree86(xfree86)");

print_table("macintosh(old)",
	# From SDL:
	'<I60>' => 60,
	'<I60>' => 'KP_Enter',
	'<LEFT>' => 131,  # commented out <RTSH> in xkb-data
	'<RGHT>' => 132,  # commented out <RALT> in xkb-data
	'<DOWN>' => 133,  # commented out <RCTL> in xkb-data
	'<UP>' => 134,    # commented out <RMTA> in xkb-data
);

print_table("amiga(usa1)",
	'<KPLP>' => 'Num_Lock',
	'<KPRP>' => 'Scroll_Lock',
);

print_table("sun(type6tuv)");

exit 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# read_dir() recurses directories and calls read_file() for any files.

sub read_dir {
	my ($dirname,$basename) = @_;
	my $dh;
	opendir $dh, $dirname or return;
	while (my $ent = readdir $dh) {
		next if ($ent =~ /^\./);
		if (-d "$dirname/$ent") {
			read_dir("$dirname/$ent", "$basename$ent/");
		} elsif (-f "$dirname/$ent") {
			read_file("$dirname/$ent", "$basename$ent");
		}
	}
	closedir $dh;
}

# Parse a Xkb keycode data file.  Not proper grammar, a very big bodge that
# happens to work with the data there right now.

sub read_file {
	my ($filename,$basename) = @_;
	return unless open(my $f, "<", $filename);

	my $line;
	while (my $l = <$f>) {
		chomp $l;
		$l =~ s#//.*$##;
		$l =~ s/^\s+//;
		$l =~ s/\s+$//;
		next if ($l eq "");
		$line .= " " if (defined $line);
		$line .= $l;

		if ($line =~ /include\s*"([^"]+)"/) {
			my $include = $1;
			if ($include !~ /\(/) {
				$include = "$include($include)";
			}
			if (defined $section) {
				push @{$section->{include}}, $include;
			}
			undef $line;
			next;
		}

		next if ($line !~ /[{;]$/);

		my $xline = $line;
		undef $line;

		if ($xline =~ /^(\S+)\s*=\s*(\S+)\s*;/) {
			next unless defined $section;
			next if ($1 eq 'minimum');
			next if ($1 eq 'maximum');
			$section->{codes}->{$1} = $2;
			next;
		}
		if ($xline =~ /^alias\s*(\S+)\s*=\s*(\S+)\s*;/) {
			if (defined $section) {
				$section->{aliases}->{$1} = $2;
			}
			next;
		}
		if ($xline =~ /^(default\s+)?xkb_keycodes\s+"([^"]+)".*/) {
			my ($default,$name) = ($1,$2);
			$name = "$basename($name)";
			if (!exists $sections{$name}) {
				$sections{$name} = { name => "$name", codes => {} };
			}
			$section = $sections{$name};
			next;
		}
		if ($xline =~ /}\*;/) {
			undef $section;
			next;
		}
	}
	close $f;
}

# Populate a data hash with codes and aliases relevant to a section.

sub add_section {
	my ($name, $data) = @_;
	$data //= { aliases => {}, codes => {} };
	if (!exists $sections{$name}) {
		warn "Missing section: $name\n";
		return $data;
	}
	my $section = $sections{$name};
	for my $subname (@{$section->{include}}) {
		$data = add_section($subname, $data);
	}
	while (my ($k, $v) = each %{$section->{codes}}) {
		$data->{codes}->{$k} = $v;
	}
	while (my ($k, $v) = each %{$section->{aliases}}) {
		$data->{aliases}->{$k} = $v;
	}
	return $data;
}

# Resolve aliases in a data hash into codes where possible.

sub resolve_aliases {
	my ($data) = @_;
	for my $alias (sort keys %{$data->{aliases}}) {
		my $falias = $alias;
		FOLLOW: while (defined $falias) {
			unshift @{$data->{comments}->{$alias}}, $falias;
			if (exists $data->{codes}->{$falias}) {
				$data->{codes}->{$alias} = $data->{codes}->{$falias};
				last FOLLOW;
			}
			$falias = $data->{aliases}->{$falias};
		}
		if (!exists $data->{codes}->{$alias}) {
			warn "Couldn't find scancode for $alias\n";
		}
	}
	delete $data->{aliases};
}

# Print mapping table to HK scancodes for a particular section.

sub print_table {
	my $section = shift @_;
	my $arrayname = $section;
	$arrayname =~ s/\(/_/;
	$arrayname =~ s/\)//;

	my $data = add_section($section);
	my $supp_map = {};
	while (my $k = shift @_) {
		my $v = shift @_;
		if ($v =~ /^\d+$/) {
			$data->{codes}->{$k} = $v;
		} else {
			$supp_map->{$k} = $v;
		}
	}
	resolve_aliases($data);

	my @table = (undef) x 256;
	my @comment = ();
	for my $name (sort keys %{$data->{codes}}) {
		my $code = $data->{codes}->{$name};
		next if (defined $table[$code]);
		if (exists $data->{comments}->{$name}) {
			$comment[$code] = join(" => ", @{$data->{comments}->{$name}});
		} else {
			$comment[$code] = $name;
		}
		$comment[$code] .= " => $code";
		if (exists $supp_map->{$name}) {
			$table[$code] = "hk_scan_".$supp_map->{$name};
		} elsif (exists $map{$name} && $map{$name} ne '') {
			$table[$code] = "hk_scan_".$map{$name};
		} elsif (!exists $map{$name}) {
			$comment[$code] .= " (no mapping)";
		}
	}

	print "static const uint8_t xkb_${arrayname}_to_hk_scancode[256] = {\n";

	for my $i (0..255) {
		my $hk = $table[$i] // "hk_scan_None";
		print "\t$hk,";
		my $col = length($hk) + 1;
		my $sp = 28 - $col;
		if ($sp < 1) {
			$sp = (($col + 2) | 7) + 1 - $col;
		}
		if (defined $comment[$i]) {
			print " " x $sp;
			print "// ".$comment[$i];
		}
		print "\n";
	}

	print "};\n\n";
}
