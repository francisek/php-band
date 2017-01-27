#!/usr/bin/env bash

WHICH_BIN=/bin/which
SED_BIN=$($WHICH_BIN sed)
WGET_BIN=$($WHICH_BIN wget)
TAR_BIN=$($WHICH_BIN tar)

NPROC=$($WHICH_BIN nproc)
MAKE_OPTS="-s"
if [ "$NPROC" != "" ]; then
    MAKE_OPTS="${MAKE_OPTS} -j$($NPROC)"
fi
declare -A PHP_BAND_CUSTOM_PECL_EXTENSIONS
declare -A PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS

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
    [ -d "${PHP_BAND_ASSETS_DIR}" ] || error_exit "The asset directory '${PHP_BAND_ASSETS_DIR}' does not exist"
    [ -d "$PHP_BAND_ARCH_DIR" ] || mkdir "${PHP_BAND_ARCH_DIR}"
    [ -d "$PHP_BAND_CONFIG_DIR" ] || mkdir "${PHP_BAND_CONFIG_DIR}"
    [ -d "$PHP_BAND_INST_DIR" ] || mkdir "${PHP_BAND_INST_DIR}"
    [ -d "$PHP_BAND_SOURCE_DIR" ] || mkdir "${PHP_BAND_SOURCE_DIR}"
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
    declare PHP_BAND_DOLLAR='$'
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}

# Subst {{varname}} with ${varname} 
# If no variable with that name exists, the placeholder is substed with empty string
php_band_substitute() {
    local filename="$1"
    local v
    sed -r -i -e "s/\\\$/\${PHP_BAND_DOLLAR}/g" "${filename}"
    v=$(sed -r -e "s/\{\{([^\}]+)\}\}/\${\1:-}/g" "${filename}")
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

php_band_check_newer() {
  local refFile="$1"
  local testFile="$2"
  if [ ! -f "${refFile}" ]; then
    return
  fi
  if [ ! -f "${testFile}" ]; then
    return
  fi
  if [ "${testFile}" -nt "${refFile}" ]; then
    rm "${refFile}"
  fi
}

get_per_version_config() {
    local base_config_file=$(basename "$1")
    local config_dir=$(dirname "$1")
    local refFile="$PHP_BAND_SOURCE_DIR/"$(php_band_build_php_source_dirname)"/.configured"
    shift
    local x="$*"
    if [ -f "$config_dir/${base_config_file}" ]; then
      source "$config_dir/$base_config_file" $x
      php_band_check_newer "${refFile}" "${config_dir}/${base_config_file}"
    fi
    while [ $# -gt 0 -a "$1" != "" ]; do
        config_dir="$config_dir/$1"
        if [ -f "$config_dir/${base_config_file}" ]; then
          source "$config_dir/${base_config_file}" $x
          php_band_check_newer "${refFile}" "${config_dir}/${base_config_file}"
        fi
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

php_band_get_php_extension_dir() {
    if [ -x "${php_band_php_install_dir}/bin/php-config" ]; then
        php_band_php_extension_dir=$(${php_band_php_install_dir}/bin/php-config --extension-dir)
    else
        php_band_php_extension_dir=''
    fi
}

php_band_pecl_add_package() {
    local package="$1"
    local user_input=$2
    if [ -z "${package}" ]; then
        echo "Package name is mandatory"
        return 1
    fi
    PHP_BAND_CUSTOM_PECL_EXTENSIONS[$package]=$user_input
    return 0
}

php_band_pecl_remove_package() {
    local package="$1"
    if [ -z "${package}" ]; then
        echo "Package name is mandatory"
        return 1
    fi
    unset PHP_BAND_CUSTOM_PECL_EXTENSIONS[$package]
    return 0
}

php_band_pecl_build_extension() {
    local ext_channel="$1"
    local user_input="${2}"
    log_info "Building pecl extension ${ext_channel}"
    echo "${user_input}" | ${php_band_php_install_dir}/bin/pecl install "${ext_channel}" # > /dev/null
    [ -z $? ] || log_info "Extension building failed"
}

php_band_pecl_build() {
    local cwd="$(pwd)"
    echo "Pecl Extensions to install : ${!PHP_BAND_CUSTOM_PECL_EXTENSIONS[@]}"
    for pecl_channel in ${!PHP_BAND_CUSTOM_PECL_EXTENSIONS[*]} ; do
        echo "Pecl extension $pecl_channel requested"
		cd "$cwd"
        custom_build_pecl_extension "$pecl_channel" "${PHP_BAND_CUSTOM_PECL_EXTENSIONS[${pecl_channel}]}"
    done
    cd "$cwd"
}

php_band_external_add() {
    local name="$1"
    local args=("${@:2}")
    if [ -z "$name" ]; then
        echo "External name is required"
        return 1
    fi
    PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[$name]=${args[*]}
    return 0
}

php_band_external_remove() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "External name is required"
        return 1
    fi
    unset PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[$name]
    return 0
}

php_band_external_build() {
    local cwd="$(pwd)"
    echo "External Extensions to install : ${!PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[@]}"
    for ext_et in ${!PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[*]} ; do
        echo "Building extension $ext_et with ${PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[$ext_et]}"
		cd "$cwd"
        command_to_run="extension_${ext_et}"
        if [ "$(type -t "$command_to_run")" = "function" ]; then
            command_params=${PHP_BAND_CUSTOM_EXTERNAL_EXTENSIONS[$ext_et]}
            $command_to_run ${command_params[@]}
        fi
    done
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
    php_band_check_newer ".configured" "$0"
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
    php_band_check_newer ".built" ".configured"
    if [ ! -f .built ]; then
        make clean
        pre_compile_php
        make ${MAKE_OPTS}
        [ $? -eq 0 ] || error_exit "Compilation of php failed" 3
        post_compile_php
        touch .built
    fi
    make install
    [ $? -eq 0 ] || error_exit "Installation of php failed" 3
    php_band_get_php_extension_dir
    post_install_php
    php_band_pecl_build
    php_band_external_build
}

