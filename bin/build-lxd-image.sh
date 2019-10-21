#!/usr/bin/env bash
set -o errexit

main() {
  set -o pipefail

  case "$1" in
  -h | --help | help)
    __usage
    exit 0
    ;;
  -l | --list-only)

    ;;
  esac

  echo "Building $1..."
  DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

  # Sync templates
  SSH="${BUILDER_USER}@${BUILDER_HOST}"
  rsync -aR --delete --exclude .vagrant --exclude ./lxd/.vagrant --exclude tmp ${DIR} ${SSH}:~/packer-templates/

  #pushd ./lxd
  __ssh "echo export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID > ~/.load_env"
  __ssh "echo export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY >> ~/.load_env"
  __ssh "echo export ARCH=$ARCH >> ~/.load_env"
  __ssh "echo export JOB_BOARD_IMAGES_URL=$JOB_BOARD_IMAGES_URL >> ~/.load_env"
  __ssh "echo export ARCH=$ARCH >> ~/.load_env"
  __ssh ". ~/.load_env && cd ~/packer-templates/lxd && packer build <(bin/yml2json < $1.yml)"
  __ssh "rm -f ~/.load_env"

  #__ssh "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID; export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY; aws s3 cp $1.tar.gz s3://travis-lxc-images/{$ARCH}/ --acl public-read"
}

__ssh() {
  local command="${1}"
  if [[ ${BUILDER_USER}xx == "xx" ]]; then
    echo "Empty BUILDER_USER"
  fi
  if [[ ${BUILDER_HOST}xx == "xx" ]]; then
    echo "Empty BUILDER_HOST"
  fi
  SSH="${BUILDER_USER}@${BUILDER_HOST}"
  ssh ${SSH} -o "LogLevel=QUIET" -t "bash -l -c '${command}'"
}

__usage() {
  awk '/^#\+  / {
    sub(/^#\+  /, "", $0) ;
    sub(/-$/, "", $0) ;
    print $0
  }' \
    "${0}"
}

main "$@"