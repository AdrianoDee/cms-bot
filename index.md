---
title: CMS-bot
layout: default
redirect_from:
  - /cmssw/ 
  - /cmssw/index.html
---


# Introduction
cms-bot started as a single script used to drive PR approval and grew to
be the core of the whole release engineering process for CMSSW.

# Setup
To have it working you'll need a `~/.github-token` which can access the
[cms-sw](http://github.io/cms-sw) organization.

# Release integration

- [process-pull-request](https://github.com/cms-sw/cms-bot/blob/master/process-pull-request):
this is the script which updates the status of a CMSSW PR. It parses all the
messages associated to the specified PR and if it spots a transition (e.g. a L2
signature) it posts a message acknowledging what happended, updates the tags
etc. The state of the PR is fully obtained by parsing all the comments, so that
we do not have to maintain our own state tracking DB. It is run by [CMS Github Bot](https://cmssdt.cern.ch/jenkins/job/cms-bot/) in jenkins. 
- [run-pr-tests](https://github.com/cms-sw/cms-bot/blob/master/run-pr-tests): Runs several tests for the pull requests, this includes compilation, unit tests, relvals, and static analysis, among other tests. It is run by [ib-any-integration](https://cmssdt.cern.ch/jenkins/job/ib-any-integration/) in Jenkins.
- [watchers.yaml](https://github.com/cms-sw/cms-bot/blob/master/watchers.yaml):
contains all the information required by `process-pull-requests` to notify
developers when a PR touches the packages they watch.

# Release building
- [process-build-release-request](https://github.com/cms-sw/cms-bot/blob/master/process-build-release-request): script that handles the github issue used to request the build.
- [build-release](https://github.com/cms-sw/cms-bot/blob/master/build-release): script used to build a release which has been requested
through a Github issue.
- [upload-release](https://github.com/cms-sw/cms-bot/blob/master/upload-release): script used to upload a release to the repository. When
the job processing build requests spots a request to upload, it SSH to the
build machine which has the release and executes this script.

For more information see [Automated Builds](automatedBuilds.html)

# Logging
Logging happens at many different level but we are trying to unify things using
Elasticsearch for "live" data from which we dump precomputed views on a
basis.

- [es-templates](https://github.com/cms-sw/cms-bot/tree/master/es-templates): contains the templates for the logged dataes-templates.
- [es-cleanup-indexes](https://github.com/cms-sw/cms-bot/blob/master/es-cleanup-indexes): cleanups old indexes in elasticsearch.

# IB Pages

The IB pages can bee seen [here](https://cmssdt.cern.ch/SDT/html/showIB.html). 

- [summary-of-merged-prs](https://cmssdt.cern.ch/jenkins/job/summary-of-merged-prs/) is the jenkins job that generates and deploys the pages. 
- [report-summary-merged-prs](https://github.com/cms-sw/cms-bot/blob/master/report-summary-merged-prs) is the script that generates the json
  files with the information that the pages show. 

For more information see [IB Pages](IBPages.html)

# Cleanup of cmssdt
- [cleanup-cmssdt](https://cmssdt.cern.ch/jenkins/job/cleanup-cmssdt): takes care of cleaning up disk space in vocms12. 
- [cleanup-cmssdt01](https://cmssdt.cern.ch/jenkins/job/cleanup-cmssdt01): takes care fo cleaning up disk space in cmssdt01. This machine is currently used for the jenkins artifacts.

# Automatic Forward Ports.
- [update-cmssw-7-0-X-branches](https://cmssdt.cern.ch/jenkins/job/update-cmssw-7-0-X-branches/): takes care of forward porting changes between cmsssw and cmssdt branches. It runs [auto-update-git-branches](https://github.com/cms-sw/cms-bot/blob/master/auto-update-git-branches).





