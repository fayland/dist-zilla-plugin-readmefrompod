package Dist::Zilla::Plugin::ReadmeFromPod;

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool' => { -version => 5 }; # after PodWeaver
with 'Dist::Zilla::Role::FilePruner';

use IO::String;
use Pod::Readme;

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
    isa => 'Maybe[Str]',
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

sub prune_files {
    my ($self) = @_;
    my $readme_file = $self->zilla->files->grep( sub { $_->name =~ m{^README\z} } )->head;
    if ($readme_file and $readme_file->added_by =~ /Dist::Zilla::Plugin::Readme/) {
        $self->log_debug([ 'pruning %s', $readme_file->name ]);
        $self->zilla->prune_file($readme_file);
    }
}

sub setup_installer {
    my ($self, $arg) = @_;

    my $pod_class = $self->pod_class;
    my $readme_name = $self->readme;

    ## guess pod_class from exisiting file, like GitHub will have README.md created
    my $readme_file;
    if (not $readme_name) {
        my %ext = (
            'md'       => 'markdown',
            'mkdn'     => 'markdown',
            'markdown' => 'markdown',
            'html'     => 'html',
            'htm'      => 'html',
            'rtf'      => 'rtf',
            'txt'      => 'txt',
            ''         => 'pod',
            'pod'      => 'pod'
        );
        foreach my $e (keys %ext) {
            $readme_file = $self->zilla->root->file("README.$e");
            if (-e "$readme_file") {
                $pod_class = $FORMATS{ $ext{$e} }->{class};
                last;
            }
        }
    }

    my $content;
    my $prf = Pod::Readme->new(
      input_file        => $self->filename,
      translate_to_fh   => IO::String->new($content),
      translation_class => $pod_class,
      zilla             => $self->zilla,
    );
    $prf->run();

    if ($readme_file) {
        return $readme_file->spew(iomode => '>:raw', $content);
    }

    $readme_name ||= $prf->default_readme_file;
    my $file = $self->zilla->files->grep( sub { $_->name eq $readme_name } )->head;
    if ( $file ) {
        $file->content( $content );
        $self->zilla->log("Override README from [ReadmeFromPod]");
    } else {
        require Dist::Zilla::File::InMemory;
        $file = Dist::Zilla::File::InMemory->new({
            content => $content,
            name    => "${readme_name}", # stringify, as it may be Path::Tiny
        });
        $self->add_file($file);
    }

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

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

=head2 Options

The following options are supported:

=head3 C<filename>

The name of the file to extract the F<README> from. This defaults to
the main module of the distribution.

=head3 C<type>

The type of F<README> you want to generate. This defaults to "text".

Other options are "html", "pod", "markdown" and "rtf".

=head3 C<pod_class>

This is the L<Pod::Simple> class used to translate a file to the
format you want. The default is based on the L</type> setting, but if
you want to generate an alternative type, you can set this option
instead.

=head3 C<readme>

The name of the file, which defaults to one based on the L</type>.

=head2 Conflicts with Other Plugins

We will remove the README created by L<Dist::Zilla::Plugin::Readme> automatically.

=head1 AUTHORS

Fayland Lam <fayland@gmail.com> and
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

Robert Rothenberg <rrwo@cpan.org> modified this plugin to use
L<Pod::Readme>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Fayland Lam <fayland@gmail.com> and E<AElig>var
ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
