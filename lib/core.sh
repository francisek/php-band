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

multicommand_error() {
    error_exit "You must specify exactly one command" 2
}

unimplemented() {
    echo -e "\033[45;37mUnimplemented $1\033[0m"
    [ -f "$base_config_file.sh" ] && source "$base_config_file.sh" ${version_components[@]}
}

log_info() {
    echo -e "\033[0;30m$1\033[0m"
}

check_env() {
    [ "" != "$WHICH_BIN" -a -x "$WHICH_BIN" ] || error_exit "No which binary" 1
    [ "" != "$WGET_BIN" -a -x "$WGET_BIN" ] || error_exit "No wget binary" 1
    [ "" != "$SED_BIN" -a -x "$SED_BIN" ] || error_exit "No sed binary" 1
    [ "" != "$TAR_BIN" -a -x "$TAR_BIN" ] || error_exit "No tar binary" 1
}

parse_version() {
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
apply_shell_expansion() {
    declare data=$1
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}

# check for source
build_source_filename() {
    printf "php-%s.%s.%s%s.tar.%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon" "$src_format" 
}

build_php_src_dirname() {
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

configure_php() {
    php_inst_dir="$INST_DIR/$php_version"
    php_config_options="--disable-all"
    get_per_version_config "$CONFIG_DIR/configure-php.sh" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon"
}

check_for_source() {
    local host
    local srcfile
    local arch_filename=$(build_source_filename) 
    srcfile="$ARCH_DIR/$arch_filename"
    [ -f "$srcfile" ] && return
    for i in ${php_prefered_sites[@]}; do
        host=$(apply_shell_expansion "${i%%}")
        log_info "Attempting to download from $host"
        $WGET_BIN -P "$ARCH_DIR" -O "$srcfile" "$host"
        [ -f "$srcfile" ] && !($TAR_BIN -tf "$srcfile" >& /dev/null) && rm "$srcfile"
        if [ -f "$srcfile" ]; then
            log_info "PHP $php_version has been downloaded"
            return
        fi
    done
    error_exit "Unable to download PHP source" 2
}

extract_source() {
    local arch_filename=$(build_source_filename)
    [ -r "$ARCH_DIR/$arch_filename" ] || error_exit "The file $arch_filename is not readable" 3
    $TAR_BIN -xf "$ARCH_DIR/$arch_filename" -C $SRC_DIR
    [ $? -ne 0 ] && error_exit "$arch_filename does not seem to be a valid archive" 3
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
    # Pre compile can be overriden in specific config files config-php.sh
    return
}

compile_php() {
    echo "Installing $php_version"
    
    cd "$SRC_DIR/"$(build_php_src_dirname)
    configure_php
    if [ ! -f .configured ]; then
        pre_configure_php
        ./configure \
            --prefix="$php_inst_dir" \
            --exec-prefix="$php_inst_dir" \
            $php_config_options
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
}

