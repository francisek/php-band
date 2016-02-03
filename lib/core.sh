#!/usr/bin/env bash

WHICH_BIN=/bin/which
SED_BIN=$($WHICH_BIN sed)
WGET_BIN=$($WHICH_BIN wget)
TAR_BIN=$($WHICH_BIN tar)


error_exit() {
    local msg=$1
    local code=$2
    echo -e "\033[41;37m$msg\033[0m"
    [ -n $code ] || code=1
    exit $code
}

php_band_multicommand_error() {
    error_exit "You must specify exactly one command" 2
}

php_band_unimplemented() {
    echo -e "\033[45;37mUnimplemented $1\033[0m"
    [ -f "$base_config_file.sh" ] && source "$base_config_file.sh" ${version_components[@]}
}

log_info() {
    echo -e "\033[0;30m$1\033[0m"
}

php_band_check_env() {
    [ "" != "$WHICH_BIN" -a -x "$WHICH_BIN" ] || error_exit "No which binary" 1
    [ "" != "$WGET_BIN" -a -x "$WGET_BIN" ] || error_exit "No wget binary" 1
    [ "" != "$SED_BIN" -a -x "$SED_BIN" ] || error_exit "No sed binary" 1
    [ "" != "$TAR_BIN" -a -x "$TAR_BIN" ] || error_exit "No tar binary" 1
}

php_band_parse_version() {
    local ver=$1
    php_version_major=${ver%%.*}
    ver=${ver#$php_version_major.}
    php_version_minor=${ver%%.*}
    ver=${ver#$php_version_minor.}
    php_version_patch=$(echo "$ver" | $SED_BIN -E 's/([0-9]+).*/\1/')
    ver=${ver#$php_version_patch}
    php_version_addon=$ver
    if [ $(printf "%s.%s.%s%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon") != "$1" ]; then
        php_version_major=""
    fi
}
# utilities
php_band_apply_shell_expansion() {
    declare data=$1
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}

# Subst {{varname}} with ${varname}} 
# If no variable with that name exists, the placeholder is substed with empty string
php_band_substitute() {
    local filename="$1"
    local v
    v=$(sed -r -e "s/\{\{([^\}]+)\}\}/\${\1}/g" "$filename")
    v=$(php_band_apply_shell_expansion "$v")
    echo "$v" > "$filename"
}

# check for source
php_band_build_source_filename() {
    printf "php-%s.%s.%s%s.tar.%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon" "$php_band_source_archive_format" 
}

php_band_build_php_source_dirname() {
    printf "php-%s.%s.%s%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon" 
}

get_per_version_config() {
    local base_config_file=$(basename "$1")
    local config_dir=$(dirname "$1")
    shift
    local x="$*"
    [ -f "$config_dir/${base_config_file}" ] && source "$config_dir/$base_config_file" $x
    while [ $# -gt 0 -a "$1" != "" ]; do
        config_dir="$config_dir/$1"
        [ -f "$config_dir/${base_config_file}" ] && source "$config_dir/${base_config_file}" $x
        shift
    done

}

php_band_configure_php() {
    php_band_php_install_dir="$PHP_BAND_INST_DIR/$php_version"
    php_band_php_config_options="--disable-all"
    get_per_version_config "$PHP_BAND_CONFIG_DIR/configure-php.sh" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon"
}

php_band_check_for_source() {
    local host
    local srcfile
    local php_band_archive_filename=$(php_band_build_source_filename) 
    srcfile="$PHP_BAND_ARCH_DIR/$php_band_archive_filename"
    [ -f "$srcfile" ] && return
    for i in ${php_prefered_sites[@]}; do
        host=$(php_band_apply_shell_expansion "${i%%}")
        log_info "Attempting to download from $host"
        $WGET_BIN -P "$PHP_BAND_ARCH_DIR" -O "$srcfile" "$host"
        [ -f "$srcfile" ] && !($TAR_BIN -tf "$srcfile" >& /dev/null) && rm "$srcfile"
        if [ -f "$srcfile" ]; then
            log_info "PHP $php_version has been downloaded"
            return
        fi
    done
    error_exit "Unable to download PHP source" 2
}

php_band_extract_php_source() {
    local php_band_archive_filename=$(php_band_build_source_filename)
    [ -r "$PHP_BAND_ARCH_DIR/$php_band_archive_filename" ] || error_exit "The file $php_band_archive_filename is not readable" 3
    $TAR_BIN -xf "$PHP_BAND_ARCH_DIR/$php_band_archive_filename" -C $PHP_BAND_SOURCE_DIR
    [ $? -ne 0 ] && error_exit "$php_band_archive_filename does not seem to be a valid archive" 3
}

pre_configure_php() {
    # Pre configure can be overriden in specific config files config-php.sh
    return
}

post_configure_php() {
    # Post configure be overriden in specific config files config-php.sh
    return
}

pre_compile_php() {
    # Pre compile can be overriden in specific config files config-php.sh
    return
}

post_compile_php() {
    # Post compile can be overriden in specific config files config-php.sh
    return
}

post_install_php() {
    # Post install can be overriden in specific config files config-php.sh
    return
}


php_band_compile_php() {
    echo "Installing $php_version"
    
    cd "$PHP_BAND_SOURCE_DIR/"$(php_band_build_php_source_dirname)
    php_band_configure_php
    if [ ! -f .configured ]; then
        pre_configure_php
        ./configure \
            --prefix="$php_band_php_install_dir" \
            --exec-prefix="$php_band_php_install_dir" \
            $php_band_php_config_options
        [ $? -eq 0 ] || error_exit "Configuration of php failed" 3
        post_configure_php
        touch .configured
    fi
    if [ ! -f .built ]; then
        pre_compile_php
        make
        [ $? -eq 0 ] || error_exit "Compilation of php failed" 3
        post_compile_php
        touch .built
    fi
    make install
    [ $? -eq 0 ] || error_exit "Installation of php failed" 3
    post_install_php
}

