# ruby-goinstant-auth

GoInstant Authentication for Your Ruby Application

[![Build Status](https://magnum.travis-ci.com/goinstant/ruby-goinstant-auth.png?token=fy6GC4GtQkNjSzNF3geU&branch=master)](https://magnum.travis-ci.com/goinstant/ruby-goinstant-auth)

This is an implementation of JWT tokens consistent with what's specified in the
[GoInstant Users and Authentication
Guide](https://developers.goinstant.com/v1/guides/users_and_authentication.html).

This library is not intended as a general-use JWT library; see JWT-php for
that. At the time of this writing, GoInstant supports the [JWT IETF draft
version 8](https://tools.ietf.org/html/draft-ietf-oauth-json-web-token-08).

# Usage

Construct a signer with your goinstant application key. The application key
should be in base64url or base64 string format. To get your key, go to [your
goinstant dashboard](https://goinstant.com/dashboard) and click on your App.

```ruby
require 'goinstant_auth'

signer = GoInstant::Auth::Signer.new(secret_key)
```

You can then use this `signer` to create as many tokens as you want. The
`:domain` parameter should be replaced with your website's domain. Groups are
optional.

```ruby
jwt = signer.sign({
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

This token can be safely inlined into an ERB template

```erb
<script type="text/javascript">
  (function() {
    // using a var like this prevents other javascript on the page from
    // easily accessing or stealing the token:
    var opts = {
      user: "<%= token %>",
      rooms: [ 'room-42' ]
    };
    var url = 'https://goinstant.net/YOURACCOUNT/YOURAPP'

    goinstant.connect(url, opts, function(err, connection) {
      if (err) {
        throw err;
      }
      runYourApp(connection);
    });
  }());
</script>
```

# Legal

&copy; 2013 GoInstant Inc., a salesforce.com company.  All Rights Reserved.

Licensed under the 3-clause BSD license
