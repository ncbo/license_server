# README

## Generating public/private keys
```
% openssl genrsa -des3 -out private.pem 2048
Generating RSA private key, 2048 bit long modulus
Enter pass phrase for private.pem:
Verifying - Enter pass phrase for private.pem:
% openssl rsa -in private.pem -out public.pem -outform PEM -pubout
```

## Creating and initializing database
```
% rails db:create
% rails db:migrate
% rails db:seed
```

## Removing database
```
% rails db:migrate VERSION=0
% rails db:drop
```

