require 'spec_helper'
require 'rspec'

describe GoInstant::Auth::Signer do
  it "doesn't accept nil" do
    expect {
      GoInstant::Auth::Signer.new(nil)
    }.to raise_error(TypeError, 'Signer requires key in base64url or base64 format')
  end

  it "needs base64" do
    expect {
      GoInstant::Auth::Signer.new('!@#$%^&*()')
    }.to raise_error(TypeError, 'Signer requires key in base64url or base64 format')
  end

  it "decodes base64url" do
    signer = GoInstant::Auth::Signer.new('HKYdFdnezle2yrI2_Ph3cHz144bISk-cvuAbeAAA999')
    signer.should_not == nil
  end

  it "decodes base64" do
    signer = GoInstant::Auth::Signer.new('HKYdFdnezle2yrI2/Ph3cHz144bISk+cvuAbeAAA999')
    signer.should_not == nil
  end

  it "handles base64 with padding too" do
    signer = GoInstant::Auth::Signer.new('HKYdFdnezle2yrI2/Ph3cHz144bISk+cvuAbeAAA999=')
    signer.should_not == nil
  end

  it "can compact serialization encode" do
    str = GoInstant::Auth.compact_encode({ :asdf => 42 })
    str.should == 'eyJhc2RmIjo0Mn0' # note: no padding
    decoded = GoInstant::Auth.compact_decode(str)
    expect(decoded).to be_a_kind_of(Hash)
  end

  it "complains if too short" do
    expect {
      GoInstant::Auth::Signer.new('HKY')
    }.to raise_error(StandardError, 'key isn\'t exactly 32 bytes')
  end

  def validate_jwt(jwt, expect_claims, expect_sig)
    parts = jwt.split(/\./)
    parts.size.should == 3

    header = GoInstant::Auth.compact_decode(parts[0])
    print "got header %s" % header.inspect
    header['typ'].should == 'JWT'
    header['alg'].should == 'HS256'

    claims = GoInstant::Auth.compact_decode(parts[1])
    expect(claims).to eql(expect_claims)

    sig = parts[2]
    sig.size.should == 43
    sig.should == expect_sig
  end

  context "with valid key," do
    before do
      secret_key = 'HKYdFdnezle2yrI2_Ph3cHz144bISk-cvuAbeAAA999'
      @signer = GoInstant::Auth::Signer.new(secret_key)
    end

    it "won't accept string user_data" do
      expect {
        @signer.sign('asdfasdf')
      }.to raise_error(GoInstant::Auth::SignerError, 'Signer#sign() requires a user_data Hash')
    end

    it "needs user_data to have an id" do
      user_data = {
        :domain => 'example.com',
        :display_name => 'bob'
      }
      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'missing required key: id')
    end

    it "needs user_data to have a display_name" do
      user_data = {
        :id => 'bar',
        :domain => 'example.com'
      }
      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'missing required key: display_name')
    end

    it "needs user_data to have a domain" do
      user_data = {
        :id => 'bar',
        :display_name => 'bob'
      }
      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'missing required key: domain')
    end

    it "checks that groups is an array, if present" do
      user_data = {
        :id => 'bar',
        :domain => 'example.com',
        :display_name => 'bob',
        :groups => 'nope'
      }
      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'groups must be an Array')
    end

    it "happily signs without groups" do
      user_data = {
        :id => 'bar',
        :domain => 'example.com',
        :display_name => 'bob'
      }

      jwt = @signer.sign(user_data)
      validate_jwt(jwt, {
        'aud' => 'goinstant.net',
        'sub' => 'bar',
        'iss' => 'example.com',
        'dn' => 'bob',
        'g' => []
      }, 'GtNNsSjgB4ubwW4aFQlgT2E1F8UO7VMxf7ppXmBRlGc')
    end

    it 'needs groups to have an id' do
      user_data = {
        :id => 'bar',
        :domain => 'example.com',
        :display_name => 'bob',
        :groups => [
          { :display_name => 'MyGroup' }
        ]
      }

      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'group 0 missing required key: id')
    end

    it 'needs groups to have a display_name' do
      user_data = {
        :id => 'bar',
        :domain => 'example.com',
        :display_name => 'bob',
        :groups => [
          { :id => 99, :display_name => 'Gretzky Lovers' },
          { :id => 1234 }
        ]
      }

      expect {
        @signer.sign(user_data)
      }.to raise_error(GoInstant::Auth::SignerError, 'group 1 missing required key: display_name')
    end

    it 'happily signs with groups' do
      user_data = {
        :id => 'bar',
        :domain => 'example.com',
        :display_name => 'bob',
        :groups => [
          { :id => 1234, :display_name => 'Group 1234' },
          { :id => 42, :display_name => 'Meaning Group' }
        ]
      }

      jwt = @signer.sign(user_data)
      validate_jwt(jwt, {
        'aud' => 'goinstant.net',
        'sub' => 'bar',
        'iss' => 'example.com',
        'dn' => 'bob',
        'g' => [
          { 'id' => 1234, 'dn' => 'Group 1234' },
          { 'id' => 42, 'dn' => 'Meaning Group' }
        ]
      }, '5isd3i1A4so7MwKm0VHWYHuWRy3WwGFipO0kkelNRLU')
    end
  end
end

