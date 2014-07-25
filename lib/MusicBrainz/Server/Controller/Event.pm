package MusicBrainz::Server::Controller::Event;
use Moose;

BEGIN { extends 'MusicBrainz::Server::Controller'; }

with 'MusicBrainz::Server::Controller::Role::Load' => {
    model       => 'Event',
    entity_name => 'event',
};
with 'MusicBrainz::Server::Controller::Role::LoadWithRowID';
with 'MusicBrainz::Server::Controller::Role::Annotation';
with 'MusicBrainz::Server::Controller::Role::Alias';
with 'MusicBrainz::Server::Controller::Role::Cleanup';
with 'MusicBrainz::Server::Controller::Role::Details';
with 'MusicBrainz::Server::Controller::Role::EditListing';
with 'MusicBrainz::Server::Controller::Role::Relationship';
with 'MusicBrainz::Server::Controller::Role::Rating';
with 'MusicBrainz::Server::Controller::Role::Tag';
with 'MusicBrainz::Server::Controller::Role::WikipediaExtract';
with 'MusicBrainz::Server::Controller::Role::EditRelationships';

use MusicBrainz::Server::Constants qw( $EDIT_EVENT_CREATE $EDIT_EVENT_DELETE $EDIT_EVENT_EDIT $EDIT_EVENT_MERGE );

use Sql;

=head2 base

Base action to specify that all actions live in the C<event>
namespace

=cut

sub base : Chained('/') PathPart('event') CaptureArgs(0) { }

after 'load' => sub
{
    my ($self, $c) = @_;

    my $event = $c->stash->{event};

    my $event_model = $c->model('Event');
    $event_model->load_meta($event);
    if ($c->user_exists) {
        $event_model->rating->load_user_ratings($c->user->id, $event);
    }

    $c->model('EventType')->load($event);
    $c->model('Relationship')->load($event);
    $c->model('Relationship')->load($event->related_series);
};

=head2 show

Shows an event's main landing page.

=cut

sub show : PathPart('') Chained('load')
{
    my ($self, $c) = @_;

    $c->model('Event')->load_performers($c->stash->{event});

    $c->stash(template => 'event/index.tt');
}


sub _merge_load_entities
{
    my ($self, $c, @events) = @_;
    $c->model('EventType')->load(@events);
    $c->model('Event')->load_performers(@events);
};

=head2 WRITE METHODS

=cut

with 'MusicBrainz::Server::Controller::Role::Merge' => {
    edit_type => $EDIT_EVENT_MERGE,
};

with 'MusicBrainz::Server::Controller::Role::Create' => {
    form      => 'Event',
    edit_type => $EDIT_EVENT_CREATE,
    dialog_template => 'event/edit_form.tt',
};

with 'MusicBrainz::Server::Controller::Role::Edit' => {
    form           => 'Event',
    edit_type      => $EDIT_EVENT_EDIT,
};

with 'MusicBrainz::Server::Controller::Role::Delete' => {
    edit_type      => $EDIT_EVENT_DELETE,
};

1;
