#!/bin/sh

set -eux

. "$( cd "$(dirname "$0")" ; pwd -P )/../ghcup_env"

mkdir -p "$CI_PROJECT_DIR"/.local/bin

CI_PROJECT_DIR=$(pwd)

ecabal() {
	cabal "$@"
}

eghcup() {
	ghcup -v -c -s file://$CI_PROJECT_DIR/ghcup-${JSON_VERSION}.yaml "$@"
}

git describe --always

### build

ecabal update

ecabal build -w ghc-${GHC_VERSION}
cp "$(ecabal new-exec -w ghc-${GHC_VERSION} --verbose=0 --offline sh -- -c 'command -v ghcup')" "$CI_PROJECT_DIR"/.local/bin/ghcup

### cleanup

rm -rf "${GHCUP_INSTALL_BASE_PREFIX}"/.ghcup

### manual cli based testing

eghcup --numeric-version

eghcup install ghc ${GHC_VERSION}
eghcup set ghc ${GHC_VERSION}
eghcup install cabal ${CABAL_VERSION}

cabal --version

eghcup debug-info

eghcup compile ghc -j $(nproc) -g ${GHC_GIT_TAG} -b ${GHC_VERSION} -- --enable-unregisterised
eghcup set ghc ${GHC_GIT_VERSION}

[ `$(eghcup whereis ghc ${GHC_GIT_VERSION}) --numeric-version` = "${GHC_GIT_VERSION}" ]

# nuke
eghcup nuke
[ ! -e "${GHCUP_INSTALL_BASE_PREFIX}/.ghcup" ]

