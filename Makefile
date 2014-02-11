.PHONY: install # Install.
.PHONY: clean   # remove.
.PHONY: tests   # Runs the tests.
.PHONY: echo-variables        # Shows make variables. mainly for debugging
.PHONY: travis-before-install # Sets up the travis environment.
.PHONY: hlint   # runs hlint on the sources

PACKAGE=aim

TEST_PATH=dist/build/tests/tests # path to the tests in any package.

#
# Sets up the cabal config. The directory platform contains the cabal
# config file to use for each platform. Typically you need to put the
# package constraints there. The platform/default.cabal.conf contains
# the default config to use.
#

HASKELL_PLATFORM ?= default
CABAL_CONFIG=platform/${HASKELL_PLATFORM}.cabal.config

#
# In a travis build, you can set explicit versions for ghc and cabal
# by setting the variables GHC_VERSION and CABAL_VERSION. The place
# that you would want this to be done is in the env section of your
# .travis.yml.
#

ifdef GHC_VERSION	# For explicit ghc version

GHC_PKG=ghc-${GHC_VERSION}
PATH:=/opt/ghc/${GHC_VERSION}/bin:${PATH}

else

GHC_PKG=ghc

endif			# For explicit ghc version


ifdef CABAL_VERSION

CABAL_PKG=cabal-install-${CABAL_VERSION}
CABAL=cabal-${CABAL_VERSION}

else

CABAL_PKG=cabal-install
CABAL=cabal

endif

# This target just prints the setting of each relevant
# variable. Useful for debugging.

echo-variables:
	@echo Makefile variables.
	@echo -e '\t'CABAL_VERSION=${CABAL_VERSION}
	@echo -e '\t'CABAL_CONFIG=${CABAL_CONFIG}
	@echo -e '\t'GHC_VERSION=${GHC_VERSION}
	@echo -e '\t'HASKELL_PLATFORM=${HASKELL_PLATFORM}

	@echo -e '\t'ghc,cabal: ${GHC_PKG} ${CABAL_PKG}

install:
	${CABAL} configure --enable-tests --enable-benchmarks -v2;\
	${CABAL} build;\
	${CABAL} test;\
	${CABAL} check;\
	${CABAL} sdist;\
	${CABAL} haddock;\
	${CABAL} install
	@echo User packages installed
	ghc-pkg list --user

tests:
	${CABAL} test

#
# Clean dirs and unregister
#

clean:
	./Setup.lhs clean;\
	ghc-pkg unregister  $(PACKAGE) --force

#
#  Travis platform setup
#

travis-before-install:
	sudo add-apt-repository -y ppa:hvr/ghc
	sudo apt-get update
	sudo apt-get install ${CABAL_PKG} ${GHC_PKG} happy
	${CABAL} update

#
#  Stuff that checks the coding style
#

hlint:
	hlint .
