#!/bin/bash
# conf
ignores_url="http://srv.quai13.net/wpwned/ignores.txt"
wp_wned_path="$(dirname $0)"
ignores_file="$(mktemp /tmp/wp-wned.ignores.XXXXXXXX)"

# OSX portability: use GNU grep
GREP="grep"
GGREP="$(which ggrep 2>/dev/null)"
if [ -x "$GGREP" ];
then
    GREP="$GGREP"
fi

# OSX portability: use GNU cut
CUT="cut"
GCUT="$(which gcut 2>/dev/null)"
if [ -x "$GCUT" ];
then
    CUT="$GCUT"
fi

# OSX portability: use GNU sed
SED="sed"
GSED="$(which gsed 2>/dev/null)"
if [ -x "$GSED" ];
then
    SED="$GSED"
fi

# default values
DIRECTORY=""
FIND_OPTIONS=""
IGNORE_SLAVES=0
# allowed parameters
OPT_DIRECTORY="--directory"
OPT_FIND_OPTIONS="--find-options"
OPT_IGNORE_SLAVES="--ignore-slaves"
# usage
function usage() {
    cat <<EOF

Find malicious php files in web sites

Options:
    $OPT_DIRECTORY="/path/to/directory"
        Restricts search to specific directory.
        If no specific directory is given, $(basename $0) will default to
        all files actually residing inside /home/*/www directories

    $OPT_FIND_OPTIONS="<find options>"
        Custom find options. Run "man find" for documentation.
        For example: --find-options="-ctime -1"

    $OPT_IGNORE_SLAVES
        Evolix servers specific.
        Ignore directories whose /home/*/state file contains a "STATE=slave" line.

EOF
}
# parse parameters
while [ $# -ne 0 ]
do
    case "$1" in
        $OPT_DIRECTORY=*)
            OPT_DIRECTORY_SIZE="${#OPT_DIRECTORY}"
            DIRECTORY="${1:$OPT_DIRECTORY_SIZE+1}"
            ;;
        $OPT_FIND_OPTIONS=*)
            OPT_FIND_OPTIONS_SIZE="${#OPT_FIND_OPTIONS}"
            FIND_OPTIONS="${1:$OPT_FIND_OPTIONS_SIZE+1}"
            ;;
        $OPT_IGNORE_SLAVES)
            IGNORE_SLAVES="1"
            ;;
        -h|--help|*)
            usage
            rm -f "$ignores_file"
            exit
            ;;
    esac
    shift
done

# get latest ignores file
wget -q "$ignores_url" -O "$ignores_file"
if [ ! -s $ignores_file ];
then
    echo "^$" > $ignores_file
fi
chmod 600 "$ignores_file"

# defaults to a search restricted to files actually residing inside /home/*/www directory
LOCATIONS="$DIRECTORY"
if [[ ( "$DIRECTORY" == "" ) ]];
then
    LOCATIONS="$(find /home -maxdepth 2 -type d -name 'www' | sort | uniq)"
fi
MASTER_LOCATIONS="$LOCATIONS"

# do not search in slave sites if not asked to
if [[ ( "$IGNORE_SLAVES" == "1" ) ]];
then
    SLAVES=$(find "/home" -mindepth 2 -maxdepth 2 -name state | $SED 's/\/state$//g' | xargs -I % $GREP -Hsl 'STATE=slave' "%/state" | $SED 's/state$//g' | sort | uniq)
    SLAVES_PATTERN=$(echo $SLAVES | $SED 's/ /\\|/g')
    if [[ ( "$SLAVES_PATTERN" != "" ) ]];
    then
        MASTER_LOCATIONS=$(echo "$LOCATIONS" | $GREP -v "$SLAVES_PATTERN")
    fi
fi
PHP_FILES_LIST=$(echo "$MASTER_LOCATIONS" | xargs -I % find "%" -type f \( -iname "*.php" -or -iname "*.inc" -or -iname "*.module" -or -iname "*.phtml" \) -size +0 $FIND_OPTIONS)

# redirects stderr to stdin before we go
exec 2>&1

# look for php files in wp-content/uploads (if it exists)
MATCHES_WPCONTENT="$(echo "$PHP_FILES_LIST" | $GREP "wp-content/uploads/" | $GREP -v -f $ignores_file;)"
if [[ ( "$MATCHES_WPCONTENT" != "" ) ]];
then
    echo "PHP files in suspect directories"
    echo "========================"
    echo "$MATCHES_WPCONTENT"
    echo
fi

