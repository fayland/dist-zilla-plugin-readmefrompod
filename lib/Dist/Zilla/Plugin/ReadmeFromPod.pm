package Dist::Zilla::Plugin::ReadmeFromPod;

use Moose;
use Moose::Autobox;
use IO::Handle;
use Encode qw( encode );

with 'Dist::Zilla::Role::InstallTool';

sub setup_installer {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;
  
  my $mmcontent = $self->zilla->main_module->content;

  require Pod::Text;
  my $parser = Pod::Text->new();
  $parser->output_string( \my $input_content );
  $parser->parse_string_document( $mmcontent );
  
  my $content;
  if( defined $parser->{encoding} ){ 
    $content = encode( $parser->{encoding} , $input_content );
  } else { 
     $content = $input_content; 
  }

  my $file = $self->zilla->files->grep( sub { $_->name =~ m{README\z} } )->head;

  if ( $file ) {
    $file->content( $content );
    $self->zilla->log("Override README from [ReadmeFromPod]");
  } else {
    $file = Dist::Zilla::File::InMemory->new({
        content => $content,
        name    => 'README',
    });
    $self->add_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Dist::Zilla::Plugin::ReadmeFromPod - Automatically convert POD to a README for Dist::Zilla

=head1 SYNOPSIS

    # dist.ini
    [ReadmeFromPod]

=head1 DESCRIPTION

Generates a plain-text README for your L<Dist::Zilla> powered dist
from its C<main_module> with L<Pod::Text>.

=head1 AUTHORS

Fayland Lam <fayland@gmail.com> and E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Fayland Lam <fayland@gmail.com> and E<AElig>var
ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
