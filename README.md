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

First of all, you can tell php-band to work in another directory than it's install dir by setting the environment variable PHP_BAND_ASSETS_DIR. This directory will be used to :

+ read custom configurations (in *config*)
+ download and extract php archives (in *src*)
+ install php versions (in *inst*)

What does php-band is :

+ check the validity of the version
+ if it does not exist, attempts to download the php archive from a list of prefered sites
+ if the php source directory does not exist, extract it from the archive into src directory
+ switches to php source directory
+ reads per-version configuration 
+ if not already done or any configuration is newer that marker file, configures php:
    + runs the *pre_configure_php()* function
    + runs configure
    + runs the *post_configure_php()* function if configure was successfull
    + marks the version as configured
+ if not already compiled or configuration marker file is newer than built marker
    + runs the *pre_compile_php()* function
    + compiles php
    + runs the *post_compile_php()* function if compilation was successfull
    + marks the version as built
+ installs php to inst/<version>
+ runs *post_install_php()* function if installation was successfull

# Custom configuration

## How it works

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
Then if major version is 5 and minor version is 6, *.config/5/6/configure-php.sh* definitions will overrides the previous configuration.
And so on ...

## What you can do

Each version-matching *configure-php.sh* file is sourced into php-band with the version components as arguments (major, minor, patch and addon).
You can define some variables and functions to customize the version you are installing.

## Alterable variables and functions

+ *php_band_php_config_options* takes any argument that php's *configure* accepts except "--prefix" and "--exec-prefix".
Its default value is defined to "--disable-all".
+ *pre_configure_php()* is called before php's *configure*
+ *post_configure_php()* is called after a successfull php's *configure*
+ *pre_compile_php()* is called before php's *make*
+ *post_compile_php()* is called after a successfull php's *make*
+ *post_install_php()* is called after a successfull php's *make install*, usefull to create default config files

The pre_\* and post_\* functions are called with the working directory set to the php source directory.

## Readonly variables

Those variables can be used but should not be modified:

+ *PHP_BAND_INST_DIR* Directory for all installations
+ *PHP_BAND_SOURCE_DIR* Directory for all sources
+ *php_band_php_install_dir* Directory into wich the current php will installed
+ *php_version* The full php version string (for example 5.6.3RC2)
+ *php_version_major* The php major version (for example 5)
+ *php_version_minor* The php minor version (for example 6)
+ *php_version_patch* The php patch version (for example 3)
+ *php_version_addon* The php version (for example RC2)
+ *php_band_php_install_dir* The directory where php is installed

## Usefull functions

Some core functions may be usefull in your functions :

+ *error_exit(error_message [, error_code])* 
  Displays the error_message and exits error_code
+ *log_info(message)* 
  Displays a message
+ *get_per_version_config(base_config_filename [, major_version][, minor_version][,patch_version][, ...])*
  Sources all config files matching the version, starting from the less sibling.
+ *php_band_substitute(filename)*
  Substitute placeholder with corresponding variable value.
  A placeholder is the name of the variable enclosed by double brackets.
  Most usefull placeholders are:
  + {{php_version}} The full php version string (for example 5.6.3RC2)
  + {{php_version_major}} The php major version (for example 5)
  + {{php_version_minor}} The php minor version (for example 6)
  + {{php_version_patch}} The php patch version (for example 3)
  + {{php_version_addon}} The php version (for example RC2)
  + {{php_band_php_install_dir}} The directory where php is installed

# Best practises in writing configuration files

The configuration file
+ must not override protected variables
+ should not create global variables
+ if global variables are created, they should be prefixed with the *CUSTOM_* or *custom_* string (optionaly followed by your suffix)
+ functions not accepted by php-band should be prefixed by *custom_* (optionnally followed by you suffix)

