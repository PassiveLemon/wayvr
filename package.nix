{ lib
, pkgs
, ...
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "wayvr";
  version = "4821123c7333cbe21f8ffb02d1972c5fd63c65d1";

  src = ./.;

  cargoHash = "sha256-zqB2ybdpQEGdlkNin6mlUfaVRkpOtFl2CVCLAdKDMoQ=";

  # Taken from nixpkgs wayvr package
  postPatch = ''
    substituteAllInPlace dash-frontend/src/util/pactl_wrapper.rs \
      --replace-fail '"pactl"' '"${lib.getExe' pkgs.pulseaudio "pactl"}"'

    # steam_utils also calls xdg-open as well as steam. Those should probably be pulled from the environment
    substituteInPlace dash-frontend/src/util/steam_utils.rs \
      --replace-fail '"pkill"' '"${lib.getExe' pkgs.procps "pkill"}"'
  '';

  nativeBuildInputs = with pkgs; [
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = with pkgs; [
    alsa-lib
    dbus
    libxcb
    libxcursor
    libxi
    libxkbcommon
    openssl
    openvr
    openxr-loader
    pipewire
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
  ];

  env.SHADERC_LIB_DIR = "${lib.getLib pkgs.shaderc}/lib";

  postFixup = ''
    wrapProgram $out/bin/wayvr \
      --suffix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs}

    wrapProgram $out/bin/uidev \
      --suffix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (buildInputs ++ [ pkgs.vulkan-loader ])}
  '';

  postInstall = ''
    install -Dm644 $src/wayvr/wayvr.desktop $out/share/applications/wayvr.desktop
    install -Dm644 $src/wayvr/wayvr.svg $out/share/icons/hicolor/scalable/apps/wayvr.svg
  '';

  meta = with lib; {
    description = "lightweight OpenXR/OpenVR overlay for Wayland and X11 desktops";
    homepage = "https://github.com/wlx-team/wayvr";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ passivelemon ];
    platforms = platforms.linux;
    mainProgram = "wayvr";
  };
}

