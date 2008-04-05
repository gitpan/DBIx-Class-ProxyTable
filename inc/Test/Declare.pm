#line 1
package Test::Declare;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.01';

my @test_more_exports;
BEGIN {
    @test_more_exports = qw(
        use_ok require_ok
        skip todo todo_skip
        pass fail
        eq_array eq_hash eq_set
        plan
        can_ok
        diag
        BAIL_OUT
        $TODO
    );
}

use Test::More import => \@test_more_exports;
use Test::Exception;
use Test::Deep;

our @EXPORT = (@test_more_exports, qw/
    init cleanup run test describe
    is_deeply_array
    cmp_ok ok
    dies_ok throws_ok
    is isnt is_deeply like unlike
    isa_ok
    cmp_deeply re
    blocks
    prints_ok stderr_ok
/);

my $test_block_name;
sub test ($$) { ## no critic
    $test_block_name = shift;
    shift->();
}

{
    no strict 'refs'; ## no critic
    for my $sub (qw/init cleanup/) {
        *{"Test\::Declare\::$sub"} = sub (&) {
            shift->();
        };
    }
}

sub run (&) { shift } ## no critic

sub describe ($$) { ## no critic
    shift; shift->();
}

use PPI;
sub PPI::Document::find_test_blocks {
    my $self = shift;
    my $blocks = $self->find(
        sub {
            $_[1]->isa('PPI::Token::Word')
            and
            $_[1]->{content} eq 'test'
        }
    )||[];
    return @$blocks
}
sub blocks {
    my @caller = caller;
    my $file = $caller[1];
    my $doc = PPI::Document->new($file) or die $!;
    return scalar( $doc->find_test_blocks );
}

## Test::More wrapper
{
    no strict 'refs'; ## no critic
    for my $sub (qw/is is_deeply like isa_ok isnt unlike/) {
        *{"Test\::Declare\::$sub"} = sub ($$;$) {
            my ($actual, $expected, $name) = @_;
            my $test_more_code = "Test\::More"->can($sub);
            goto $test_more_code, $actual, $expected, $name||$test_block_name;
        }
    }

}

sub cmp_ok ($$$;$) { ## no critic
    my ($actual, $operator, $expected, $name) = @_;
    my $test_more_code = "Test\::More"->can('cmp_ok');
    goto $test_more_code, $actual, $operator, $expected, $name||$test_block_name;
}

sub ok ($;$) { ## no critic
    my ($test, $name) = @_;
    my $test_more_code = "Test\::More"->can('ok');
    goto $test_more_code, $test, $name||$test_block_name;
}

## original method
sub is_deeply_array ($$;$) { ## no critic
    my ($actual, $expected, $name) = @_;
    is_deeply( [sort { $a cmp $b } @{$actual}], [sort { $a cmp $b } @{$expected}], $name);
}

use IO::Scalar;
sub prints_ok (&$;$) { ## no critic
    my ($code, $expected, $name) = @_;

    tie *STDOUT, 'IO::Scalar', \my $stdout;
        $code->();
        like($stdout, qr/$expected/, $name||$test_block_name);
    untie *STDOUT;
}
sub stderr_ok (&$;$) { ## no critic
    my ($code, $expected, $name) = @_;

    tie *STDERR, 'IO::Scalar', \my $stderr;
        $code->();
        like($stderr, qr/$expected/, $name||$test_block_name);
    untie *STDERR;
}

1;

__END__
