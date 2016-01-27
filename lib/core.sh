#!/usr/bin/env bash

WHICH_BIN=/bin/which
SED_BIN=$($WHICH_BIN sed)
WGET_BIN=$($WHICH_BIN wget)
TAR_BIN=$($WHICH_BIN tar)

show_usage() {
    cat << EOM
Usage:
    ${PHP_BAND_NAME} [option] [...]
Where option in
    -h or --help : displays this help  
    -v or --version : displays php_band version
    --download php_version : download a php version from source 
    --install php_version : installs a php version from source 
    --src-format gz|bz2|xz : format of downloaded archive (default xz)
    -c or --config file : load file to define genral config
EOM
   exit 1 
}

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

command_version() {
    echo "0.0.1"
    exit 0
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
    arch_filename=$(printf "php-%s.%s.%s%s.tar.%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon" "$src_format" )
}

build_php_src_dirname() {
    php_src_dirname=$(printf "php-%s.%s.%s%s" "$php_version_major" "$php_version_minor" "$php_version_patch" "$php_version_addon" )
}

get_configure_options() {
    php_inst_dir="$INST_DIR/$php_version"
    php_config_options="--disable-all"
    # @todo get per version configuration
}

check_for_source() {
    local host
    local srcfile
    build_source_filename
    srcfile="$ARCH_DIR/$arch_filename"
    [ -f "$srcfile" ] && return
    for i in ${php_prefered_sites[@]}; do
        host="$(apply_shell_expansion "${i%%}")"
        log_info "Attempting to download from $host"
        $WGET_BIN -P "$ARCH_DIR" -O "$srcfile" "$host"
        [ ! -s "$srcfile" -a -f "$srcfile" ] && rm "$srcfile"
        if [ -f "$srcfile" ]; then
            log_info "PHP $php_version has been downloaded"
            return
        fi
    done
    error_exit "Unable to download PHP source" 2
}

extract_source() {
    build_source_filename
    [ -r "$ARCH_DIR/$arch_filename" ] || error_exit "The file $arch_filename is not readable" 3
    $TAR_BIN -xf "$ARCH_DIR/$arch_filename" -C $SRC_DIR
    [ $? -ne 0 ] && error_exit "$arch_filename does not seem to be a valid archive" 3
}


compile_php() {
    echo "Installing $php_version"
    build_php_src_dirname
    cd "$SRC_DIR/$php_src_dirname"
    get_configure_options
    if [ ! -f .configured ]; then
        ./configure \
            --prefix="$php_inst_dir" \
            --exec-prefix="$php_inst_dir" \
            --disable-all \
            $php_config_options
        [ $? -eq 0 ] || error_exit "Configuration of php failed" 3
        touch .configured
    fi
    if [ ! -f .built ]; then
        make
        [ $? -eq 0 ] || error_exit "Compilation of php failed" 3
        touch .built
    fi
    make install
    [ $? -eq 0 ] || error_exit "Installation of php failed" 3
}

