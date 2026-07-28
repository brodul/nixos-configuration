{ config, pkgs, lib, ... }:
{
  # Remote access for the Pi 4B: x11vnc (mirrors the physical i3 screen) reached
  # over a Cloudflare tunnel. Nothing listens on a public port — x11vnc binds to
  # 127.0.0.1 and cloudflared makes only *outbound* connections, so there are no
  # inbound firewall holes. You reach VNC/SSH through the tunnel.
  #
  # ── ONE-TIME SETUP YOU MUST DO (values below are placeholders) ──────────────
  #
  # 1. VNC password (service refuses to start without it):
  #      sudo x11vnc -storepasswd 'your-vnc-password' /etc/x11vnc.pass
  #      sudo chmod 600 /etc/x11vnc.pass
  #
  # 2. Cloudflare tunnel credentials + DNS (needs a Cloudflare-managed domain):
  #      cloudflared tunnel login
  #      cloudflared tunnel create rpi4
  #        -> writes ~/.cloudflared/<UUID>.json ; note the <UUID>
  #      cloudflared tunnel route dns rpi4 ssh.example.com
  #      cloudflared tunnel route dns rpi4 vnc.example.com
  #      cloudflared tunnel route dns rpi4 sync.example.com
  #    Then put the credentials JSON somewhere root-readable on the Pi, e.g.
  #      /var/lib/cloudflared/rpi4.json
  #    and replace TUNNEL_UUID / the example.com hostnames / credentialsFile
  #    below. (Prefer sops-nix/agenix for the credentials file in a real setup.)
  #
  # Reach the tunneled TCP services from a client with cloudflared, e.g.:
  #      cloudflared access ssh --hostname ssh.example.com
  #      cloudflared access tcp --hostname vnc.example.com --url 127.0.0.1:5900
  # ─────────────────────────────────────────────────────────────────────────────

  #### x11vnc — mirror the physical X display (:0) ####
  environment.systemPackages = [ pkgs.x11vnc ];

  systemd.services.x11vnc = {
    description = "x11vnc server mirroring the physical X display :0";
    # Start once the graphical stack (lightdm/X) is up, and keep it tied to it.
    after = [ "display-manager.service" ];
    wants = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # -auth guess   : locate the running X server's Xauthority (works with lightdm)
      # -localhost    : bind 127.0.0.1 only -> reachable solely via the tunnel/SSH
      # -forever -loop: survive session logouts / X restarts
      # -rfbauth      : VNC password file created in step 1 above
      ExecStart = ''
        ${pkgs.x11vnc}/bin/x11vnc \
          -display :0 \
          -auth guess \
          -rfbauth /etc/x11vnc.pass \
          -rfbport 5900 \
          -localhost \
          -forever -loop -shared -noxdamage -repeat
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  #### Cloudflare tunnel — encrypted outbound path to the Pi ####
  services.cloudflared = {
    enable = true;
    tunnels = {
      # Replace this attribute name with your real tunnel UUID (step 2).
      "TUNNEL_UUID" = {
        # JSON credentials written by `cloudflared tunnel create` (step 2).
        credentialsFile = "/var/lib/cloudflared/rpi4.json";

        # Public-hostname -> local-service routing (edit the hostnames).
        ingress = {
          "ssh.example.com"  = "ssh://localhost:22";
          "vnc.example.com"  = "tcp://localhost:5900";
          "sync.example.com" = "http://localhost:8384";
        };

        # Anything not matched above gets a 404 rather than reaching the Pi.
        default = "http_status:404";
      };
    };
  };
}
