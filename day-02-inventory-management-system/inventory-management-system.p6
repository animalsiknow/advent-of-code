#!/usr/bin/env perl6

my Int $with-pairs = 0;
my Int $with-triples = 0;

my @lines = "./inventory-management-system.txt".IO.lines.map(*.comb);

for @lines -> @line {
    my Int %frequencies is default(0);
    for @line -> $char {
        %frequencies{$char} += 1;
    }
    $with-pairs += 1 if 2 ∈ %frequencies.values;
    $with-triples += 1 if 3 ∈ %frequencies.values;
}

"checksum: $($with-pairs * $with-triples)".say;

for @lines -> @line {
    for @lines -> @reference {
        if (@line »eq« @reference).grep(* == False) == 1 {
            my Str $result = (@line Z @reference).grep({ $_[0] eq $_[1] }).map({ $_[0] }).join;
            "common letters: $result".say;
            exit;
        }
    }
}
