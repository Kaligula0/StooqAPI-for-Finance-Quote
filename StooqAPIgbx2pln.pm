#    Copyright (C) 1998, Dj Padzensky <djpadz@padz.net>
#    Copyright (C) 1998, 1999 Linas Vepstas <linas@linas.org>
#    Copyright (C) 2000, Yannick LE NY <y-le-ny@ifrance.com>
#    Copyright (C) 2000, Paul Fenwick <pjf@cpan.org>
#    Copyright (C) 2000, Brent Neal <brentn@users.sourceforge.net>
#    Copyright (C) 2000, Keith Refson <Keith.Refson@earth.ox.ac.uk>
#    Copyright (C) 2003, Tomas Carlsson <tc@tompa.nu>
#    Copytight (C) 2010, Michal Fita
#    Copytight (C) 2022, Kaligula <kaligula.dev@gmail.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#
# This code was derived from the work on the packages Finance::Yahoo::*
# This code was derived from the work on the packages Finance::SEB
#
package Finance::Quote::StooqAPIgbx2pln;
require 5.004;

use strict;

use vars qw($VERSION $STOOQ_STOCKS_URL);

use LWP::UserAgent;
use HTTP::Request::Common;
use utf8;

$VERSION = '0.20';
$STOOQ_STOCKS_URL = 'https://stooq.com/q/l/';

sub methods { return (stooq_api_gbx2pln => \&stooq_api_gbx2pln); }

{
  my @labels = qw/date isodate time method source name currency last price open high low ask bid volume/;
	
  sub labels { return (stooq_api_gbx2pln => \@labels); }
}

sub stooq_api_gbx2pln {
  my $quoter  = shift;
  my @symbols = @_;

  return unless @symbols;
  my ($ua, $url_rate, $reply_rate, $url, $reply, $symbol, %stocks);
  $ua    = $quoter->user_agent;

  $url_rate   = $STOOQ_STOCKS_URL . '?s=GBPPLN&f=c';
  $reply_rate = $ua->request(GET $url_rate);
  unless ($reply_rate->is_success) {
    $stocks{$symbol, "success"}  = 0;
    $stocks{$symbol, "errormsg"} = "HTTP failure";
    return wantarray ? %stocks : \%stocks;
  }
  my ($rate,$empty_footer_rate) = split(/\r\n/, $reply_rate->content, 2);
  chomp($rate);

  foreach $symbol (@symbols) {

    # Nioch, nioch... stooq accepts only lower case tickers!
    $url   = $STOOQ_STOCKS_URL . '?s=' . lc $symbol . '&f=nd2t2ohlcabv';
	# format (&f=):
	#	a	ask
	#	b	bid
	#	c	close
	#	dX	date in format nr X (X=[1,2,3,4])
	#	h	high
	#	i	openint
	#	l	low
	#	n	name
	#	o	open
	#	p	previous
	#	r	turnover
	#	s	symbol
	#	tX	time in format nr X (X=[1,2,3,4])
	#	v	volume

    $reply = $ua->request(GET $url);
    unless ($reply->is_success) {
      $stocks{$symbol, "success"}  = 0;
      $stocks{$symbol, "errormsg"} = "HTTP failure";
      return wantarray ? %stocks : \%stocks;
    }

	my ($name, $date, $time, $open, $high, $low, $last, $ask, $bid, $volume);
	
	my ($line,$empty_footer) = split(/\r\n/, $reply->content, 2);
	chomp($line);
	# Format:
	# Name,Date,Time,Open,High,Low,Close,Ask,Bid,Volume
	# CDPROJEKT,2022-10-28,17:01:20,119.5,124.7,118.54,124,124.0,123.94,603435
	($name, $date, $time, $open, $high, $low, $last, $ask, $bid, $volume) = split ',', $line;

    utf8::encode($name);

    #if (grep {$_ eq $name} @symbols) {
    unless ($date eq "N/A") {

		#$price =~ s/,/\./; # change decimal point from , to .
		$stocks{$symbol, 'symbol'}   = $symbol;
		$stocks{$symbol, 'name'}     = ($_ = $name, s/[\"]//g, $_);
		$quoter->store_date(\%stocks, $symbol, { isodate => $date });
		$stocks{$symbol, 'time'}     = $time;
		$stocks{$symbol, 'open'}     = $open * $rate;
		$stocks{$symbol, 'high'}     = $high * $rate;
		$stocks{$symbol, 'low'}      = $low * $rate;
		$stocks{$symbol, 'last'}     = $last * $rate;
		$stocks{$symbol, 'price'}    = $last * $rate;
		$stocks{$symbol, 'ask'}      = $ask * $rate;
		$stocks{$symbol, 'bid'}      = $bid * $rate;
		$stocks{$symbol, 'volume'}   = $volume;

		$stocks{$symbol, 'method'}   = 'stooq_api_gbx2pln';
		$stocks{$symbol, 'source'}   = 'Finance::Quote::StooqAPIgbx2pln';

		$stocks{$symbol, 'currency'} = 'PLN';
	
		# divide GBX (p) quotes by 100
		foreach my $field ( $quoter->default_currency_fields ) {
			next unless ( $stocks{ $symbol, $field } );
			$stocks{ $symbol, $field } =
				$quoter->scale_field( $stocks{ $symbol, $field },
									0.01 );
		}
	  
		$stocks{$symbol, 'success'}  = 1;

    }
  }

  # Check for undefined symbols
  foreach my $symbol (@symbols) {
    unless ($stocks{$symbol, 'success'}) {
      $stocks{$symbol, "success"}  = 0;
      $stocks{$symbol, "errormsg"} = "Stock name not found";
    }
  }

  return %stocks if wantarray;
  return \%stocks;
}

1;

=head1 NAME

Finance::Quote::Stooq - Obtain prices of stocks traded on GPW from www.stooq.com

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %stockinfo = $q->fetch("stooq_api_gbx2pln","tlt"); # the letter ticker

=head1 DESCRIPTION

This module obtains information about prices of stocks being trade on WARSAW
STOCK EXCHANGE market in Poland through popular stooq.com service, as currently
open method for accessing such data directly from GPW is not known.

=head1 STOCK NAMES

Every stock shares traded on Warsaw Stock Exchange has its own unique three
letter ticker (there is one exception – "SVRS").

For example:
"GPW" for Warsaw Stock Exchange itself,
"TPE" for Tauron Polska Energia,
"CDR" for CD Projekt SA.

=head1 LABELS RETURNED

Information available from GPW may include the following labels:
date time method source name currency price low high. The prices are available for most
recent closed session.

=head1 SEE ALSO

GPW website - https://www.gpw.pl/
STOOQ website - https://stooq.com/ or https://stooq.pl/

=cut
