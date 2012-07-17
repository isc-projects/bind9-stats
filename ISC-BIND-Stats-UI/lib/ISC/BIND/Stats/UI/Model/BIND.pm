package ISC::BIND::Stats::UI::Model::BIND;

use Moose;
BEGIN { extends 'Catalyst::Model::MongoDB' };

__PACKAGE__->config(
	host => 'localhost',
	port => '27017',
	dbname => '',
	collectionname => '',
	gridfs => '',
);

=head1 NAME

ISC::BIND::Stats::UI::Model::BIND - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<ISC::BIND::Stats::UI>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

=head1 AUTHOR

Francisco Obispo

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
