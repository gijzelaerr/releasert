#!bash -e
#
# this script will build a debian package from a github repo.
# it is assumed that:
#
# * You want to make a new release
#
# * You want the changes commited to the github repository
#    (new tag and updated deb package changelog)
#
# * you can access and commit to the git repo
#
# * you have access to dput to launchpad
#
#
# WARNING: will push stuff to launchad and github
#


ORGANISATION=ska-sa
WORKDIR=~/packaging
DIST=trusty


if [ "$#" -ne 2 ]; then
    echo "usage: $0 <project name> <version>"
    echo 
    echo "example: $0 tigger 1.3.2"
    echo 
    exit 1
fi

NAME=$1
VERSION=$2
REPO=git@github.com:$ORGANISATION/$NAME.git
DEB_REPO=git@github.com:$ORGANISATION/$NAME-debian.git
RELEASE_URL=https://github.com/$ORGANISATION/$NAME/releases/tag/$VERSION

if [ ! -x $WORKDIR ]; then
    echo "$WORKDIR doens't exists, creating"
    mkdir $WORKDIR
fi

cd $WORKDIR

if [ ! -x $NAME ]; then
    echo "checking out $NAME for the first time"
    git clone $REPO $NAME
    cd $NAME
else
    cd $NAME
    git pull
    git checkout master
fi

echo "* making new version"
git tag $VERSION
git push --tags
echo "* release online now: RELEASE_URL"
git archive --prefix=$NAME-$VERSION/ $VERSION | bzip2 >../${NAME}_$VERSION.orig.tar.bz2
cd ..
tar jxvf ${NAME}_$VERSION.orig.tar.bz2
cd $NAME-$VERSION 

echo "* preparing debian files"
git clone $DEB_REPO debian
cd debian
git checkout $DIST
dch -v $VERSION-1$DIST -D $DIST --force-distribution "new upstream release" || true
git commit changelog -m "new upstream release"
git push

echo "* building source package"
cd ..
debuild -S -sa

echo "* pushing to launchpad PPA"
dput ppa:ska-sa/main ../${NAME}_$VERSION-1$DIST_source.changes

