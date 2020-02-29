# README

## Generating public/private keys
```
% openssl genrsa -out keys/private.pem 2048
% openssl rsa -in keys/private.pem -out keys/public.pem -outform PEM -pubout
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

## Setup crontab
```
% bundle exec whenever --update-crontab --set environment='production'
% crontab -l
```


