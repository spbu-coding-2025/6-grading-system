#!/bin/bash -e

function usage() {
	cat <<eof
Usage: $0 [OPTION]...

Automatically submit the student's solution for review on HwProj.
This script uses HWPROJ_AUTH_TOKEN environment variable for HwProj authentication.

Options
	-h, --help               Print this help message and exit.
	-c, --course ID          ID of the course on HwProj.
	                         If not specified, the environment variable HWPROJ_COURSE_ID will be used.
	-t, --task ID            ID of the problem on HwProj.
	                         If not specified, the environment variable HWPROJ_TASK_ID will be used.
	-l, --logins PATH        Specify PATH to the file with students' names and GitHub logins.
	                         If not specified, the environment variable HWPROJ_STUDENTS_PATH will be used.
	-p, --problem NAME       Specify the NAME of the problem that will be used as a prefix for student submodules.
	                         If not specified, the environment variable GH_PROBLEM_NAME will be used.
	-o, --owner NAME         NAME of the GitHub user or organization that owns grading system and students repositories.
	                         If not specified, the environment variable GH_OWNER will be used.
	-s, --submodule NAME     NAME of the student's git submodule.
	                         If not specified, the environment variable GH_SUBMODULE will be used.
	--ci                     Whether the script is working in GitHub Actions.
eof
}

IS_CI=0
while [[ "$1" != "" ]]; do
	case $1 in
		-h|--help)
			usage
			exit 0
			;;
		-c|--course)
			if [[ -z "$2" ]]; then
				echo "ID of the course is required"
				usage
				exit 1
			fi
			HWPROJ_COURSE_ID="$2"
			shift 2
			;;
		-t|--task)
			if [[ -z "$2" ]]; then
				echo "ID of the task is required"
				usage
				exit 1
			fi
			HWPROJ_TASK_ID="$2"
			shift 2
			;;
		-l|--logins)
			if [[ -z "$2" || ! -f "$2" ]]; then
				echo "'$2' is not path to file with students' names and logins"
				usage
				exit 1
			fi
			HWPROJ_STUDENTS_PATH=$(realpath "$2")
			shift 2
			;;
		-p|--problem)
			if [[ -z "$2" ]]; then
				echo "problem name cannot be empty"
				usage
				exit 1
			fi
			GH_PROBLEM_NAME="$2"
			shift 2
			;;
		-o|--owner)
			if [[ -z "$2" ]]; then
				echo "GitHub owner NAME cannot be empty"
				usage
				exit 1
			fi
			GH_OWNER="$2"
			shift 2
			;;
		-s|--submodule)
			if [[ -z "$2" ]]; then
				echo "'$2' is not name of the submodule"
				usage
				exit 1
			fi
			GH_SUBMODULE="$2"
			shift 2
			;;
		--ci)
			IS_CI=1
			shift 1
			;;
		-*|*)
			echo "Unknown argument $1"
			usage
			exit 1
			;;
	esac
done

if [[ -z "$HWPROJ_AUTH_TOKEN" ]]; then
	echo "No hwproj auth token found!"
	usage
	exit 1
fi

if [[ -z "$HWPROJ_COURSE_ID" \
	|| -z "$HWPROJ_TASK_ID" \
	|| ! -f "$HWPROJ_STUDENTS_PATH" \
	|| -z "$GH_PROBLEM_NAME" \
	|| -z "$GH_OWNER" \
	|| -z "$GH_SUBMODULE" ]]; then
	echo "Arguments are invalid"
	usage
	exit 1
fi

# Get student's login
STUDENT_LOGIN="${GH_SUBMODULE#"${GH_PROBLEM_NAME}-"}"

if [[ -n "$IS_CI" ]]; then
	printf "::group::"
fi
echo "Try to submit solution using student's GitHub login"

if curl -X 'POST' --fail-with-body \
  "https://hwproj.ru/api/Solutions/automated/$HWPROJ_COURSE_ID" \
  -H 'accept: */*' \
  -H "Authorization: Bearer $HWPROJ_AUTH_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"taskId\": \"$HWPROJ_TASK_ID\",
  \"taskIdType\": \"Title\",
  \"studentId\": \"$STUDENT_LOGIN\",
  \"studentIdType\": \"GitHub\",
  \"githubUrl\": \"https://github.com/${GH_OWNER}/${GH_SUBMODULE}\",
  \"comment\": \"Автоматизированно\"
}"; then
	if [[ -n "$IS_CI" ]]; then
		printf "\n::endgroup::\n"
	fi
	echo "Submitted successfully"
	exit 0
fi

if [[ -n "$IS_CI" ]]; then
	printf "\n::endgroup::\n"
	printf "::group::"
fi
echo "Try to submit solution using student's name"

STUDENT_NAME=$(awk -v login="$STUDENT_LOGIN" 'BEGIN{FS=","}{ if ($2==login) print$1 }' "$HWPROJ_STUDENTS_PATH")

if curl -X 'POST' --fail-with-body \
  "https://hwproj.ru/api/Solutions/automated/$HWPROJ_COURSE_ID" \
  -H 'accept: */*' \
  -H "Authorization: Bearer $HWPROJ_AUTH_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"taskId\": \"$HWPROJ_TASK_ID\",
  \"taskIdType\": \"Title\",
  \"studentId\": \"$STUDENT_NAME\",
  \"studentIdType\": \"FullName\",
  \"githubUrl\": \"https://github.com/${GH_OWNER}/${GH_SUBMODULE}\",
  \"comment\": \"Автоматизированно\"
}"; then
	if [[ -n "$IS_CI" ]]; then
		printf "\n::endgroup::\n"
	fi
	echo "Submitted successfully"
	exit 0
fi

if [[ -n "$IS_CI" ]]; then
	printf "\n::endgroup::\n"
	printf "::group::"
fi
echo "Try to submit solution using student's HwProj id"

STUDENT_ID=$(awk -v login="$STUDENT_LOGIN" 'BEGIN{FS=","}{ if ($2==login) print$3 }' "$HWPROJ_STUDENTS_PATH")

if curl -X 'POST' --fail-with-body \
  "https://hwproj.ru/api/Solutions/automated/$HWPROJ_COURSE_ID" \
  -H 'accept: */*' \
  -H "Authorization: Bearer $HWPROJ_AUTH_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"taskId\": \"$HWPROJ_TASK_ID\",
  \"taskIdType\": \"Title\",
  \"studentId\": \"$STUDENT_ID\",
  \"studentIdType\": \"Id\",
  \"githubUrl\": \"https://github.com/${GH_OWNER}/${GH_SUBMODULE}\",
  \"comment\": \"Автоматизированно\"
}"; then
	if [[ -n "$IS_CI" ]]; then
		printf "\n::endgroup::\n"
	fi
	echo "Submitted successfully"
	exit 0
fi

if [[ -n "$IS_CI" ]]; then
	printf "\n::endgroup::\n"
fi

echo "Cannot submit solution"
exit 1