# look for obvious malicious files (various evals, obfuscated code, strange characters...)
REGEXP_KNOWN_HACKS='_YM82iAN\|$compressed=base64_decode($cookieData);\|r57shell.php\|c999sh_\|preg_match../config/...\$_SERVER..REQUEST_URI.....echo.1..exit\|hacked.by'
REGEXP_INJECTS_1='\beval\b *(.*\(decode\|inflate\|rot13\|qrpbqr\|vasyngr\) *(.*'
REGEXP_INJECTS_2='\(decode\|inflate\|rot13\|qrpbqr\|vasyngr\) *(.*\beval\b *(.*'
REGEXP_INJECTS_3='\(\beval\b\|\bshell_exec\b\|\bsystem\b\|\bproc_open\b\|\bpopen\b\|\bpassthru\b\) *(\$_....'
REGEXP_INJECTS_4='@$_COOKIE *\['
#REGEXP_INJECTS_5='\(.*_POST *\[\|.*_REQUEST *\[\)\{8\}'
REGEXP_OBFUSCATED_1='\s*\$[a-z0-9_]\+=[^[:space:]]\{10,\}.*[^-]\.$'
#REGEXP_OBFUSCATED_2="[:&\*\+,\`\.^_{}()'\"-]\{200\}"
REGEXP_OBFUSCATED_2='[^a-z0-9 	]\{300\}'
REGEXP_STRANGE_CHARS_1='\(\\x[0-9a-z]\{2\}\)\{8,\}'
REGEXP_STRANGE_CHARS_2='\(\\[0-9]\{3\}\)\{8,\}'
MATCHES_REGEX="$(echo "$PHP_FILES_LIST" \
    | xargs -I % $GREP -Haiorn "\($REGEXP_KNOWN_HACKS\)\|\($REGEXP_INJECTS_1\)\|\($REGEXP_INJECTS_2\)\|\($REGEXP_INJECTS_3\)\|\($REGEXP_INJECTS_4\)\|\($REGEXP_OBFUSCATED_1\)\|\($REGEXP_OBFUSCATED_2\)\|\($REGEXP_STRANGE_CHARS_1\)\|\($REGEXP_STRANGE_CHARS_2\)" "%" 2>&1 \
    | $GREP -v ': No such file or directory$' \
    | $GREP -o '^.*\.php:[0-9]*:.\{1,255\}' \
    | $GREP -v -f $ignores_file)"

if [[ ( "$MATCHES_REGEX" != "" ) ]];
then
    echo "Probably malicious files"
    echo "========================"
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_KNOWN_HACKS"     | $SED 's/^/REGEXP_KNOW_HACKS: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_INJECTS_1"       | $SED 's/^/REGEXP_INJECTS_1: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_INJECTS_2"       | $SED 's/^/REGEXP_INJECTS_2: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_INJECTS_3"       | $SED 's/^/REGEXP_INJECTS_3: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_INJECTS_4"       | $SED 's/^/REGEXP_INJECTS_4: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_OBFUSCATED_1"    | $SED 's/^/REGEXP_OBFUSCATED_1: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_OBFUSCATED_2"    | $SED 's/^/REGEXP_OBFUSCATED_2: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_STRANGE_CHARS_1" | $SED 's/^/REGEXP_STRANGE_CHARS_1: /g'
    echo "$MATCHES_REGEX" | $GREP -ai "$REGEXP_STRANGE_CHARS_2" | $SED 's/^/REGEXP_STRANGE_CHARS_2: /g'
    echo
fi

# look for PHP files containing very long strings
REGEXP_TOO_LONG='[^ :]\{255\}[^ :]\{255\}[^ :]\{255\}'
SUBCOMMAND_TOO_LONG="EXCERPT=\"\$($CUT -c 1-1534 '%' | $CUT -c 768-1534 | $GREP -v '^$')\"; echo \"%:\$EXCERPT\"; "
MATCHES_LONG="$(echo "$PHP_FILES_LIST" | xargs -I % sh -c "$SUBCOMMAND_TOO_LONG" 2>&1 \
    | $GREP -v ': No such file or directory$' \
    | $GREP -v '\.php:$' \
    | $GREP -o '^.*\.php:.\{1,255\}' \
    | $GREP -v -f $ignores_file)"
    #| $GREP "$REGEXP_TOO_LONG" \

if [[ ( "$MATCHES_LONG" != "" ) ]];
then
    echo "PHP files containing very long strings"
    echo "======================================"
    echo "$MATCHES_LONG"
    echo
fi

# look for binary code inside PHP files
MATCHES_BINARY="$(echo "$PHP_FILES_LIST" | xargs -I % $GREP -alP '[\x80-\x9f]{3}' "%" 2>&1 \
    | $GREP -v ': No such file or directory$' \
    | $GREP -v -f $ignores_file)"

if [[ ( "$MATCHES_BINARY" != "" ) ]];
then
    echo "PHP files containing binary code"
    echo "================================"
    echo "$MATCHES_BINARY"
    echo
fi

# ignore return codes
rm -f "$ignores_file"
exit 0

# TODO: look for improvements in similar projects : PHP antivirus, sucuri, wordfence, Joomla-Anti-Malware-Scan-Script...
