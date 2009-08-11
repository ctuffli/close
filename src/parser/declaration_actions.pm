# $Id$

=method cv_qualifier

Creates a type-specifier entry, with "is_<?>" set to 1. Type-specifier is used 
because a cv_qualifier is a valid type specifier by itself.

=cut

method cv_qualifier($/) {
	my $past := close::Compiler::Types::new_specifier(:name(~$<token>));
	$past{'is_' ~ $<token>} := 1;
	DUMP($past);
	make $past;
}

=method dclr_alias

Just another kind of declarator.

=cut

method dclr_alias($/) {
	my $past := close::Compiler::Types::new_dclr_alias($<alias>.ast);
	DUMP($past);
	make $past;
}
=method dclr_array_or_hash

Constructs an immediate token to represent the type-declarator,
and attaches any attributes required (array #elements).

=cut

method dclr_array_or_hash($/) {
	my $past;
	
	if $<hash> {
		$past := new_dclr_hash();
	}
	elsif $<expression> {
		$past := immediate_token("FixedArray");
		$past<num_elements> := $<expression>.ast;
	}
	else {
		$past := immediate_token("Array");
	}
	$past.node($/);
	
	DUMP($past);
	make $past;
}

# method declarator_name($/)
# This method is defined in name_actions.pm

=method dclr_atom

Passes through the PAST of the C<declarator_name> or of the 
nested C<declarator>.

=cut

method dclr_atom($/) {
	if $<declarator_name> {
		make $<declarator_name>.ast;
	}
	else {
		make $<declarator>.ast;
	}
}

method declarator($/) {	
	my $past := $<dclr_atom>.ast;
	NOTE("Processing declarator: ", $past.name());
	DUMP($past);
	
	unless $past<etype> {
		$past<etype> := $past;
	}
	
	my $last_dclr := $past<etype>;
	
	# Merge postfix declarator mods (array, function, hash) in to 
	# $past - the inner declarator or symbol name. Postfix declarators
	# read left to right, so foo()[] is a function returning an array. 
	# The declarator chain here should be 'foo'->function->array.
	for $<dclr_postfix> {
		NOTE("Adding postfix declarator: ", $_.ast.name());
		$last_dclr<type> := $_.ast;
		$last_dclr := $_.ast;
	}
	
	$past<etype> := $last_dclr;
	
	# Merge prefix declarator mods (pointer) in to $past.
	# Prefix declarators read from right to left, making 
	# C< *v *c foo> a "const pointer to volatile pointer".
	# The declarator chain should be foo -> *c -> *v.	
	$last_dclr := $past<etype><type>;
	
	for $<dclr_pointer> {
		NOTE("Adding pointer declarator: ", $_.ast.name());
		# Reverse pointers by "inserting" them in at back of list.
		$_.ast<type> := $past<etype><type>;
		$past<etype><type> := $_.ast;
		
		if !$last_dclr {
			$last_dclr := $_.ast;
		}
	}

	if $last_dclr {
		$past<etype> := $last_dclr;
	}
	
	NOTE("Declarator fixed up (specifiers not added yet)");
	DUMP($past);
	make $past;
}
	
=method dclr_alias_init($/)

=cut

method dclr_alias_init($/) {
	my $past := $<declarator>.ast;
	
	if $<initializer> {
		$past<initializer> := $<initializer>[0].ast;
	}
	
	DUMP($past);
	make $past;
}

=method dclr_pointer

Creates a token around the '*' in the pointer declarator, and attaches
any qualifiers as children of the node.

=cut

method dclr_pointer($/) {
	my $past := new_dclr_pointer();
	$past.node($/);
	$past.name(~$/);
	
	for $<cv_qualifier> {
		$past := close::Compiler::Types::merge_specifiers($past, $past, $_.ast);
	}

	DUMP($past);
	make $past;
}

=method dclr_postfix

Passes through the array, hash, or function declarator.

=cut

method dclr_postfix($/, $key) { PASSTHRU($/, $key); }

method declaration($/, $key) {
	if $key eq 'specifiers' {
		NOTE("Processing specifiers");
		# Create a temporary block on scope stack, so symbol names
		# are visible to later declarations in this same structure.
		# e.g., typedef int X, X* PX; // X must be visible after comma
		my $block := close::Compiler::Node::create('decl_temp',
			:name('temporary declaration scope')
		);
		
		my $past := $block<varlist>;
		# Modify $specifier to reflect all the specifiers we saw. 
		# Attach errors to $past.
		for $<specifier> {
			$past<specifier> := close::Compiler::Types::merge_specifiers($past, $past<specifier>, $_.ast);
		}
		
		close::Compiler::Scopes::push($block);
		
		NOTE("Pushed temporary varlist scope on stack.");
		DUMP($block);
	}
	elsif $key eq 'declarators' {
		# FIXME: It may be logical to separate the VarList and the 
		# Block, and only create the VarList to replace the Block in this
		# part.
		
		NOTE("Processing declarators");
		# Once the declaration is complete, the temporary block is 
		# discarded. At that point, though, the PAST returned is a 
		# varlist, and whoever requested the varlist should merge the 
		# symbols in with their own symbol table. (E.g., a declaration
		# statement, or a parameter list, or whatever.)
		my $block	:= close::Compiler::Scopes::pop('decl_temp');
		my $past	:= $block<varlist>;
		my $spec	:= $past<specifier>;
		
		NOTE("Popped ", $block<lstype>, " scope '", $block.name(), "'");
		
		# Convert individual declarators into type-chains
		# Create Past Var entries for each declarator.
		# Lookup init values for types where no initializer is provided.
		# Set types for 'auto' decls with initializers.
			
		# Merge the specifier in to the declarator. Attach errors, etc.
		for $<symbol> {
			my $declarator := $_.ast;
			NOTE("Merging specifier with declarator '", $declarator.name(), "'");
			$declarator := 
				close::Compiler::Types::add_specifier_to_declarator($spec, $declarator);
			$past.push($declarator);
		}

		if +@($block) {
			$/.panic("Unexpected elements added to temporary VarList block");
		}

		NOTE("done");
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action declaration: ' ~ $key);
	}
}

method declarator_part($/) {
	my $past := $<declarator>.ast;
	NOTE("Assembling declarator ", $past.name());
	
	if $<dclr_alias> {
		$past<alias> := $<dclr_alias>.ast;
	}
	
	if $<initializer> {
		NOTE("Adding initializer");
		my $initializer := $<initializer>[0].ast;
		DUMP($initializer);
		$past<initializer> := $initializer;
	}
	
	if $<body> {
		# Where is the block for this?
		ASSERT($past<type><is_function>, "It's a function, unless it's a class or something.");
		
		if $past<type><is_function> {
			$past<type><function_definition> := $<body>[0].ast;
		}
	}
	
	NOTE("done");
	DUMP($past);
	make $past;
}

=method namespace_alias_declaration

Edits the enclosing block of this node, creating an alias for the namespace
name given.

=cut

method namespace_alias_declaration($/) {
	my $ns_name := $<namespace>.ast;
	my $past := $<alias>.ast;

	$past.isdecl(1);
	$past<is_alias> := 1;
	$past<alias_for> := $ns_name;
	
	DUMP($past);
	make $past;
}

method namespace_definition($/, $key) {
	if $key eq 'open' {
		# FIXME: This should be a function, maybe part of the namespace_path target.
 		my $path	:= $<namespace_path>.ast;
		my @namespace_path;
		
		if $path<is_rooted> {
			@namespace_path	:= $path.namespace();
			@namespace_path.unshift($path<hll>);
		}
		else {
			my $parent		:= close::Compiler::Scopes::fetch_current_namespace();
			@namespace_path	:= Array::concat($parent<path>, $path.namespace());
		}
		
		NOTE("Opening namespace: hll: ", Array::join(' :: ', @namespace_path));
		my $namespace := close::Compiler::Namespaces::fetch(@namespace_path);
		close::Compiler::Scopes::push($namespace);
	}
	else { # $key eq 'close'
		my $past := close::Compiler::Scopes::pop('namespace_block');
		
		for $<extern_statement> {
			$past.push($_.ast);
		}
		
		DUMP($past);
		make $past;
	}
}


our %Adverb_aliases;
%Adverb_aliases{'...'} := 'slurpy';
%Adverb_aliases{'?'} := 'optional';

sub adverb_unalias_name($adverb) {
	my $name := $adverb.value();
	NOTE("Unaliasing adverb: '", $name, "'");
	DUMP($adverb);
	
	if %Adverb_aliases{$name} {
		$name := %Adverb_aliases{$name};
	}
	elsif String::char_at($name, 0) eq ':' {
		$name := String::substr($name, 1);
	}
	
	ASSERT(String::length($name) > 0, 'Adverb name must have some value.');
	NOTE("Unaliased name is: '", $name, "'");
	return $name;
}

method param_adverb($/) {
	my $past := make_token($<token>);
	$past.name(adverb_unalias_name($past));
	
	DUMP($past);
	make $past;
}

=method parameter_declaration

=cut

method parameter_declaration($/) {
	my $past := close::Compiler::Node::create('parameter_declaration', 
		:from($<parameter>.ast));
	
	my $specifier;

	for $<specifier> {
		$specifier := close::Compiler::Types::merge_specifiers($past, $specifier, $_.ast);
	}

	close::Compiler::Types::add_specifier_to_declarator($specifier, $past);
	
	for $<adverbs> {
		my $adv := $_.ast;
		$past<adverbs>{$adv.name()} := $adv;
	}
	
	if $<default> {
		$past<default> := $<default>.ast;
	}
	
	# Done by declarator_name
	# Declare object in current scope, which should be a parameter block.
	ASSERT(
		close::Compiler::Scopes::get_object(
			close::Compiler::Scopes::current(), $past.name()) =:= $past,
		'Expected current scope would already have this parameter declared (by <declarator_name>)');
	
	# Insert declaration into current scope.
	my $scope := close::Compiler::Scopes::current();
	DUMP($scope);
	ASSERT(close::Compiler::Node::type($scope) eq 'parameter_scope',
		'Parameters are expected to be declared within a parameter_scope block');
	$scope.push($past);
	
	DUMP($past);
	make $past;
}

=method parameter_list

Creates a function-returning declarator, which is set as the PAST result of 
the rule. The declarator contains a PAST::Block to represent the function's 
parameter scope.

=cut

method parameter_list($/, $key) {
	if $key eq 'open' {
		NOTE('Begin function parameter list');
		my $past	:= close::Compiler::Types::function_returning();
		$past.node(	$/);
		my $block	:= $past<parameter_scope>;
		
		close::Compiler::Scopes::push($block);

		NOTE("Pushed new scope on stack: ", $block.name());
		DUMP($past);
	}
	elsif $key eq 'close' {
		my $block	:= close::Compiler::Scopes::pop('parameter_scope');
		my $past	:= $block<function_decl>;
		
		NOTE("Popped scope from stack: ", $block.name());
		
		for $<param_list> {
			NOTE('Adding parameter to function: ', $_.ast.name());
			$past.push($_.ast);
			close::Compiler::Scopes::add_declarator($block, $_.ast);
		}
		
		NOTE('End function parameter list: ', +@($past), ' parameters');
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action dclr_param_list: ' ~ $key);
	}
}

method specifier($/, $key) { PASSTHRU($/, $key); }

=method tspec_builtin_type

Creates a type specifier with noun set to the type name.

=cut

method tspec_builtin_type($/) {
	my $past := close::Compiler::Types::new_specifier(
		:is_builtin(1),
		:noun(~$<token>),
		:name(~$<token>));
	DUMP($past);
	make $past;
}

=method tspec_function_attr

Creates a token around the keyword.

=cut

method tspec_function_attr($/) {
	my $past := close::Compiler::Types::new_specifier();
	$past{'is_' ~ $<token>} := 1;
	DUMP($past);
	make $past;
}

=method tspec_storage_class

Creates a token around the keyword.

=cut

method tspec_storage_class($/) {
	my $past := close::Compiler::Types::new_specifier(:storage_class(~$<token>));
	DUMP($past);
	make $past;
}

method tspec_type_specifier($/, $key) { PASSTHRU($/, $key); }

method tspec_type_name($/) {
	my $past := close::Compiler::Types::new_specifier(:type_name($<type_name>.ast));
	DUMP($past);
	make $past;
}