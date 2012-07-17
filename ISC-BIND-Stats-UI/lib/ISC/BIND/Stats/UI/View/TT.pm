package ISC::BIND::Stats::UI::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

ISC::BIND::Stats::UI::View::TT - TT View for ISC::BIND::Stats::UI

=head1 DESCRIPTION

TT View for ISC::BIND::Stats::UI.

=head1 SEE ALSO

L<ISC::BIND::Stats::UI>

=head1 AUTHOR

Francisco Obispo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
