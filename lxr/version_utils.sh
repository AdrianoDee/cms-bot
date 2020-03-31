#!/bin/bash
function sort_version()
{
  grep    '_X_' ${1} | tr '_' ' ' | sort -rn --key 2,3 | tr ' ' '_' | uniq  > ${1}.new
  grep -v '_X_' ${1} | tr '_' ' ' | sort -rn --key 2,3 | tr ' ' '_' | uniq >> ${1}.new
  mv ${1}.new ${1}
}

function delete_version()
{
  if [ $(grep "^${2}$" ${1} | wc -l) -gt 0 ] ; then
    grep -v "${2}$" $1 > $1.new
    mv ${1}.new ${1}
  fi
}

