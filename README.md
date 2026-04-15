

`make fetch` stores sources in /src.
`make rebuild` wipes /output/src, then copies from /src/src to /output/src and builds all libraries and ffmpeg.
`make ffmpeg` rebuilds ffmpeg from sources in /output/src/ffmpeg.

## SSH agent forwarding for private fetches

The Docker service forwards the host SSH agent socket so `git@...` remotes can be fetched from inside the container.

Security note: this does not copy your private key into the container, but any process in the container that can access the forwarded agent socket can ask the host agent to authenticate while the container is running.

Safer usage:
- use short-lived containers (`docker compose run --rm`)
- load only a dedicated limited-scope key before fetch
- prefer passphrase-protected keys
- avoid running untrusted scripts/dependencies in that container

