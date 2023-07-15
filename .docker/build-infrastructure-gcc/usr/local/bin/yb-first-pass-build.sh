#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source
# ensure the source code
if [ ! -d "./.git" ]; then
    echo "Checking out '${YB_REPOSITORY}'..."
    git clone "${YB_REPOSITORY}" .
else 
    echo "'${YB_REPOSITORY}' already checked out..."
fi
# checkout the version to work with
git checkout "${YB_SOURCE_VERSION}"
# optionally, install extensions for compilation
extra_extensions=""
count=$(find /extensions/ -maxdepth 1 -type d | grep -v '^/extensions/$' | wc -l)
if [ $count -ne 0 ]; then
    for d in /extensions/*/ ; do
        ext_name=$(basename "$d")
        echo "Discovered an extension to add: '${ext_name}'"
        extra_extensions="$extra_extensions $ext_name"
        rm -rf "src/postgres/third-party-extensions/${ext_name}"
        cp -v -r "$d" src/postgres/third-party-extensions/
    done
fi
if [ -z "${extra_extensions}" ]; then
    echo "There were no extra extensions to compile with..."
else
    echo "Appending '${extra_extensions}' to src/postgres/third-party-extensions/Makefile"
    sed -i "1{s/$/${extra_extensions}/}" src/postgres/third-party-extensions/Makefile
fi
# patch postgres.h
/usr/local/bin/patch_postgres_h.sh
# first pass compile
[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}
./yb_build.sh release
# done
echo "Your first pass build of YugabyteDB ${YB_SOURCE_VERSION} is complete"
