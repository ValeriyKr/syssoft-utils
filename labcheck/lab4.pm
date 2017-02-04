package lab4;

use strict;
use warnings;

my $preload = "./lab4_preload.so";
my $labtests = "./labtests/lab4/";
my $preload_exitcode = 42;

my @var = (
    "zsh",
    "cat",
    "cp",
    "head",
    "tail",
    "tee",
    "wc",
    "cmp",
    "more",
    "less",
    "sed",
    "awk",
    "sh",
    "ksh",
    "csh"
);

# options 
my $pipe_input = 1 << 0;
my $file_input = 1 << 1;
my $trim_whitespaces = 1 << 2;
my $redirect = 1 << 3;

sub launch { 
	my ($executable, $options, $in_file, $out_file) = @_;
	my $cmd = "";
	if($options & $pipe_input) {
		$cmd .= "cat $in_file | ";
	}
	$cmd .= "LD_PRELOAD=$preload ";
	$cmd .= "$executable ";
	if($options & $file_input) {
		$cmd .= "$in_file ";
	}
	if($options & $trim_whitespaces) {
		$cmd .= " | sed -e 's/  */ /g; s/^ //g' ";
	}
	if($options & $redirect) {
		$cmd .= "> ";
	}
	$cmd .= "$out_file ";
	
	#print "cmd: $cmd\n";
	system($cmd);
	my $e = $? >> 8;
	#print "exitcode: $e\n\n" ;
	return $? >> 8;
}

sub check_test {
	my ($executable, $original, $test_file, $options) = @_;
	
	my $out_exec = "exec.out";
	my $out_orig = "orig.out";
	my $exit_code;
	
	if(launch($executable, $options, $test_file, $out_exec) == $preload_exitcode) {
		print "No.\n";
		return 2;
	}
	launch($original, $options, $test_file, $out_orig);
	
	system("cmp $out_exec $out_orig");
	return $? >> 8;
}

sub check_common_tests {
	my ($executable, $original, $options) = @_;
	my @common_tests = ();
	my $result;
	
	opendir(DIR, $labtests) or die $!;
	while (my $file = readdir(DIR)) {	
		next if ($file =~ m/^\./);
        push @common_tests, "$file";
    }
	closedir(DIR);
	
	@common_tests = sort @common_tests;

	foreach(@common_tests) {
		$result = check_test($executable, $original, "$labtests$_", $options);
		print "Common test $_ exits with exits code = $result\n";
	}
}

sub check_cat {
	my $executable = $_[0];
	my $original = "cat";
	
	check_common_tests($executable, $original, $file_input | $redirect);
}

sub check_wc {
	my $executable = $_[0];
	my $original = "wc";
	
	check_common_tests($executable, $original, $file_input | $redirect | $trim_whitespaces);
}

sub check {
	my ($varnum, $executable) = @_;
	print "Lab num: 4\nLab variant: $varnum -- $var[$varnum]\nExecutable: $executable\n";
	if($varnum == 1) {
		check_cat($executable);
	} elsif($varnum == 6) {
		check_wc($executable);
	} else {
		print "Checker for variant $var[$varnum] not implemented!\n";
	}
}

1
