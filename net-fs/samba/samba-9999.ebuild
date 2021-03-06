# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-fs/samba/samba-4.0.0_alpha11.ebuild,v 1.5 2010/07/15 12:34:43 scarabeus Exp $

EAPI="2"

inherit git confutils

EGIT_REPO_URI="git://git.samba.org/samba.git"


DESCRIPTION="Samba Server component"
HOMEPAGE="http://www.samba.org/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="caps debug dso gnutls +netapi sqlite threads +client +server +tools +python"

DEPEND="!net-fs/samba-libs
	!net-fs/samba-server
	!net-fs/samba-client
	dev-libs/popt
	sys-libs/readline
	virtual/libiconv
	caps? ( sys-libs/libcap )
	gnutls? ( net-libs/gnutls )
	sqlite? ( >=dev-db/sqlite-3 )
	>=sys-libs/talloc-2.0.1
	>=sys-libs/tdb-1.2.0
	=sys-libs/tevent-0.9.8"
	#=sys-libs/ldb-0.9.10 No release yet
# See source4/min_versions.m4 for the minimal versions
RDEPEND="${DEPEND}"

RESTRICT="mirror"

S="${WORKDIR}/${MY_P}/source4"

pkg_setup() {
	SBINPROGS=""
	if use server ; then
		SBINPROGS="${SBINPROGS} bin/samba"
	fi
	if use client ; then
		SBINPROGS="${SBINPROGS} bin/mount.cifs bin/umount.cifs"
	fi

	BINPROGS=""
	if use client ; then
		BINPROGS="${BINPROGS} bin/smbclient bin/net bin/nmblookup bin/ntlm_auth"
	fi
	if use server ; then
		BINPROGS="${BINPROGS} bin/testparm bin/smbtorture"
	fi
	if use tools ; then
		# Should be in sys-libs/ldb, but there's no ldb release yet
		BINPROGS="${BINPROGS} bin/ldbedit bin/ldbsearch bin/ldbadd bin/ldbdel bin/ldbmodify bin/ldbrename"
	fi
	confutils_use_depend_all server python
}

src_unpack() {
	git_src_unpack
	S="${S}/source4"
	cd "${S}"
	./autogen-waf.sh
}

src_configure() {
	
	# Upstream refuses to make this configurable
	use caps && export ac_cv_header_sys_capability_h=yes || export ac_cv_header_sys_capability_h=no
	export CFLAGS="${CFLAGS} -I${S}/lib/ldb/include/"
	econf \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--enable-fhs \
		--enable-developer \
		$(use_enable gnutls) \
		--enable-socket-wrapper \
		--enable-nss-wrapper \
		--with-modulesdir=/usr/lib/samba/modules \
		--with-privatedir=/var/lib/samba/private \
		--with-ntp-signd-socket-dir=/var/run/samba \
		--with-lockdir=/var/cache/samba \
		--with-piddir=/var/run/samba \
		--bundled-libraries=ALL
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	cd "${S}"
	# install libs
	emake install DESTDIR="${D}" || die "make install failed"
	insinto /usr/share/samba
	doins setup
	newinitd "${FILESDIR}/samba4.initd" samba
}

pkg_preinst() {
	cd "${D}"
	rm usr/share/man/man8/tdbdump.8.bz2
	rm usr/share/man/man8/tdbbackup.8.bz2
	rm usr/share/man/man8/tdbtool.8.bz2
}

src_test() {
	emake test DESTDIR="${D}" || die "Test failed"
}

pkg_postinst() {
	# Optimize the python modules so they get properly removed
	use python && python_mod_optimize $(python_get_sitedir)/${PN}

	# Warn that it's an alpha
	ewarn "Samba 4 is an alpha and therefore not considered stable. It's only"
	ewarn "meant to test and experiment and definitely not for production"
}

pkg_postrm() {
	# Clean up the python modules
	use python && python_mod_cleanup $(python_get_sitedir)/${PN}
}
