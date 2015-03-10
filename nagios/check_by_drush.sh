#!/usr/bin/env bash

drush sql-query --extra=--skip-column-names "SELECT count(*) FROM users WHERE name='admin'"
