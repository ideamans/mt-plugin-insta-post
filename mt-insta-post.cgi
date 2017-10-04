#!/usr/bin/perl -w

use strict;
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/plugins/InstaPost/lib" : 'plugins/InstaPost/lib';
use MT::Bootstrap App => 'MT::InstaPost::App';
