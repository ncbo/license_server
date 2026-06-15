# Characterization test for the license-key crypto contract (lib/util/encryption_util.rb).
#
# Standalone — does NOT load Rails — so it runs on any Ruby version, which lets us
# compare behavior before/after the Ruby 2.7 -> 3.2 / OpenSSL 1.1 -> 3 upgrade.
# The license-key format is an EXTERNAL CONTRACT (deployed appliances verify it),
# so this must keep passing byte-for-byte across the modernization.
#
# Run standalone:
#   ruby test/characterization/encryption_util_test.rb
# Reuse a fixed keypair across runs/versions (for cross-version checks):
#   LS_TEST_PRIVATE_KEY=tmp/xver_priv.pem LS_TEST_PUBLIC_KEY=tmp/xver_pub.pem \
#     ruby test/characterization/encryption_util_test.rb

require 'minitest/autorun'
require 'securerandom'
require_relative '../../lib/util/encryption_util'

class EncryptionUtilTest < Minitest::Test
  # One keypair for the whole run. Use provided test keys if set (so the same pair
  # can be reused across Ruby versions), otherwise generate an ephemeral pair.
  if ENV['LS_TEST_PRIVATE_KEY'] && ENV['LS_TEST_PUBLIC_KEY']
    PRIVATE = File.read(ENV['LS_TEST_PRIVATE_KEY'])
    PUBLIC  = File.read(ENV['LS_TEST_PUBLIC_KEY'])
  else
    _rsa    = OpenSSL::PKey::RSA.new(2048)
    PRIVATE = _rsa.to_pem
    PUBLIC  = _rsa.public_key.to_pem
  end

  # Representative of the real payload "appliance_id;organization;valid_date",
  # plus edges: embedded delimiters, multibyte org name, very long org.
  PAYLOADS = [
    'b5c1a2d3-0000-4000-8000-000000000001;Acme Corp;2027-06-01',
    'id-1;Org; with; semicolons;2027-06-01',
    'idX;Évariste Galois Inc;2030-12-31',
    "u;#{'x' * 1000};2027-06-01",
  ].freeze

  # decrypt returns ASCII-8BIT bytes; compare on bytes to avoid UTF-8/binary
  # encoding mismatches on multibyte org names (a real-world consideration).
  def test_round_trip_decrypts_to_original
    PAYLOADS.each do |p|
      blob = EncryptionUtil.encrypt(PRIVATE, p)
      assert_equal p.b, EncryptionUtil.decrypt(PUBLIC, blob).b,
                   "round-trip failed for #{p[0, 40].inspect}"
    end
  end

  def test_wire_format_is_two_pipe_joined_base64_blobs
    blob  = EncryptionUtil.encrypt(PRIVATE, 'a;b;2027-01-01')
    parts = blob.split('|')
    assert_equal 2, parts.length, 'expected base64(rsa_key)|base64(cipher)'
    parts.each { |b64| assert_match(/\A[A-Za-z0-9+\/=\n]+\z/, b64) }
    parts.each { |b64| Base64.decode64(b64) } # decodes without raising
  end

  def test_random_aes_key_per_call_but_both_decrypt
    p = 'same;payload;2027-01-01'
    a = EncryptionUtil.encrypt(PRIVATE, p)
    b = EncryptionUtil.encrypt(PRIVATE, p)
    refute_equal a, b, 'expected a fresh random AES key each call'
    assert_equal p.b, EncryptionUtil.decrypt(PUBLIC, a).b
    assert_equal p.b, EncryptionUtil.decrypt(PUBLIC, b).b
  end
end
