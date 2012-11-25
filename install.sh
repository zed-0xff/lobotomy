#!/bin/sh

# required gems
GEMS="nanoc3 RedCloth coderay systemu kramdown haml nokogiri"

# common packages to install in all distros
PKGS=

#################################################################

askrun(){
    echo
    while true; do
            echo -n "run \"$CMD\" [Y/n]?"
            read INPUT
            [ -z $INPUT ] && INPUT=y
            case $INPUT in
                    [Yy]* ) echo running...; $CMD; break;;
                    [Nn]* ) break;;
            esac
    done
}

command -v gem >/dev/null 2>&1 || PKGS="$PKGS rubygems"

# installing packages

CMD=
if [ -f /etc/gentoo-release -a -x /usr/bin/emerge ]; then
	echo "[.] Gentoo detected"
        command -v pygmentize >/dev/null 2>&1 || PKGS="$PKGS pygments"
        [ -n "$PKGS" ] && CMD="emerge -tva ${PKGS# }"

elif [ -f /etc/lsb-release -a -x /usr/bin/apt-get ]; then
	echo "[.] Ubuntu detected"
        command -v pygmentize >/dev/null 2>&1 || PKGS="$PKGS python-pygments"
	PKGS="$PKGS libxml2-dev libxslt1-dev"
        [ -n "$PKGS" ] && CMD="apt-get install ${PKGS# }"
else
	echo "[?] could not detect distro"
        echo
        if ! command -v pygmentize >/dev/null 2>&1; then
            # 'pygmentize' command absent
            echo "Please install 'pygments' app from your distro repository for syntax hilite"
        fi
        if ! command -v gem >/dev/null 2>&1; then
            # 'gem' command absent
            echo "Please install 'rubygems' app from your distro repository and rerun this script"
            echo "or manually install following gems: $GEMS"
            exit 1
        fi
fi

if [ -n "$CMD" ]; then
    [ $USER != root ] && CMD="sudo $CMD"
    askrun
fi

# installing gems

CMD="gem install $GEMS --no-ri --no-rdoc"

if [ $USER != root ]; then
    while true; do
            echo
            echo "using sudo will install gems system-wide"
            echo "NOT using sudo will install gems for current user only"
            read -p "use sudo when installing gems [Y/n]?" INPUT
            [ -z $INPUT ] && INPUT=y
            case $INPUT in
                    [Yy]* ) CMD="sudo $CMD"; break;;
                    [Nn]* ) break;;
            esac
    done
fi

askrun

