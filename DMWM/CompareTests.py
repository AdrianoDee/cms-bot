#! /usr/bin/env python

from __future__ import print_function

import glob
import os
import sys
import xunitparser
import pdb # REMOVE

from github import Github

testResults = {}

# Parse all the various nose xunit test reports looking for changes

for kind, directory in [('base','./MasterUnitTests/'), ('test', './LatestUnitTests/')]:
    for xunitFile in glob.iglob(directory + '*/nosetests-*.xml'):

        ts, tr = xunitparser.parse(open(xunitFile))
        for tc in ts:
            testName = '%s:%s' % (tc.classname, tc.methodname)
            if testName in testResults:
                testResults[testName].update({kind : tc.result})
            else:
                testResults[testName] = {kind : tc.result}

# Generate a Github report of any changes found

issueID = None

if 'ghprbPullId' in os.environ:
    issueID = os.environ['ghprbPullId']

message = 'Unit test changes for pull request %s:\n' % issueID
changed = False
failed = False
errorConditions = ['error']

for testName, testResult in testResults.items():
    if 'base' in testResult and 'test' in testResult:
        if testResult['base'] != testResult['test']:
            changed = True
            message += "* %s changed from %s to %s\n"  % (testName, testResult['base'], testResult['test'])
            if testResult['test'] in errorConditions:
                failed = True
    elif 'test' in testResult:
        changed = True
        message += "* %s was added. Status is %s\n"  % (testName, testResult['test'])
        if testResult['test'] in errorConditions:
            failed = True
    elif 'base' in testResult:
        changed = True
        message += "* %s was deleted. Prior status was %s\n"  % (testName, testResult['base'])


gh = Github(os.environ['DMWMBOT_TOKEN'])

repoName = '%s/%s' % (os.environ['WMCORE_REPO'], 'WMCore') # Could be parameterized

issue = gh.get_repo(repoName).get_issue(int(issueID))

if not changed:
    message = "No changes to unit tests for pull request %s\n"  % issueID

issue.create_comment('%s' % message)

if failed:
    sys.exit(1)
