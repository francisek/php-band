# php-band

<img src="https://circleci.com/gh/francisek/php-band/tree/master.svg?style=shield&circle-token=0e2b5681405bbc52e77bce982d74c449b46636d8" />

A simple bash tool to compile php versions


# Installation

Just clone the repository
```
git clone git@github.com:francisek/php-band
```

# Requirements

To compile a PHP version, you will need:

+ a bash shell with which, tar, sed and wget commands available 
+ any requirement for PHP compilation (<http://php.net/manual/en/install.unix.php>)

# Using php-band

Run
``` 
bin/php-band --help
```
to get help on how to run this tool.

# Running tests

The test suite uses the bats framework.
Install it from repository:

```
git clone --depth 1 git@github.com:sstephenson/bats.git
```
Then run the tests :
```
./bats/bin/bats tests
```

if you want also to fully compile php while testing, you have to set the environment variable PHP_BAND_TEST_COMPILATION.

# The compilation process

What does php-band is :

+ check the validity of the version
+ if it does not exist, attempts to download the php archive from a list of prefered sites
+ if the php source directory does not exist, extract it from the archive into src directory
+ if not already, configures php
+ compiles php
+ installs php to inst/<version>

