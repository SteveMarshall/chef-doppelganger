# Chef Doppelganger

Chef Doppelganger is a Chef server backed by git repositories for cookbooks.

It's useful when you want to offer a Chef server for cookbooks whose code is in git repositories, but don't want to host a fully-fledged Chef server. It's intended to be simple, Chef 11 compliant, easy to run and fast to start. It is NOT intended to be secure, scalable, or performant. It is entirely read-only, and has no idea about how to update its local cookbooks (it assumes you know how to update bare git repositories).

## Todo

- Installation/usage instructions
- Gemify
