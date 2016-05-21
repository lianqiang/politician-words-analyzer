#!/usr/local/bin/perl -w


use strict;

use Carp;
use FileHandle;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use utf8;
use Text::Unidecode;

use Net::Twitter::Lite::WithAPIv1_1;





my $consumer_key = "fo6MDUtBhkZ2MaVB4CFM2mIG1";
my $consumer_secret = "vIu8ALtsC3HGMPJoaAZWJe7a6Q4Kf1IyGRjZcrbKm2v0AUPhnp";
my $token = "731363372084670464-4OOcPt3xHVQHkBsqXz7W9iqO48Sgd9z";
my $token_secret = "I4Cg0ni1EQdjtVaTEVGqkc4Ai737W2B49RwHT5LOID6La";


  open(my $trumptweets, '>', 'trumptweets.raw');
  my $st = 'from:realDonaldTrump';
  my $numtweets = 1000;

my $newt = Net::Twitter::Lite::WithAPIv1_1->new(
    consumer_key        => $consumer_key,
   consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret, ssl=>1);



my $results = $newt->search({q=>$st,count=> $numtweets, lang=>"en"});
for my $status ( @{$results->{statuses}} ) {
    $status->{text} =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
    print $trumptweets "$status->{text}\n\n";
}

close $trumptweets;

open(my $hillarytweets, '>', 'hillarytweets.raw');
  $st = 'from:HillaryClinton';
   
$results = $newt->search({q=>$st,count=> $numtweets,lang=>"en"});

for my $status ( @{$results->{statuses}} ) {
    $status->{text} =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
    print $hillarytweets "$status->{text}\n\n";
}
close $hillarytweets;

open(my $obamatweets, '>', 'obamatweets.raw');
  $st = 'from:BarackObama';
   
$results = $newt->search({q=>$st,count=> $numtweets, lang=>"en"});
for my $status ( @{$results->{statuses}} ) {
    $status->{text} =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
    #$status->{text} =~ s/(.*)http//g;
  #  print $1;
    print $obamatweets "$status->{text}\n\n";
}
close $hillarytweets;


exit (0);
