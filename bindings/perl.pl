#!/usr/bin/perl
use v5.40;

use IO::Socket;
#use JSON::XS qw( decode_json );
use JSON::PP qw( decode_json ); # use Pure Perl version to reduce dependencies

use Exporter qw( import );
our @EXPORT_OK = qw( exocket );

sub exocket($msg) {
    my ($host, $port) = ('localhost', 7777);

    my $sock = IO::Socket::INET->new(
        Proto     => "tcp",
        PeerAddr  => $host,
        PeerPort  => $port
    ) || do {
        die "can't connect to port $port on $host: $!";
    };

    $sock->autoflush(1); # so output gets there right away
    $sock->send("$msg\n") or die "No sent size";
    $sock->shutdown(SHUT_WR);
    my $buffer = '';
    $sock->recv($buffer, 10*1024*1024); # NOTE might need to increase buffer length
    my $reply = eval { decode_json($buffer) };
    $sock->shutdown(SHUT_RDWR);
    $sock->close();
    return $reply;
}

say exocket('exec log("asdf")');

sub session_status {
    my $status_num = exocket('exec session_status()');
    my $status_desc = {
        0 => 'не определено',
        1 => 'основная сессия',
        2 => 'начался промклиринг',
        3 => 'завершился промклиринг',
        4 => 'начался основной клиринг',
        5 => 'основной клиринг: новая сессия назначена',
        6 => 'завершился основной клиринг',
        7 => 'завершилась вечерняя сессия',
    };
    return $status_desc->{int $status_num};
}

say "Session status: ".session_status();
my $wut = { secclass => 'SPBFUT', seccode => 'USDRUBF' };
say "$wut->{seccode} best offer: ".
    exocket("exec getParamEx('$wut->{secclass}', '$wut->{seccode}', 'OFFER').param_value");
say "$wut->{seccode} best bid: ".
    exocket("exec getParamEx('$wut->{secclass}', '$wut->{seccode}', 'BID').param_value");

1;
