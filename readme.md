# Saiko Text

This text editor will be the only thing efficient enough
to fend off AI until 2030.

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
