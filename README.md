# ruby-goinstant-auth

GoInstant Authentication for Your Ruby Application

[![Build Status](https://travis-ci.org/goinstant/ruby-goinstant-auth.png&branch=master)](https://travis-ci.org/goinstant/ruby-goinstant-auth)

This is an implementation of JWT tokens consistent with what's specified in the
[GoInstant Users and Authentication
Guide](https://developers.goinstant.com/v1/security_and_auth/guides/users_and_authentication.html).

This library is not intended as a general-use JWT library.  For a more general
library, see [progrium/ruby-jwt](https://github.com/progrium/ruby-jwt) (but
please note its supported version).
At the time of this writing, GoInstant supports the [JWT IETF draft
version 08](https://tools.ietf.org/html/draft-ietf-oauth-json-web-token-08).

# Installation

```sh
gem install goinstant-auth
```

# Usage

Construct a signer with your goinstant application key. The application key
should be in base64url or base64 string format. To get your key, go to [your
goinstant dashboard](https://goinstant.com/dashboard) and click on your App.

**Remember, the Secret Key needs to be treated like a password!**
Never share it with your users!

```ruby
require 'goinstant/auth'

signer = GoInstant::Auth::Signer.new(secret_key)
```

You can then use this `signer` to create as many tokens as you want. The
`:domain` parameter should be replaced with your website's domain. Groups are
optional.

```ruby
token = signer.sign({
  :domain => 'example.com', # TODO: replace me
  :id => user.id,
  :display_name => user.full_name,
  :groups => [
    {
      :id => 'room-42',
      :display_name => 'Room 42 ACL Group'
    }
  ]
})
```

This token can be safely inlined into an ERB template.  For example, a fairly
basic template for calling [`goinstant.connect`
call](https://developers.goinstant.com/v1/javascript_api/connect.html) might
look like this:

```html
<script type="text/javascript">
  (function() {
    var token = "<%= token %>";
    var url = 'https://goinstant.net/YOURACCOUNT/YOURAPP'

    var opts = {
      user: token,
      rooms: [ 'room-42' ]
    };

    goinstant.connect(url, opts, function(err, conn, room) {
      if (err) {
        throw err;
      }
      runYourApp(room);
    });
  }());
</script>
```

# Methods

## `GoInstant::Auth::Signer`

Re-usable object for creating user tokens.

### `.new(secret_key)`

Constructs a `Signer` object from a base64url or base64 secret key string.

Throws an Error if the `secretKey` could not be parsed.

### `#sign(user_data, extra_headers={})`

Creates a JWT as a JWS in Compact Serialization format.  Can be called multiple
times on the same object, saving you from having to load your secret GoInstant
application key every time.

`user_data` is a Hash with the following required fields, plus any other
custom ones you want to include in the JWT.

- `:domain` - the domain of your website
- `:id` - the unique, permanent identity of this user on your website
- `:display_name` - the name to initially display for this user
- `:groups` - an array of groups, each group requiring:
  - `:id` - the unique ID of this group, which is handy for defining [GoInstant ACLs](https://developers.goinstant.com/v1/security_and_auth/guides/creating_and_managing_acl.html)
  - `:display_name` - the name to display for this group

`extra_headers` is completely optional.  It's used to define any additional
[JWS header fields](http://tools.ietf.org/html/draft-ietf-jose-json-web-signature-11#section-4.1)
that you want to include.

# Technicals

The `sign()` method's `user_data` maps to the following JWT claims.
The authoritative list of claims used in GoInstant can be found in the [Users and Authentication Guide](https://developers.goinstant.com/v1/security_and_auth/guides/users_and_authentication.html#which-reserved-claims-are-required).

- `:domain` -> `iss` (standard claim)
- `:id` -> `sub` (standard claim)
- `:display_name` -> `dn` (GoInstant private claim)
- `:groups` -> `g` (GoInstant private claim)
  - `:id` -> `id` (GoInstant private claim)
  - `:display_name` -> `dn` (GoInstant private claim)
- `'goinstant.net'` -> `aud` (standard claim) _automatically added_

For the `extra_headers` parameter in `sign()`, the `alg` and `typ` headers will
be overridden by this library.

# Contributing

If you'd like to contribute to or modify ruby-goinstant-auth, here's a quick
guide to get you started.

## Development Dependencies

Base dependencies are as follows.

- [ruby](https://www.ruby-lang.org/en/downloads/) >= 1.9.2
- [rubygems](https://rubygems.org/pages/download) >= 2.1

The following gems should then be installed via `gem install`:

- [bundler](http://bundler.io/) >= 1.5
- [rake](http://rake.rubyforge.org/) >= 10.1

## Set-up

```sh
git clone git@github.com:goinstant/ruby-goinstant-auth.git
cd ruby-goinstant-auth

# if you haven't already:
gem install bundler
gem install rake

# then, install dev dependencies:
bundle install
```

## Testing

Testing is done with RSpec.  Tests are located in the `spec/` folder.

To run the tests:

```sh
rake # 'test' is the default
```

## Developer Documentation

You can view the documentation generated by `yard` easily:

```sh
gem install yard
rake doc
open doc/frames.html
```

## Publishing

When publishing `$VERSION` to master.

1. Edit `goinstant-auth.gemspec` and bump the version number
2. `git add *.gemspec && git commit -m '$VERSION'`
3. `git tag $VERSION`
4. `git push --tags origin master`
5. `rake gem`
6. `gem push goinstant-auth-$VERSION.gem` - note that there may be other .gem files hanging around so don't be lazy and specify `*.gem`

Check on https://rubygems.org/gems/goinstant-auth to see that it published.

# Support

Email [GoInstant Support](mailto:support@goinstant.com) or stop by [#goinstant
on freenode](irc://irc.freenode.net/#goinstant).

For responsible disclosures, email [GoInstant Security](mailto:security@goinstant.com).

To [file a bug](https://github.com/goinstant/node-goinstant-auth/issues) or
[propose a patch](https://github.com/goinstant/node-goinstant-auth/pulls),
please use github directly.

# Legal

&copy; 2013 GoInstant Inc., a salesforce.com company.  All Rights Reserved.

Licensed under the 3-clause BSD license
