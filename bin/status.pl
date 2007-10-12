#!/usr/bin/perl -w

use LWP::Simple;
use XML::LibXML;
use Date::Manip;

my $host = "localhost";
my $port = "6544";

my $status = get("http://$host:$port/xml");

my $parser = XML::LibXML->new();
my $xml = eval { $parser->parse_string( $status ) };

our $today    = substr(ParseDate('today'), 0, 8);
our $tomorrow = substr(ParseDate('tomorrow'), 0, 8);

my @blocks = (
  {
    'name'  => 'Encoders',
    'xpath' => "//Status/Encoders/Encoder",
    'attrs' => [ qw/hostname id state/ ],
    'template' => "__hostname__ (__id__) - __state__",
    'rewrite' => {
      'state' =>{ '0' => 'Idle', '4' => 'Recording' },
    }
  },
  {
    'name'  => 'Recording Now',
    'xpath' => "//Status/Encoders/Encoder/Program",
    'attrs' => [ qw/title endTime/ ],
    'template' => "__title__ (Ends: __endTime__)",
     'rewrite' => {
       'endTime' => { 'T' => ' ' },
     }
  },
  {
    'name'  => 'Scheduled Recordings',
    'xpath' => '//Status/Scheduled/Program',
    'attrs' => [ qw/title startTime/ ],
    'template' => "__startTime__ - __title__",
    'filter' =>  {
       'startTime' => sub {
	   my $date = substr(ParseDate($_[0]), 0, 8);
           return ! (($date cmp $today) == 0
	      || ($date cmp $tomorrow) == 0) }
     },
     'rewrite' => {
       'startTime' => { 'T' => ' ' },
     }
  }
);

for my $block (@blocks) {
  my $items = $xml->documentElement->find($block->{'xpath'});

  print "$block->{'name'}:\n"
    if (scalar(@$items) > 0);

  for my $item (@{ $items }) {
    my $template = $block->{'template'};
    my $skip = undef;
    for my $key (@{ $block->{'attrs'} }) {
      my $value = $item->getAttribute($key);

      $skip = 1
        if defined $block->{'filter'}{$key} &&
	  &{ $block->{'filter'}{$key} }($value);

      if (defined $block->{'rewrite'}{$key}) {
	my ($search, $replace);
	while (($search, $replace) = each %{ $block->{'rewrite'}{$key} } ) {
	  $value =~ s/$search/$replace/g;
	}
      }

      $template =~ s/__${key}__/$value/g;
    }
   
    print "$template\n"
      unless defined $skip;
  }

  print "\n";
}
