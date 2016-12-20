#!/bin/bash
#
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Script to get a full clone of a Git repository and set it up so that it
# satisifies the SPM dependencies. The resulting repo has the full history,
# rather than the abbreviated history cloned by SPM.
#
# The URL of the repository and the tag must be specified.
#
# This involves:
# - Perform a full clone, appending the tag name to the directory
# - Create a local branch from the tag, with the same name as the tag
# - Check out the tag
# - Set the upstream references to origin
#
# This differs from SPM, which renames the default local branch to the tag.
#

REPO=$1
TAG=$2

if [ -z "$TAG" ]; then
  echo "Usage: $0 <repo_URL> <tag>"
  exit 1
fi

REPONAME=`echo $REPO | awk -F/ '{print $NF}' | sed -e's#.git$##'`

if [ -z "$REPONAME" ]; then
  echo "Error: could not infer repository name from URL"
  exit 1
fi

SPM_DIR="$REPONAME-$TAG"

mkdir -p Packages && cd Packages && git clone $REPO $SPM_DIR && cd $SPM_DIR && git branch $TAG $TAG && git checkout $TAG && git branch --set-upstream-to=origin && cd ../..

