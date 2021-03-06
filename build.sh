#!/bin/bash
# This script written by @imlongnguyen (Ref DirectAdmin)

if [ "$(id -u)" != "0" ]; then
	echo "You must be root to execute the script. Exiting."
	exit 1
fi

SCRIPT_VERSION=1.0
BUILD_DIR=/root/custombuild
BUILD_SERVER="http://files.directadmin.com/services/custombuild"
mkdir -p ${BUILD_DIR}
chmod 700 ${BUILD_DIR}


OS=`uname`
HOSTNAME=`hostname`

if [ "`cat /proc/cpuinfo | grep -F 'model name' | wc -l`" -gt 0 ]; then
	CPU_CORES="`cat /proc/cpuinfo | grep -F 'model name' | wc -l`"
fi

MEMORY=`grep -m1 'MemTotal' /proc/meminfo | awk '{print $2}'`

LANG=C

if uname -m | grep -qE -m1 'amd64|x86_64'; then
	B64=1
	LD_LIBRARY_PATH=/usr/lib/apache:/usr/local/icu/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib
	export LD_LIBRARY_PATH
	PKG_CONFIG_PATH=/usr/local/icu/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig
	export PKG_CONFIG_PATH
	if [ "${OS_CENTOS_VER}" = "6" ]; then
		export KERBEROS_LIBS="-L/usr/lib64 -lkrb5 -lk5crypto -lgssapi_krb5"
		export KERBEROS_CFLAGS="-I/usr/include"
		export ONIG_LIBS="-L/usr/lib64 -lonig"
        export ONIG_CFLAGS="-I/usr/include"
	fi
fi

if [ ! -z "${MEMORY}" ]; then
	if [ ${MEMORY} -lt 2097152 ]; then
		CPU_CORES=1
	fi
fi

#Check path for /usr/local/bin
if ! echo "${PATH}" | grep -qF -m1 '/usr/local/bin:'; then
	export PATH=/usr/local/bin:$PATH
fi

# Common pre-install
yum install -y wget tar gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio \
libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed \
autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel \
psmisc net-tools systemd-devel libdb-devel perl-DBI perl-Perl4-CoreLibs perl-libwww-perl xfsprogs rsyslog logrotate crontabs file kernel-headers

# Start build 
AUTOCONF="autoconf-2.69"
PCRE="pcre-8.44"
PCRE2="pcre2-10.34"
LIBJPEG="jpegsrc.v9d"
LIBPNG="libpng-1.6.37"
LIBWEBP="libwebp-1.1.0"
LIBMCRYPT="libmcrypt-2.5.8"
MHASH="mhash-0.9.9.9"
FREETYPE2="freetype-2.10.1"
ICONV="libiconv-1.16"
ICU="icu4c-66_1-src"
LIBXML2="libxml2-2.9.9"
LIBXSTL="libxslt-1.1.33"
LIBSODIUM="libsodium-1.0.18"
PHP73="php-7.3.16"


build_autoconf() {
	cd ${BUILD_DIR}

	echo "Start build autoconf"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${AUTOCONF}.tar.gz

	echo "Extracting ..."
	tar zxvf ${AUTOCONF}.tar.gz
	
	cd ${AUTOCONF}

	./configure --prefix=/usr/local
	LANG=c make
	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	LANG=c make install

	echo "Build autoconf completed"
}

build_pcre() {
	cd ${BUILD_DIR}

	echo "Start build PCRE"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${PCRE}.tar.gz

	echo "Extracting ..."
	tar zxvf ${PCRE}.tar.gz

	cd ${PCRE}
	
	./configure --enable-utf8 --enable-unicode-properties --enable-jit
	make CFLAGS=-fpic CPPFLAGS=-I/usr/kerberos/include
	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build pcre completed"

	/sbin/ldconfig
}


build_pcre2() {
	cd ${BUILD_DIR}

	echo "Start build PCRE2"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${PCRE2}.tar.gz

	echo "Extracting ..."
	tar zxvf ${PCRE2}.tar.gz

	cd ${PCRE2}
	
	./configure --enable-jit
	make -j ${CPU_CORES}
	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build pcre2 completed"
}


build_libjpeg() {
	cd ${BUILD_DIR}

	echo "Start build libjpeg"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBJPEG}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBJPEG}.tar.gz
	
	cd jpeg-9d

	./configure
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libjpeg completed"
}


build_libpng() {
	cd ${BUILD_DIR}

	echo "Start build libpng"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBPNG}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBPNG}.tar.gz
	
	cd ${LIBPNG}

	./configure --prefix=/usr/local
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libpng completed"
}


build_libwebp() {
	cd ${BUILD_DIR}

	echo "Start build libwebp"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/libwebp/${LIBWEBP}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBWEBP}.tar.gz
	
	cd ${LIBWEBP}

	./configure --prefix=/usr/local
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libwebp completed"
}


