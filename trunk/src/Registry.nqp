# $Id: String.nqp 166 2009-09-27 15:58:50Z austin_hastings@yahoo.com $

module Registry;

#Parrot::IMPORT('Dumper');
	
################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	say("Registry::_onload");
	
	Registry := Hash::new();
}

################################################################

# No methods, no subs.