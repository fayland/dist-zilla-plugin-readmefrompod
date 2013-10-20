package Dist::Zilla::Plugin::ReadmeFromPod;

use Moose;
use Moose::Autobox;
use IO::Handle;
use Encode qw( encode );
with 'Dist::Zilla::Role::InstallTool' => { -version => 5 }; # after PodWeaver

has filename => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_filename',
);

sub _build_filename {
    my $self = shift;
    $self->zilla->main_module->name;
}

sub setup_installer {
    my ($self, $arg) = @_;

    my $mmcontent = $self->zilla->files->grep(sub {
        $_->name eq $self->filename
    })->head->content;

    require Pod::Text;
    my $parser = Pod::Text->new();
    $parser->parse_characters(1);
    $parser->output_string( \my $content );
    $parser->parse_string_document( $mmcontent );

    my $file = $self->zilla->files->grep( sub { $_->name =~ m{^README\z} } )->head;

    if ( $file ) {
        $file->content( $content );
        $self->zilla->log("Override README from [ReadmeFromPod]");
    } else {
        require Dist::Zilla::File::InMemory;
        $file = Dist::Zilla::File::InMemory->new({
            content => $content,
            name    => 'README',
        });
        $self->add_file($file);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 NAME

Dist::Zilla::Plugin::ReadmeFromPod - Automatically convert POD to a README for Dist::Zilla

=head1 SYNOPSIS

    # dist.ini
    [ReadmeFromPod]

    # or
    [ReadmeFromPod]
    filename = lib/XXX.pod

=head1 DESCRIPTION

generate the README from C<main_module> (or specified) by L<Pod::Text>

The code is mostly a copy-paste of L<Module::Install::ReadmeFromPod>

=head1 AUTHORS

Fayland Lam <fayland@gmail.com> and E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Fayland Lam <fayland@gmail.com> and E<AElig>var
ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
