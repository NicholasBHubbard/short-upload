# short-upload

Upload a file and share a download link. Files are automatically deleted after 5 minutes.

This project is intended for personal use and is not production-ready.

# Dependencies

- Perl 5.20 or newer
- Mojolicious
- IO::Socket::SSL (optional, for HTTPS)

# Deployment

Run as a user service with Podman and systemd:

```sh
podman build -t short-upload .
install -Dm644 short-upload.container ~/.config/containers/systemd/short-upload.container
systemctl --user daemon-reload
systemctl --user start short-upload
```

Open <http://localhost:8080>. To use <http://localhost:9090> instead, set `PublishPort=9090:8080` in `short-upload.container` before installing it.

HTTP is unencrypted. For public use configure HTTPS.

To start at boot and keep running after logout, run `loginctl enable-linger`.

# License

MIT
