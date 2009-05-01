use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;
use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

{
    my @meths = (
        method ($foo, $bar, @rest) {
            return join q{,}, @rest;
        },
        method ($foo, $bar, %rest) {
            return join q{,}, map { $_ => $rest{$_} } keys %rest;
        },
    );

    for my $meth (@meths) {
        dies_ok(sub { $o->${\$meth->body}() });
        dies_ok(sub { $o->${\$meth->body}('foo') });

        lives_and(sub {
            is($o->${\$meth->body}('foo', 'bar'), q{});
        });

        lives_and(sub {
            is($o->${\$meth->body}('foo', 'bar', 1 .. 6), q{1,2,3,4,5,6});
        });
    }
}

{
    my $meth = method (Str $foo, Int $bar, Int @rest) {
        return join q{,}, @rest;
    };

    lives_and(sub {
        is($o->${\$meth->body}('foo', 42), q{});
    });

    lives_and(sub {
        is($o->${\$meth->body}('foo', 42, 23, 13), q{23,13});
    });

    throws_ok(sub {
        $o->${\$meth->body}('foo', 42, 'moo', 13);
    }, qr/Validation failed/);
}

{
    eval 'my $meth = method (:$foo, :@bar) { }';
    like $@, qr/arrays or hashes cannot be named/i;

    eval 'my $meth = method ($foo, @bar, :$baz) { }';
    like $@, qr/named parameters can not be combined with slurpy positionals/i;
}
