# Determine GitHub-related capabilities

#OAUTH_FILE from local.sh
OAUTH_TOKEN=
POST_COMMENT=true
EDIT_COMMENT=true

# repository with the working branch and pull requests
REPOSITORY=cms-sw

# OAuth token to post comments on GitHub
if [ "$OAUTH_FILE" ] && [ -f "$OAUTH_FILE" ]; then
  OAUTH_TOKEN=$(< "$OAUTH_FILE")
else
  echo "OAUTH token not found." 1>&2
  POST_COMMENT=false
fi

# Tools to post comments on GitHub
if ! which "curl" > /dev/null; then
  echo "Command \"curl\" not found." 1>&2
  POST_COMMENT=false
fi

if ! which "jq" > /dev/null; then
  echo "Command \"jq\" not found." 1>&2
  EDIT_COMMENT=false
fi

[ $POST_COMMENT ] || echo "The report will not be posted to GitHub." 1>&2
[ $POST_COMMENT ] && [ $EDIT_COMMENT ] || "Only the final report will be posted to GitHub." 1>&2


function can_post_comment() {
  local ISSUE_NUMBER=$1
  $POST_COMMENT && [ "$ISSUE_NUMBER" ]
}

function can_update_comment() {
  local ISSUE_NUMBER="$1"
  local COMMENT_ID="$2"
  can_post_comment $ISSUE_NUMBER && $EDIT_COMMENT && [ "$COMMENT_ID" ]
}

# Post a comment to a GitHub issue
#
# Usage:
#   post_comment ISSUE BODY
#
# Any format accepted by curl is valid for BODY. For example,
# the format "@FILE" will use the content of FILE.
#
# Returns the comment id for further editing
#
function post_comment() {
  local ISSUE_NUMBER=$1
  can_post_comment $ISSUE_NUMBER || return
  local BODY="$2"       # body of the message, wrapped in JSON format (see https://developer.github.com/v3/issues/comments/ )
  local RESPONSE
  if ! RESPONSE=$(curl -s -S -H "Authorization: token $OAUTH_TOKEN" -X "POST" "https://api.github.com/repos/cms-patatrack/cmssw/issues/$ISSUE_NUMBER/comments" -d "$BODY"); then
    # failed; disable further posting
    POST_COMMENT=false
    EDIT_COMMENT=false
  elif $EDIT_COMMENT; then
    # success; return the comment id for further editing
    echo "$RESPONSE" | jq ".id"
  fi
}

# Update a comment on a GitHub issue
#
# Usage:
#   update_comment ISSUE COMMENT BODY
#
# Any format accepted by curl is valid for BODY. For example,
# the format "@FILE" will use the content of FILE.
#
function update_comment() {
  local ISSUE_NUMBER=$1
  local COMMENT_ID="$2"
  can_update_comment $ISSUE_NUMBER $COMMENT_ID || return
  local BODY="$3"       # body of the message, wrapped in JSON format (see https://developer.github.com/v3/issues/comments/ )
  local RESPONSE
  if ! RESPONSE=$(curl -s -S -H "Authorization: token $OAUTH_TOKEN" -X "PATCH" "https://api.github.com/repos/cms-patatrack/cmssw/issues/comments/$COMMENT_ID" -d "$BODY"); then
    # failed; disable further posting
    POST_COMMENT=false
    EDIT_COMMENT=false
  fi
}

function upload_final_report() {
  local ISSUE_NUMBER=$1
  local COMMENT_ID="$2"
  local JSON=$(mktemp -p $BASE report.XXXXXXXXXX.json)
  {
    echo -e -n '{\n    "body": "'
    cat $BASE/report.md | tr '\n' '\r' | sed -e's/\r/\\r\\n/g' -e's/"/\\"/g'
    echo -e '"\n}'
  } > $JSON
  if can_update_comment $ISSUE_NUMBER $COMMENT_ID; then
    update_comment $ISSUE_NUMBER $COMMENT_ID "@$JSON"
  elif can_post_comment $ISSUE_NUMBER; then
    post_comment   $ISSUE_NUMBER "@$JSON"
  fi
  rm -f $JSON
}

function upload_report() {
  local ISSUE_NUMBER=$1
  local COMMENT_ID="$2"
  local JSON=$(mktemp -p $BASE report.XXXXXXXXXX.json)
  {
    echo -e -n '{\n    "body": "'
    cat $BASE/report.md | tr '\n' '\r' | sed -e's/\r/\\r\\n/g' -e's/"/\\"/g'
    echo -e "\\\r\\\n\\\r\\\n:construction: Validation running at $(hostname):$BASE ...\"\n}"
  } > $JSON
  if can_update_comment $ISSUE_NUMBER $COMMENT_ID; then
    update_comment $ISSUE_NUMBER $COMMENT_ID "@$JSON"
  elif can_post_comment $ISSUE_NUMBER; then
    post_comment   $ISSUE_NUMBER "@$JSON"
  fi
  rm -f $JSON
}

function is_PR() {
  local PR="$1"
  # check for a numerical (decimal) value
  [ "$(echo "$PR" | sed -e's/^[1-9][0-9]*//')" ] && return 1
  # check for a valid issue which is also a pull request
  curl -s -S -H "Authorization: token $OAUTH_TOKEN" -X "GET" "https://api.github.com/repos/cms-patatrack/cmssw/issues/$PR" | grep -q "pull_request"
}

function filter_PRs() {
  local PR=
  for PR in "$@"; do
    if is_PR $PR; then
      echo $PR
    fi
  done
}
