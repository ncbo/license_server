# README

## Generate public/private keys
```
% openssl genrsa -out keys/private.pem 2048
% openssl rsa -in keys/private.pem -out keys/public.pem -outform PEM -pubout
```

## Create and initialize database
```
% rails db:create
% rails db:migrate
% rails db:seed
```

## Import initial data
```
% rails batch:import_initial_data
```

## Setup crontab
```
% whenever task: bundle exec whenever --clear-crontab
% bundle exec whenever --update-crontab --set environment='production'
% crontab -l
```

## If you ever need to remove the database
```
% rails db:migrate VERSION=0
% rails db:drop
```

