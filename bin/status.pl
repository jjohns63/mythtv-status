#!/usr/bin/perl -w

# Display the current status of a MythTV system.

use LWP::Simple;
use XML::LibXML;
use Date::Manip;
use Getopt::Long;

# Some sane defaults.
my $host = "localhost";
my $port = "6544";

GetOptions(
  'h|host=s' => \$host,
  'p|port=s' => \$port
);

die "Sorry, port isn't a number.\n"
  if $port !~ /^\d+$/;

my $url = "http://$host:$port/xml";
my $status = get($url);

die "Sorry, failed to fetch $url.\n"
  unless defined $status;

my $parser = XML::LibXML->new();
my $xml = eval { $parser->parse_string( $status ) };

our $today    = substr(ParseDate('today'), 0, 8);
our $tomorrow = substr(ParseDate('tomorrow'), 0, 8);

# The blocks of output which we might generate.
my @blocks = (
  # Info about the encoders.
  {
    'name'  => 'Encoders',
    'xpath' => "//Status/Encoders/Encoder",
    'attrs' => [ qw/hostname id state/ ],
    'template' => "__hostname__ (__id__) - __state__",
    'rewrite' => {
      'state' =>{ '0' => 'Idle', '4' => 'Recording' },
    }
  },

  # What programs (if any) are being recorded right now?
  {
    'name'  => 'Recording Now',
    'xpath' => "//Status/Encoders/Encoder/Program",
    'attrs' => [ qw/title endTime/ ],
    'template' => "__title__ (Ends: __endTime__)",
     'rewrite' => {
       'endTime' => { 'T' => ' ' },
     }
  },

  # The upcoming recordings.
  {
    'name'  => 'Scheduled Recordings',
    'xpath' => '//Status/Scheduled/Program',
    'attrs' => [ qw/title startTime/ ],
    'template' => "__startTime__ - __title__",
    'filter' =>  {
       # Only show recordings for today and tomorrow.
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

  # Don't do any work on this block if there is nothing for it.
  next
    if (scalar(@$items) == 0);

  print "$block->{'name'}:\n";

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
