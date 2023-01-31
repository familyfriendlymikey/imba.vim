# imba.vim

A TUI editor written in Imba. It works but it's incomplete.

I'd love to have an editor that I can customize with Imba but I don't want to be on
the computer more than I already am, and tools like Neovim, Kakoune, and Helix are already
80% as good as it's going to get.

## Development

### Logging

Since this is a TUI app, logging to the console doesn't work.
Logging to a file didn't work either.
So, instead we get the path of another terminal by running:

```sh
tty
# /dev/ttys002
```

Then run dev, redirecting stderr to that terminal:

```sh
npm run dev 2>/dev/ttys002
```
