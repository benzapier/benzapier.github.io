#!/bin/sh

# Create a test Zap from your local command line!
# This script gathers up a bunch of info about the CLI app
#    in the current working dir, and tells the developer_cli
#    monolith to create a brand new Zap that's configured
#    for testing the specific trigger/search/action
#    that you specify
#
# Please drop by #team-dev-platform if you have any questions,
#    thoughts, or suggestions.  Thanks!

set -e

SCRIPT_VERSION='2022-07-22'

showHelp() {
  echo "Zapier CLI for Creating Test Zap(s), v$SCRIPT_VERSION"
  echo "Please provide at least two params:"
  echo "  1.  trigger|search|action    (selects what type of step you're testing)"
  echo "  2.  key                      (the key of the thing you're testing, like 'new_foo')"
  echo "Then add any additional key=value stuff for the step's params, like this:"
  echo "      someKey=someValue"
  echo "      color=blue"
  echo "      aNumber=123"
}

checkForUpdate() {
  echo "coming soon ..."
}

if [ $# -eq 1 -a $1 = '-v' ]; then
  echo $SCRIPT_VERSION
  exit 0
fi

if [ $# -lt 2 ]; then
  showHelp
  exit 1
fi

stepType=$1
stepKey=$2

if [ ! -f ~/.zapierrc ]; then
  echo "Unable to locate your .zapierrc file, please run 'zapier login'"
  exit 1
fi
# note to self: xargs helps trim excess whitespace from stuff
deployKey=`grep deployKey ~/.zapierrc | cut -f4 -d\" | xargs`

if [ ! -f package.json ]; then
  echo "Unable to locate your app's 'package.json' file in the current directory."
  echo "Please change directory, to the same dir/folder that contians your app's 'package.json' file."
  exit 1
fi
appVersion=`head package.json | grep version | cut -f4 -d\" | xargs`

if [ ! -f .zapierapprc ]; then
  echo "Unable to locate your app's '.zapierapprc' file in the current directory."
  echo "Please change directory, to the same dir/folder that contians your app's '.zapierapprc' file."
  echo "If your app doesn't have a '.zapierapprc', please run 'zapier push' first."
  exit 1
fi
appId=`grep \"id\" .zapierapprc | cut -f2 -d: | cut -f1 -d, | xargs`

BASEURL="https://zapier.com"
if [ -n "$ZAPIER_BASE_ENDPOINT" ]; then
  BASEURL=$ZAPIER_BASE_ENDPOINT
fi
URLPATH="api/platform/cli/apps/$appId/zaps/$appVersion"
URL="$BASEURL/$URLPATH"

# create a var that contains all the 'param' key-value stuff (if any)
params=""
shift 2
while [ $# -gt 0 ]; do
  params="$params -d param=$1"
  shift
done

echo "Creating a Zap for app-version $appVersion, using the $stepType \"$stepKey\""

set +e
result=`curl $URL --no-progress-meter -H "x-deploy-key: $deployKey" -X POST -d stepType=$stepType -d stepKey=$stepKey $params`
if [ $? -gt 0 ]; then
  echo "Error communicating with the server"
else
  echo "$result"
fi

