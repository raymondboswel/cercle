# Cercle CRM for Trello lovers - Phoenix & Vuejs 

Cercle is a CRM for smart people who need to manage a database of contacts and get things done.

Easy to keep track of your sales, partnerships, support tickets, onboarding clients. 

[Try Cercle Today. Click here: http://www.cercle.co/register](http://www.cercle.co/register)

## Why Cercle?
- realtime
- visual like Trello
- simple
- API ready
- open source
- free

## Features
- Each Card can be linked to several contacts
- Card Contact Tags
- Card Contact Organization
- Card Attachements
- Card Tasks
- Card Comments
- Card Email Notification System for team member
- Import CSV
- Export CSV 
- Board Timeline on a sidebar
- Board Archive/Unarchive
- Oauth for API in Zapier


## Changelog

### V1.1 (TBD)
#### New Features
- UX improvements so we can use Card without contacts (Trello Clone feature)
- Notification system for task due date & Card due date

### V1.0 - June 2017
- Oauth Integration with Zapier
- Add Full name option during CSV Import



## To install Cercle on Local

You need to setup a postgresql DB version 9.5

1. Rename to dev.secret_example.exs to dev.secret.exs
2. Fill out the parameters
3. Run the migration
4. You're good to go!

## To Install Cercle into heroku
1. mix phoenix.gen.secret
2. heroku config:set SECRET_KEY_BASE="your_key_here"
3. heroku config:set POOL_SIZE=18
4. add others parameters from dev.secret into Heroku config:set
5. You're good to go!

## Using Docker For Development
1. Given you already have docker and docker-compose installed on your machine, Simply run these following commands:
```
# Build all and pull images and containers
docker-compose build
# Build application dependencies.
# This will set permission to allow our build script to run.
chmod +x build
./build
# Build the Docker image and start the `web` container, daemonized
docker-compose up -d web
```

## Contribution
Feel free to send your PR with proposals, improvements or corrections!

## License
Copyright © 2016-2017 AK Cercle Inc.

Licence LGPL v3.


