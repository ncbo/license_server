# README

## Generating public/private keys
```
% openssl genrsa -des3 -out private.pem 2048
Generating RSA private key, 2048 bit long modulus
Enter pass phrase for private.pem:
Verifying - Enter pass phrase for private.pem:
% openssl rsa -in private.pem -out public.pem -outform PEM -pubout
```

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
