{
  uhttpd."main" = {
    listen_http = [
      "0.0.0.0:80"
      "[::]:80"
      "0.0.0.0:443"
      "[::]:443"
    ];
    redirect_https = "0";
    cgi_prefix = "/cgi-bin";
    lua_prefix = [ "/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua" ];
    ubus_prefix = "/ubus";
  };
}
