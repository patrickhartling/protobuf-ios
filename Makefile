
LIBRARY = libprotobuf.a

XCODE_DEVELOPER = $(shell xcode-select --print-path)
IOS_PLATFORM ?= iPhoneOS

# Pick latest SDK in the directory
IOS_PLATFORM_DEVELOPER = ${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer
IOS_SDK = ${IOS_PLATFORM_DEVELOPER}/SDKs/$(shell ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)
#IOS_SDK = ${IOS_PLATFORM_DEVELOPER}/SDKs/${IOS_PLATFORM}6.0.sdk

ifeq (iPhoneOS, ${IOS_PLATFORM})
PLATFORM_OPTION = iphoneos
else
PLATFORM_OPTION = ios-simulator
endif

PLATFORM_MIN_VERSION = 6.0
PROTOBUF_VERSION = 2.5.0
PROTOC_PATH = ${HOME}/protobuf-2.5/bin/protoc

all: lib/libprotobuf.a
lib/libprotobuf.a: build_arches
	mkdir -p lib
	mkdir -p include

	# Copy includes
	cp -R build/armv7/include/google include

	# Make fat libraries for all architectures
	for file in build/armv7/lib/*.a; \
		do name=`basename $$file .a`; \
		${IOS_PLATFORM_DEVELOPER}/usr/bin/lipo -create \
			-arch armv7 build/armv7/lib/$$name.a \
			-arch armv7s build/armv7s/lib/$$name.a \
			-arch i386 build/i386/lib/$$name.a \
			-output lib/$$name.a \
		; \
		done;

# Build separate architectures
build_arches:
	${MAKE} arch ARCH=armv7 IOS_PLATFORM=iPhoneOS
	${MAKE} arch ARCH=armv7s IOS_PLATFORM=iPhoneOS
	${MAKE} arch ARCH=i386 IOS_PLATFORM=iPhoneSimulator

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib
BINDIR = ${PREFIX}/bin
INCLUDEDIR = ${PREFIX}/include

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -m${PLATFORM_OPTION}-version-min=${PLATFORM_MIN_VERSION} -O3
CXXFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -m${PLATFORM_OPTION}-version-min=${PLATFORM_MIN_VERSION} -O3
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -m${PLATFORM_OPTION}-version-min=${PLATFORM_MIN_VERSION} -L${LIBDIR} -L${IOS_SDK}/usr/lib -arch ${ARCH}

arch: ${LIBDIR}/libprotobuf.a

${LIBDIR}/libprotobuf.a: ${CURDIR}/protobuf
	cd protobuf && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=arm-apple-darwin --prefix=${PREFIX} --disable-shared --with-protoc=${PROTOC_PATH} && make clean install

${CURDIR}/protobuf:
	curl http://protobuf.googlecode.com/files/protobuf-${PROTOBUF_VERSION}.tar.bz2 > protobuf.tar.gz
	tar -xzf protobuf.tar.gz
	rm protobuf.tar.gz
	mv protobuf-${PROTOBUF_VERSION} protobuf

clean:
	rm -rf build protobuf include lib
