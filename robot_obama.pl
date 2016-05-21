#!/usr/local/bin/perl -w

#
# This program walks through HTML pages, extracting all the links to other
# text/html pages and then walking those links. Basically the robot performs
# a breadth first search through an HTML directory structure.
#
# All other functionality must be implemented
#
# Example:
#
#    robot_base.pl mylogfile.log content.txt http://www.cs.jhu.edu/
#
# Note: you must use a command line argument of http://some.web.address
#       or else the program will fail with error code 404 (document not
#       found).

use strict;

use Carp;
use HTML::LinkExtor;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use LWP::RobotUA;
use URI::URL;

URI::URL::strict( 1 );   # insure that we only traverse well formed URL's

$| = 1;

my $log_file = shift (@ARGV);

my $content_file = shift (@ARGV);

if ((!defined ($log_file)) || (!defined ($content_file))) {
    print STDERR "You must specify a log file, a content file and a base_url\n";
    print STDERR "when running the web robot:\n";
    print STDERR "  ./robot_base.pl mylogfile.log content.txt base_url\n";
    exit (1);
}

open LOG, ">$log_file";
open CONTENT, ">$content_file";

############################################################
##               PLEASE CHANGE THESE DEFAULTS             ##
############################################################

# I don't want to be flamed by web site administrators for
# the lousy behavior of your robots. 

my $ROBOT_NAME = 'LmaoBot/1.0';
my $ROBOT_MAIL = 'lmao5@jhu.edu';

my $robot = new LWP::RobotUA $ROBOT_NAME, $ROBOT_MAIL;

$robot->delay(0.02);

$robot->cookie_jar( {} );

my $base_url    = shift(@ARGV);   # the root URL we will start from
my ($site_name) = $base_url =~ /\.(.+)/;

my @search_urls = ();    # current URL's waiting to be trapsed
my @wanted_urls = ();    # URL's which contain info that we are looking for
my %relevance   = ();    # how relevant is a particular URL to our search
my %pushed      = ();    # URL's which have either been visited or are already
                         #  on the @search_urls array
my %output      = ();
    
push @search_urls, $base_url;



while (@search_urls) {

    my $url = shift @search_urls;

    my $parsed_url = eval { new URI::URL $url; };

    next if $@;
    next if $parsed_url->scheme !~/http/i; # case insensitive
	
    print $parsed_url, "\n";

    print LOG "[HEAD ] $url\n";

    my $request  = new HTTP::Request HEAD => $url;
    my $response = $robot->request( $request );

    # print $response->code, "\n";
    # print $response->content_type, "\n";
	
    # next if $response->code != RC_OK;

    # next if ! &wanted_content( $response->content_type, $parsed_url );

    print LOG "[GET  ] $url\n";

    $request->method( 'GET' );
    $response = $robot->request( $request );

    if ($response->code == "302") {

        $url = $response->header("Location");
        
        $request  = new HTTP::Request HEAD => $url;

        $request->method( 'GET' );
        $response = $robot->request( $request );

        # print $response->content;
    }

    # next if $response->code != RC_OK;

    next if $response->content_type !~ m@text/html@;
    
    print LOG "[LINKS] $url\n";

    &extract_content ($response->content, $url);

    my @related_urls  = &grab_urls( $response->content, $url );

    foreach my $link (@related_urls) {

        next if $link =~ /#/;
        next if $link !~ /http/;

        # print $link, "\n";

    	my $full_url = eval { (new URI::URL $link, $response->base)->abs; };
        
    	delete $relevance{ $link } and next if $@;

        next if $full_url =~ /$url#/;

        next if $full_url !~ /$site_name\/(2015|2016)/;

    	$relevance{ $full_url } = $relevance{ $link };

    	delete $relevance{ $link } if $full_url ne $link;

    	push @search_urls, $full_url and $pushed{ $full_url } = 1
    	    if ! exists $pushed{ $full_url };
    	
    }

    @search_urls = 
	sort { -1 * ($relevance{ $a } <=> $relevance{ $b }); } @search_urls;

}

close LOG;
close CONTENT;

exit (0);
    

sub extract_content {

    my $content = shift;
    my $url = shift;

    my $words;

    # print $content;
    


    open(my $obama, '>>', 'obama.raw');

    while ($content =~ s/Obama\s(said|added|claimed|stated|asked|exclaimed)[\s\w]*(\:|\,).\“([\-\’\.\,\?\!\s\w]+)\”//) {
        $words = $3;
        last if defined($output{$words});        
        # print $trump "\n";
        print "$words \n";
        print $obama "$words \n";
        # print $trump"\n";
        $output{$words} = $url;
    }

    while ($content =~ s/\“([\-\’\.\,\?\!\s\w]+)\”[\s\w\,]*(said|added|claimed|stated|asked|exclaimed)[\s\w]*Obama//) {
        $words = $1;
        last if defined($output{$words});        
        # print $trump "\n";
        print "$words \n";
        print $obama "$words \n";
        # print $trump"\n";
        $output{$words} = $url;
    }


    while ($content =~ s/\“([\-\’\.\,\?\!\s\w]+)\”[\s\w]*Obama[\s\w]*(said|added|claimed|stated|asked|exclaimed)//) {
        $words = $1;
        last if defined($output{$words});        
        # print $trump "\n";
        print "$words \n";
        print $obama "$words \n";
        # print $trump"\n";
        $output{$words} = $url;
    }
    close $obama;

    return;
}


sub grab_urls {

    my $content = shift;
    my $url = shift;

    my %urls    = ();    # NOTE: this is an associative array so that we only
                         #       push the same "href" value once.

    
    skip:
    
    while ($content =~ s/<\s*[aA] ([^>]*)>\s*(?:<[^>]*>)*(?:([^<]*)(?:<[^aA>]*>)*<\/\s*[aA]\s*>)?//) {

    	my $tag_text = $1;
    	my $reg_text = $2;
    	
        my $link = "";
        my $weight = 0;

        # print $tag_text, "\n";
        # print $reg_text, "\n";

    	if (defined $reg_text) {

    	    $reg_text =~ s/[\n\r]/ /;
    	    $reg_text =~ s/\s{2,}/ /;

            if ($reg_text =~ /obama|politics/i) {
                # print "OK", $reg_text, "\n";
                $weight ++;
            }
    	    #
    	    # compute some relevancy function here
    	    #
    	}

    	if ($tag_text =~ /href\s*=\s*(?:["']([^"']*)["']|([^\s])*)/i) {
    	    
            $link = $1 || $2;
            $link = "" if (!defined $link);
            # print $link, "\n";

            # next if $link !~ /$site_name/;

            if ($link =~ /democratic|politics|obamacare/i) {
                $weight ++;
            }


            if ($link =~ /obama/i) {
                $weight += 2;
            }

    	    #
    	    # okay, the same link may occur more than once in a
    	    # document, but currently I only consider the last
    	    # instance of a particular link
    	    #
            # print $weight, "\n";
    	    $relevance{ $link } = $weight;
    	    $urls{ $link }      = 1;
    	}

    	# print $reg_text, "\n" if defined $reg_text;
    	# print $link, "\n\n";
    }

    return keys %urls;   # the keys of the associative array hold all the
                         # links we've found (no repeats).
}
