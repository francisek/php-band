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
+ switches to php tource directory
+ reads per-version configuration
+ if not already, configures php:
    + runs the pre_configure_php function
    + runs configure
    + runs the post_configure_php function if configure was successfull
    + marks the version as configured
+ if not already compiled
    + runs the pre_compile_php function
    + compiles php
    + runs the post_compile_php function if compilation was successfull
    + marks the version as built
+ installs php to inst/<version>

# Custom configuration

# How it works

You can define custom configuration to plot any version.
The version-independant configurations reside in the *config* directory.
The you can plot a specific version configuration in a version-like subtree of the *config* directory.
To get it clear, look at this example of config tree:

```
./config
  + configure-php.sh
  + 5/
    + configure-php.sh
    + 6/
      + configure-php.sh
```

php-band will use first *./config/configure-php.sh* for any version.
Then if major version is 5, *./config/5/configure-php.sh* overrides the previous configuration.
Then if major version is 5 and minor version is 6, *.config/5/6/configure-php.sh* overrides the previous configuration.
And so on ...

# What you can do

Each version-matching *configure-php.sh* file is sourced into php-band with the version components as arguments (major, minor, patch and addon).
You can define some variables and functions to customize the version you are installing.

## Alterable variables and functions

+ *php_config_options* takes any argument that php's *configure* accepts except "--prefix" and "--exec-prefix".
Its default value is defined to "--disable-all".
+ *pre_configure_php()* is called before php's *configure*
+ *post_configure_php()* is called after a successfull php's *configure*
+ *pre_compile_php()* is called before php's *make*
+ *post_compile()* is called after a successfull php's *make*

## Readonly variables

Those variables can be used but should not be modified:

+ *INST_DIR* Directory for all installations
+ *SRC_DIR* Directory for all sources
+ *php_inst_dir* Directory into wich the current php will installed

