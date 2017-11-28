#!/usr/bin/env python

from releases import *
from categories import *
import yaml
import re
# Validate the schema of watchers.

KEY_RE = "^[^@]+"
VALUE_RE = "[A-Za-z0-0.*+]"

w = yaml.load(open("watchers.yaml", "r"))
assert(type(w) == dict)
for (key, value) in w.items():
  assert(type(key) == str)
  assert(re.match(KEY_RE, key))
  assert(type(value) == list)
  for x in value:
    assert(type(x) == str)
    assert(re.match(VALUE_RE, x))


assert(CMSSW_CATEGORIES)
assert(type(CMSSW_CATEGORIES) == dict)

PACKAGE_RE = "^([A-Z][0-9A-Za-z]*/[a-zA-Z][0-9A-Za-z]*|.gitignore|.clang-[^/]+)$"

for (key, value) in CMSSW_CATEGORIES.items():
  assert(type(key) == str)
  assert(type(value) == list)
  if key == "externals":
    assert(len(value)>0)
    continue
  for p in value:
    assert(type(p) == str)
    assert(re.match(PACKAGE_RE, p))

w = yaml.load(open("super-users.yaml", "r"))

assert(type(w) == list)
for p in w:
  assert(type(p) == str)
  assert(re.match(KEY_RE, p))
