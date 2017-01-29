# php-band

[![Circle CI](https://circleci.com/gh/francisek/php-band/tree/master.svg?style=plastic&circle-token=0e2b5681405bbc52e77bce982d74c449b46636d8)]()
[![Code Climate](https://codeclimate.com/github/francisek/php-band/badges/gpa.svg?style=plastic)](https://codeclimate.com/github/francisek/php-band)]()
[![Code Climate](https://img.shields.io/codeclimate/issues/github/francisek/php-band.svg?style=plastic)]()
[![GitHub tag](https://img.shields.io/github/tag/francisek/php-band.svg?style=plastic)]()

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
+ builds pecl extensions
+ builds external extensions

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

## Building extensions

Extensions are built and installed after php itself.

It is of your responsability to provide the loading and parameters of the extension to php, generally by creating an extension_name.ini file in the `${php_band_php_install_dir}/conf.d/` directory.

### Using pecl

You add some pecl extensions to build in your *configure-php.sh* file by using the function *php_band_pecl_add_package*.
It takes the package name as first parameter and eventually a string representing user inputs as second parameter.
The pecl package name must be a string accordingly to [pecl documentation](http://php.net/manual/en/install.pecl.pear.php).
For example to install the xdebug package, use either :

```
php_band_pecl_add_package 'xdebug'
```

or

```
php_band_pecl_add_package 'xdebug-2.5.0'
```

or

```
php_band_pecl_add_package 'pecl.php.net/xdebug-stable'
```

You may know some extensions defined in a lower config file are not compatible with a specific version (for example, xhprof does not work on 7.x).
You can remove the building extension request with the function *php_band_pecl_remove_package* :

```
php_band_pecl_remove_package 'xhprof'
```

### Building custom extensions

You can request building a custom extension with function *php_band_external_add*.
It takes a request identifer string as first parameter. Any other parameter will be passed to a callback function of your own named *extension_<identifier>*.

For example, let's build the extension xhprof. The pecl version builds untin php 5.99.
Our `config/configure-php.sh` may look like:

```bash
#!/bin/bash -e

php_band_pecl_add_package 'xhprof-stable'
```

In the `config/7/configure-php.sh` file we won't install pecl version but the git version from branch 'php7':

```bash
#!/bin/bash -e

php_band_pecl_remove_package 'xhprof-stable'
php_band_external_add 'custom_xhprof' 'https://github.com/RustJason/xhprof.git' 'php7'

# @param $1 Git repository
# @param $2 Git branch
extension_custom_xhprof() {
    local repo="$1"
    local branch="${2:-master}"
    local xhprof_src_dir="${PHP_BAND_SOURCE_DIR}/$(php_band_build_php_source_dirname)/ext/xhprof"

    if [ -f "${php_band_php_extension_dir}/xhprof.so" ]; then
        echo "Xhprof already installed"
        return 0
    fi

    [ -d "$xhprof_src_dir" ] && rm -rf "$xhprof_src_dir"
    git clone --depth 1 --branch "$branch" $repo "${xhprof_src_dir}"
    cd "$xhprof_src_dir/extension"
    ${php_band_php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_band_php_install_dir}/bin/php-config
    make ${MAKE_OPTS} && make install

    echo "extension=${php_band_php_extension_dir}/xhprof.so" > ${php_band_php_install_dir}/conf.d/xhprof.ini
}
```

And finally there is no current branch working with PHP 7.1 line, so our file `config/7/1/configure-php.sh` would look like:

```bash
#!/bin/bash -e

php_band_external_remove 'custom_xhprof'
```

## Readonly variables

Those variables can be used but should not be modified:

+ *PHP_BAND_INST_DIR* Directory for all installations
+ *PHP_BAND_SOURCE_DIR* Directory for all sources
+ *php_band_php_install_dir* Directory into which the current php version will be installed
+ *php_version* The full php version string (for example 5.6.3RC2)
+ *php_version_major* The php major version (for example 5)
+ *php_version_minor* The php minor version (for example 6)
+ *php_version_patch* The php patch version (for example 3)
+ *php_version_addon* The php version (for example RC2)
+ *php_band_php_extension_dir* The directory where php looks extensions for. Available from the post_install_php() stage.

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
  + {{php_band_php_extension_dir}} The directory where php loads its extensions. Available after installation.
+ *php_band_build_php_source_dirname()*
  Returns the php dirname where php sources resides. This is used in conjonction with *${PHP_BAND_SOURCE_DIR}*

# Best practises in writing configuration files

The configuration file
+ must not override protected variables
+ should not create global variables
+ if global variables are created, they should be prefixed with the *CUSTOM_* or *custom_* string (optionaly followed by your suffix)
+ functions not accepted by php-band should be prefixed by *custom_* (optionnally followed by you suffix)

