package Dist::Zilla::Plugin::ReadmeFromPod;

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool' => { -version => 5 }; # after PodWeaver

use IO::String;

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

has type => (
    is => 'ro',
    isa => 'Str',
    default => 'text',
);

my %FORMATS = (
    'html'     => { class => 'Pod::Simple::HTML' },
    'markdown' => { class => 'Pod::Markdown'     },
    'pod'      => { class => undef },
    'rtf'      => { class => 'Pod::Simple::RTF' },
    'text'     => { class => 'Pod::Simple::Text' },
);

has pod_class => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_pod_class',
);

sub _build_pod_class {
  my $self = shift;
  my $fmt  = $FORMATS{$self->type}
    or $self->log_fatal("Unsupported type: " . $self->type);
  $fmt->{class};
}

has readme => (
    is => 'ro',
    isa => 'Str',
);

sub setup_installer {
    my ($self, $arg) = @_;

    require Pod::Readme;

    my $content;

    my $prf = Pod::Readme->new(
      input_file        => $self->filename,
      translate_to_fh   => IO::String->new($content),
      translation_class => $self->pod_class
    );

    $prf->run();

    my $name = $self->readme // $prf->default_readme_file;
    my $file = $self->zilla->files->grep( sub { $_->name eq $name } )->head;

    if ( $file ) {
        $file->content( $content );
        $self->zilla->log("Override README from [ReadmeFromPod]");
    } else {
        require Dist::Zilla::File::InMemory;
        $file = Dist::Zilla::File::InMemory->new({
            content => $content,
            name    => $name,
        });
        $self->add_file($file);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 NAME

Dist::Zilla::Plugin::ReadmeFromPod - dzil plugin to generate README from POD

=head1 SYNOPSIS

    # dist.ini
    [ReadmeFromPod]

    # or
    [ReadmeFromPod]
    filename = lib/XXX.pod
    type = markdown
    readme = READTHIS.md

=head1 DESCRIPTION

This plugin generates the F<README> from C<main_module> (or specified)
by L<Pod::Readme>.

=head1 AUTHORS

Fayland Lam <fayland@gmail.com> and E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Fayland Lam <fayland@gmail.com> and E<AElig>var
ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