build_libmcrypt() {
	cd ${BUILD_DIR}

	echo "Start build libmcrypt"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBMCRYPT}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBMCRYPT}.tar.gz
	
	cd ${LIBMCRYPT}

	./configure --enable-ltdl-install

	make CFLAGS=-fpic

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libmcrypt completed"


	if [ -d libltdl ]; then
		echo "Install libltdl for libmcrypt"
		cd libltdl
		./configure --enable-ltdl-install
		make
		make install
		echo "Install libltdl for libmcrypt completed"
	fi
}


build_mhash() {
	cd ${BUILD_DIR}

	echo "Start build mhash"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${MHASH}.tar.gz

	echo "Extracting ..."
	tar zxvf ${MHASH}.tar.gz
	
	cd ${MHASH}

	./configure --prefix=/usr/local
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build mhash completed"
}


build_freetype2() {
	cd ${BUILD_DIR}

	echo "Start build freetype2"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${FREETYPE2}.tar.gz

	echo "Extracting ..."
	tar zxvf ${FREETYPE2}.tar.gz
	
	cd ${FREETYPE2}

	./configure --enable-freetype-config
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build freetype2 completed"
}

build_iconv() {
	cd ${BUILD_DIR}

	echo "Start build iconv"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${ICONV}.tar.gz

	echo "Extracting ..."
	tar zxvf ${ICONV}.tar.gz
	
	cd ${ICONV}

	./configure --prefix=/usr/local --enable-extra-encodings
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build iconv completed"

	/sbin/ldconfig
}

build_icu() {
	cd ${BUILD_DIR}

	echo "Start build icu"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${ICU}.tgz

	echo "Extracting ..."
	tar zxvf ${ICU}.tgz
	
	cd icu/source
	
	mkdir -p /usr/local/icu
	./configure --prefix=/usr/local/icu --enable-rpath
	make -j ${CPU_CORES}

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	ln -sf /usr/local/icu/bin/icu-config /usr/local/bin/icu-config

	echo "Build icu completed"
}

build_libxml2() {
	cd ${BUILD_DIR}

	echo "Start build libxml2"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBXML2}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBXML2}.tar.gz
	
	cd ${LIBXML2}

	./configure --prefix=/usr/local --without-python --with-zlib=/usr
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libxml2 completed"
}


build_libxslt() {
	cd ${BUILD_DIR}

	echo "Start build libxslt"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBXSTL}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBXSTL}.tar.gz
	
	cd ${LIBXSTL}

	./configure --prefix=/usr/local --with-libxml-prefix=/usr/local
	
	make -j ${CPU_CORES}

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libxslt completed"

	/sbin/ldconfig
}

build_libsodium() {
	cd ${BUILD_DIR}

	echo "Start build libsodium"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${LIBSODIUM}.tar.gz

	echo "Extracting ..."
	tar zxvf ${LIBSODIUM}.tar.gz
	
	cd ${LIBSODIUM}

	./configure --prefix=/usr/local
	
	make

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build libsodium completed"
}

build_php73() {
	cd ${BUILD_DIR}

	echo "Start build php73"
	echo "Downloading ..."
	wget ${BUILD_SERVER}/${PHP73}.tar.gz

	echo "Extracting ..."
	tar zxvf ${PHP73}.tar.gz
	
	cd ${PHP73}

	'./configure' \
	'--enable-embed' \
	'--prefix=/usr/local/php73' \
	'--program-suffix=73' \
	'--enable-fpm' \
	'--with-fpm-systemd' \
	'--with-litespeed' \
	'--with-config-file-scan-dir=/usr/local/php73/lib/php.conf.d' \
	'--with-curl' \
	'--with-gd' \
	'--with-gettext' \
	'--with-jpeg-dir=/usr/local/lib' \
	'--with-freetype-dir=/usr/local/lib' \
	'--with-libxml-dir=/usr/local/lib' \
	'--with-kerberos' \
	'--with-openssl' \
	'--with-mhash' \
	'--with-mysql-sock=/var/lib/mysql/mysql.sock' \
	'--with-mysqli=mysqlnd' \
	'--with-pcre-regex=/usr/local' \
	'--with-pdo-mysql=mysqlnd' \
	'--with-pear' \
	'--with-png-dir=/usr/local/lib' \
	'--with-sodium=/usr/local' \
	'--with-webp-dir=/usr/local/lib' \
	'--with-xsl' \
	'--with-zlib' \
	'--enable-zip' \
	'--without-libzip' \
	'--with-iconv=/usr/local' \
	'--enable-bcmath' \
	'--enable-calendar' \
	'--enable-exif' \
	'--enable-ftp' \
	'--enable-sockets' \
	'--enable-soap' \
	'--enable-mbstring' \
	'--with-icu-dir=/usr/local/icu' \
	'--enable-intl' \
	"$@"

	C_INCLUDE_PATH=/usr/kerberos/include make -j ${CPU_CORES}

	if [ $? -ne 0 ]; then
		printf "The make has failed. Exiting"
		exit
	fi

	echo "Make complete"
	
	make install

	echo "Build php73 completed"
}


build_autoconf
build_pcre
build_pcre2
build_libjpeg
build_libpng
build_libwebp
build_libmcrypt
build_mhash
build_freetype2
build_iconv
build_icu
build_libxml2
build_libxslt
build_libsodium

build_php73
