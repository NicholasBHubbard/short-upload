#!perl

use strict;
use warnings;
use v5.20;
use autodie;

use File::Temp;

use Mojolicious::Lite -signatures;
use Mojo::File qw(path);
use Mojo::IOLoop;
use Mojo::Upload;
use Mojo::Util qw(quote);

my $FILESTORE = File::Temp->newdir('short-upload.store.XXXXXX', PERMS=>0700);
my $FILENAME_CACHE = {};
my $MAX_FILE_SIZE = 1024 * 1024 * 1024;
my $MAX_FILES_STORED = 50;

get '/' => sub ($c) {
    $c->render(template => 'form');
};

post '/upload' => sub ($c) {
    my $file = $c->req->upload('file');
    unless ($file && length $file->filename) {
        return $c->render(text => 'No file uploaded', status=>400);
    }
    if ($file->size > $MAX_FILE_SIZE) {
        return $c->render(text => 'File exceeds max size of 1GB', status=>400);
    }
    if (keys %$FILENAME_CACHE >= $MAX_FILES_STORED) {
        return $c->render(text => 'File store full try again later', status=>400);
    }
    my $tmp = File::Temp->new('XXXXXX', DIR=>$FILESTORE, UNLINK=>0);
    my $stored = path($tmp->filename)->to_abs;
    $tmp->close;
    $file->move_to($stored);
    my $key = $stored->basename;
    $FILENAME_CACHE->{$key} = $file->filename;
    Mojo::IOLoop->timer(5 * 60 => sub {
        unlink $stored;
        delete $FILENAME_CACHE->{$key};
    });
    my $url = $c->url_for('download', key => $key)->to_abs;
    $c->render(template => 'uploaded', download_url => "$url");
};

get '/files/:key' => sub ($c) {
    my $key = $c->param('key');
    return $c->reply->not_found unless $key =~ /\A[A-Za-z0-9_]{6}\z/;
    my $file = path("$FILESTORE", $key)->to_abs;
    return $c->reply->not_found unless -f $file;
    my $filename = $FILENAME_CACHE->{$key};
    $c->res->headers->content_type('application/octet-stream');
    $c->res->headers->content_disposition('attachment; filename='.quote($filename));
    $c->reply->file($file);
} => 'download';

app->max_request_size($MAX_FILE_SIZE + 2048);
app->start;

1;

__DATA__

@@ not_found.html.ep
Page not found

@@ form.html.ep
<!doctype html>
<html>
 <body>
  <p>Upload a file to get a shareable download link. Files are deleted after 5 minutes.</p>
  <form action="/upload" method="post" enctype="multipart/form-data">
   <input type="file" name="file">
   <button type="submit">Upload</button>
  </form>
 </body>
</html>

@@ uploaded.html.ep
<!doctype html>
<html>
 <body>
  <p>File saved successfully</p>
  <p><a href="<%= $download_url %>"><%= $download_url %></a></p>
  <p>This file will only be downloadable for 5 minutes.</p>
 </body>
</html>
