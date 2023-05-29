{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }@inputs: {
    packages.x86_64-linux.default =
      with import nixpkgs { system = "x86_64-linux"; };
      let spacenavSupport = stdenv.isLinux; in
      stdenv.mkDerivation rec {
        pname = "openscad";
        version = "2023.05.27";

        src = fetchFromGitHub {
          owner = "openscad";
          repo = "openscad";
          rev = "e2ea2a6abe461e87d9dba73ec46e0151eb60ac39";
          sha256 = "sha256-Hx1f7e0WwaHjcSVN/GctBa0So9PALlyEHQzAyAcV+e0=";
          fetchSubmodules = true;
        };

        nativeBuildInputs = [ bison flex pkg-config gettext cmake qt5.qmake qt5.wrapQtAppsHook ];

        buildInputs = [
          eigen boost glew opencsg cgal_5 mpfr gmp glib
          harfbuzz lib3mf libzip double-conversion freetype fontconfig
          #qtbase qtmultimedia
          qt5.qtbase qt5.qtmultimedia
          qscintilla cairo
          python3
          python310Packages.pillow
          python310Packages.numpy
          python310Packages.pip
          python310Packages.setuptools
          virtualenv
          tbb
        ] ++ lib.optionals stdenv.isLinux [ libGLU libGL wayland wayland-protocols qt5.qtwayland xorg.libXdmcp xorg.libSM ]
          ++ lib.optional stdenv.isDarwin qt5.qtmacextras
          ++ lib.optional spacenavSupport libspnav
        ;

        cmakeFlags = [
          "VERSION=${version}"
          "-DOPENSCAD_VERSION=${version}"
          "-DEXPERIMENTAL=1"
        ] ++
          lib.optionals spacenavSupport [
            "ENABLE_SPNAV=1"
            "SPNAV_INCLUDEPATH=${libspnav}/include"
            "SPNAV_LIBPATH=${libspnav}/lib"
          ];

        enableParallelBuilding = true;

        postInstall = lib.optionalString stdenv.isDarwin ''
          mkdir $out/Applications
          mv $out/bin/*.app $out/Applications
          rmdir $out/bin || true

          mv --target-directory=$out/Applications/OpenSCAD.app/Contents/Resources \
            $out/share/openscad/{examples,color-schemes,locale,libraries,fonts,templates}

          rmdir $out/share/openscad
        '';

        meta = {
          description = "3D parametric model compiler";
          longDescription = ''
            OpenSCAD is a software for creating solid 3D CAD objects. It is free
            software and available for Linux/UNIX, MS Windows and macOS.

            Unlike most free software for creating 3D models (such as the famous
            application Blender) it does not focus on the artistic aspects of 3D
            modelling but instead on the CAD aspects. Thus it might be the
            application you are looking for when you are planning to create 3D models of
            machine parts but pretty sure is not what you are looking for when you are more
            interested in creating computer-animated movies.
          '';
          homepage = "http://openscad.org/";
          license = lib.licenses.gpl2;
          platforms = lib.platforms.unix;
          maintainers = with lib.maintainers; [ bjornfor raskin gebner ];
        };
      };
  };
}
