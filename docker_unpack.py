#!/usr/bin/env python
from json import loads
from sys import exit, argv
import hashlib, stat
from os.path import exists, join
from os import makedirs, walk, lstat, chmod
from commands import getstatusoutput as runCmd

def cleanup_exit(msg, tmpdirs=[], image_hash="", exit_code=1):
  if msg:    print msg
  for tdir in tmpdir: runCmd("rm -rf %s" % tdir)
  if image_hash: runCmd("docker rm -f %s" % image_hash)
  exit(exit_code)

def get_docker_token(repo):
  print "Getting docker.io token ...."
  e, o = runCmd('curl --silent --request "GET" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:%s:pull"' % repo)
  if e:
    print o
    exit(1)
  return loads(o)['token']

def get_docker_manifest(repo, tag):
  token = get_docker_token(repo)
  print "Getting manifest for %s/%s" % (repo, tag)
  e, o = runCmd('curl --silent --request "GET" --header "Authorization: Bearer %s" "https://registry-1.docker.io/v2/%s/manifests/%s"' % (get_docker_token(repo), repo, tag))
  if e:
    print o
    exit(1)
  return loads(o)

def fix_mode(full_fname, mode_num, st=None):
  if not st: st = lstat(full_fname)
  n_mode = mode_num*100
  #mode = mode_num + mode_num*10 + n_mode
  old_mode = stat.S_IMODE(st.st_mode)
  if (old_mode & n_mode) == 0:
    new_mode = old_mode | n_mode
    print "Fixing mode of: %s: %s -> %s" % (full_fname, oct(old_mode), oct(new_mode))
    chmod(full_fname, new_mode)

def fix_modes(img_dir):
  # Walk the path, fixing file permissions
  for (dirpath, dirnames, filenames) in walk(img_dir):
    for fname in filenames:
      fix_mode (join(dirpath, fname), 4)
    for dname in dirnames:
      full_dname = join(dirpath, dname)
      st = lstat(full_dname)
      if not stat.S_ISDIR(st.st_mode): continue
      old_mode = stat.S_IMODE(st.st_mode)
      if old_mode & 0111 == 0:
        fix_mode (full_dname, 1, st)
      if old_mode & 0222 == 0:
        fix_mode (full_dname, 2, st)
  return

def create_image_link(outdir, img_sdir, image):
  e, o = runCmd("cd %s; rm -rf %s; mkdir -p %s; rm -rf %s; ln -sf ../%s %s" % (outdir, image, image, image, img_sdir, image))
  if e:
    print o
    exit(1)
  return

def process(image, outdir):  
  container = image.split(":",1)[0]
  tag = image.split(":",1)[-1]
  if container==tag: tag="latest"

  manifest = get_docker_manifest(container,tag)
  hasher = hashlib.sha256()
  for layerinfo in manifest['fsLayers']: hasher.update(layerinfo['blobSum'].split(":")[-1])
  image_hash = hasher.hexdigest()

  img_sdir = join(".images", image_hash[0:2], image_hash[2:])
  img_dir = join(outdir, img_sdir)
  if exists(img_dir):
    create_image_link(outdir, img_sdir, image)
    exit(0)

  print "Starting Container %s" % image
  tmpdir = join(outdir, ".images", "tmp")
  e, o = runCmd('docker run --name %s %s echo OK' % (image_hash,image))
  if e: cleanup_exit(o, [tmpdir], image_hash)

  print "Getting Container Id"
  e, o = runCmd('docker ps -aq --filter name=%s' % image_hash)
  if e: cleanup_exit(o, [tmpdir], image_hash)
  container_id = o

  print "Exporting Container ",container_id
  e, o = runCmd('rm -rf %s; mkdir -p %s; cd %s; docker export -o %s.tar %s' % (tmpdir, tmpdir, tmpdir,image_hash, container_id))
  if e: cleanup_exit(o, [tmpdir], image_hash)

  print "Cleaning up container ",image_hash
  runCmd('docker rm -f %s' % image_hash)

  print "Unpacking exported container ...."
  e, o = runCmd('mkdir -p %s; cd %s; tar -xf %s/%s.tar' % (img_dir, img_dir, tmpdir, image_hash))
  if e: cleanup_exit(o, [tmpdir, img_dir])
  runCmd('rm -rf %s' % tmpdir)

  for xdir in [ "srv", "cvmfs", "dev", "proc", "sys", "build", "data", "pool" ]:
    sdir = join(img_dir, xdir)
    if not exists(sdir): runCmd('mkdir %s' % sdir)
  
  print "Fixng file modes ...."
  fix_modes (img_dir)

  print "Creating container synlink ...."
  create_image_link(outdir, img_sdir, image)
  return

if __name__ == "__main__":
  from optparse import OptionParser
  parser = OptionParser(usage="%prog <pull-request-id>")
  parser.add_option("-c", "--container",  dest="container",  help="Docker container e.g. cmssw/cc7:latest", default=None)
  parser.add_option("-o", "--outdir",     dest="outdir",     help="Output directory where to unpack image", default=None)
  opts, args = parser.parse_args()

  if len(args) != 0: parser.error("Too many/few arguments")
  process(opts.container, opts.outdir)
  print "All OK"

  

