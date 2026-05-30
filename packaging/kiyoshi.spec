%global appname kiyoshi
%global appver  1.0.0
%global debug_package %{nil}

Name:          %{appname}
Version:       %{appver}
Release:       1%{?dist}
Summary:       Zen Studio — Glassmorphic Kanban Workspace Manager

License:       MIT
URL:           https://github.com/jomvick/Kiyoshi
Source0:       %{name}-%{version}.tar.gz
Source1:       %{name}.sh
Source2:       %{name}.desktop

Requires:      gtk3
Requires:      mesa-libEGL
Requires:      libX11
Requires:      libXcursor
Requires:      libXrandr
Requires:      libXinerama
Requires:      xz-libs
Requires:      fontconfig
Requires:      freetype

%description
Kiyoshi is a minimalist glassmorphic Kanban workspace manager.
Built with Flutter, it provides task management, project
organization, calendar, and a block-based canvas — all wrapped
in a calming Zen Studio design system.

%prep
%setup -q -n %{name}-%{version}

%install
install -d %{buildroot}%{_datadir}/%{appname}/lib
install -d %{buildroot}%{_datadir}/%{appname}/data
install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{_datadir}/applications

install -m 0755 %{appname} %{buildroot}%{_datadir}/%{appname}/%{appname}
install -m 0644 lib/*.so %{buildroot}%{_datadir}/%{appname}/lib/
cp -r data/* %{buildroot}%{_datadir}/%{appname}/data/
install -m 0755 %{_sourcedir}/%{appname}.sh %{buildroot}%{_bindir}/%{appname}
install -m 0644 %{_sourcedir}/%{appname}.desktop %{buildroot}%{_datadir}/applications/%{appname}.desktop

%files
%{_bindir}/%{appname}
%{_datadir}/%{appname}/%{appname}
%{_datadir}/%{appname}/lib/*.so
%{_datadir}/%{appname}/data/
%{_datadir}/applications/%{appname}.desktop

%post
update-desktop-database &>/dev/null || :

%postun
update-desktop-database &>/dev/null || :

%changelog
* Tue May 19 2026 jomvick <jomvick@users.noreply.github.com> - 1.0.0-1
- Initial RPM release of Kiyoshi
