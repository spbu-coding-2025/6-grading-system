#!/bin/bash -e

function usage() {
	cat <<eof
Usage: $0 [OPTION]...

Fetch private github submodule.

Options
	-h, --help               Print this help message and exit.
	-a, --auth { SSH | PAT } Specify authentication method. Default is SSH.
	                         If the PAT method is selected, the AUTH_TOKEN environment variable must contain authorization token.
	-s, --submodule NAME     NAME of the git submodule to fetch.
	                         If not specified, the environment variable SUBMODULE_NAME will be used.
eof
}

AUTH_METHOD="SSH"

while [[ "$1" != "" ]]; do
	case $1 in
		-h|--help)
			usage
			exit 0
			;;
		-a|--auth)
			if [[ "$2" != "SSH" && "$2" != "PAT" ]]; then
				echo "'$2' is not AUTH method. Only SSH and PAT are supported."
				usage
				exit 1
			fi
			AUTH_METHOD="$2"
			shift 2
			;;
		-s|--submodule)
			if [[ -z "$2" ]]; then
				echo "'$2' is not name of the submodule"
				usage
				exit 1
			fi
			SUBMODULE_NAME="$2"
			shift 2
			;;
		-*|*)
			echo "Unknown argument $1"
			usage
			exit 1
			;;
	esac
done

if [[ -z "$SUBMODULE_NAME" ]]; then
	echo "Arguments are invalid"
	usage
	exit 1
fi

GIT_EXTRA_CONFIGURATION=()
if [[ "$AUTH_METHOD" = "PAT" ]]; then
	if [[ -z "$AUTH_TOKEN" ]]; then
		echo "AUTH_TOKEN environment variable cannot be empty for PAT authorization method"
		exit 1
	fi
	GIT_EXTRA_CONFIGURATION+=("-c")
	GIT_EXTRA_CONFIGURATION+=("url.https://github.com/.insteadOf=git@github.com:")
	GIT_EXTRA_CONFIGURATION+=("-c")
	GIT_EXTRA_CONFIGURATION+=("http.extraHeader=Authorization: Basic $(printf 'x-access-token:%s' "$AUTH_TOKEN" | base64)")
else
	GIT_EXTRA_CONFIGURATION+=("-c")
	GIT_EXTRA_CONFIGURATION+=("url.ssh://git@github.com:.insteadOf=https://github.com/")
fi

git "${GIT_EXTRA_CONFIGURATION[@]}" submodule update --init "$SUBMODULE_NAME"
