package CreateDocument;

use warnings;
use strict;


sub get_etherpad_contents {
    my $first_found_etherpad = $_[0];
    my $date_of_event = $_[1];
    my $event_page_link = $_[2];
    my $event_name = $_[3];

    my $etherpad_ua = LWP::UserAgent->new;

    my $etherpad_request = $etherpad_ua->get($first_found_etherpad);

    my $etherpad_content = $etherpad_request->decoded_content;

    my $header = "
'''<dfn>$event_name</dfn>''' was an IndieWeb meetup on Zoom held on $date_of_event.

* $event_page_link
* When: $date_of_event
* Archived from: $first_found_etherpad


    ";

    my $wiki_entry_body = $header . $etherpad_content;

    my $footer = "

{{Homebrew Website Club}}

[[Category:Events]]
    ";

    $wiki_entry_body .= $footer;

    $wiki_entry_body;
}

sub create_page {
    my $event_page_link = $_[0];

    my $event_page_ua = LWP::UserAgent->new;

    my $parsed_event_page = Mojo::DOM->new($event_page_ua->get($event_page_link)->decoded_content);

    # find all links
    my $links = $parsed_event_page->find('a');

    my $event_name = $parsed_event_page->at('.p-name')->text;
    my @event_date = split 'T', $parsed_event_page->at('.dt-start')->attr('value');

    my $date_of_event = $event_date[0];

    my $first_found_etherpad = "";

    for my $link ($links->each) {
        my $href = $link->attr('href');
        if ($href =~ /etherpad.indieweb.org/) {
            $first_found_etherpad = $href;
        }
    }

    if (!$first_found_etherpad) {
        return "Could not find Etherpad link on provided page.";
    }

    $first_found_etherpad .= "/export/txt";

    my $url = $ENV{'wiki_url'};

    my $ua = LWP::UserAgent->new(
        cookie_jar => {},
    );

    my $login = WikiActions::login_to_mediawiki($ua);
    my $csrf_token = WikiActions::get_csrf_token($ua);
    my $wiki_entry_body = get_etherpad_contents($first_found_etherpad, $date_of_event, $event_page_link, $event_name);

    $event_name = lc($event_name);
    $event_name =~ s/-//g;
    $event_name =~ s/  / /g;
    $event_name =~ s/ /-/g;

    my %request = (
        "action" => "edit",
        "format" => "json",
        "title" => "events/$date_of_event-$event_name",
        "text" => $wiki_entry_body,
        "token" => $csrf_token
    );

    # my $l = $ua->post($url, \%request);

    # if ($l->is_success) {
    #     return "Created https://indieweb.org/events/$date_of_event-$event_name. Please review the page to ensure the document is correctly formatted and remove any unnecessary text.";
    # } else {
    #     return "There was an error and your wiki entry was not created."
    # }
}

1;