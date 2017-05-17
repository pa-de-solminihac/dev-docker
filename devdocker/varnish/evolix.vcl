# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
#
# Clients' settings are overwritten on /etc/varnish/<client>.vcl.
#

vcl 4.0;

# Unique backend definition.
# 
backend haproxy {
    .host = "127.0.0.1";
    .port = "80";
    .connect_timeout = 3s;
    .first_byte_timeout = 300s;
    .between_bytes_timeout = 300s;
    .probe = {
        .request =
          "HEAD /haproxycheck HTTP/1.1"
          "Connection: close";
        .timeout = 10s;
        .interval = 30s;
        .window = 3;
        .threshold = 2;
    }
}

sub vcl_recv {

    # HAProxy check
    if (req.url == "/varnishcheck") {
        return(synth(200, "Hi HAProxy, I'm fine!"));
    }

    # Grace mode (Stale content delivery)
    #if (req.backend.healthy) {
    #    set req.grace = 2m;
    #}
    #else {
    #    set req.grace = 4h;
    #}

    # We only deal with GET and HEAD methods by default.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Normalize encoding, and unset it on yet-compressed formats.
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|lzma|tbz|zip|rar)(\?.*|)$") {
            unset req.http.Accept-Encoding;
        }
        # use gzip when possible, otherwise use deflate
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        }
        elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        }
        else {
            # unknown algorithm, unset accept-encoding header
            unset req.http.Accept-Encoding;
        }
    }

    # No cache for WordPress' backoffice nor connected users.
    if (req.url ~ "^/wp-(login|admin)" || req.http.Cookie ~ "wordpress_logged_in_" ) {
        return (pass);
    }

    # Cleanup requests on static binary files and force serving from cache.
    if (req.url ~ "\.(jpe?g|png|gif|ico|swf|gz|zip|rar|bz2|tgz|tbz|pdf|pls|torrent|mp4)(\?.*|)$") {
        unset req.http.Authenticate;
        unset req.http.POSTDATA;
        unset req.http.cookie;
        set req.method = "GET";
        return (hash);
    }

    # Remove known cookies used only on client side (by JavaScript).
    if (req.http.cookie) {
        set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");       # Google Analytics
        set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");        # Google Analytics
        set req.http.Cookie = regsuball(req.http.Cookie, "_gaq=[^;]+(; )?", "");       # Google Analytics
        set req.http.Cookie = regsuball(req.http.Cookie, "__utm[^=]*=[^;]+(; )?", ""); # Google Analytics

        if (req.http.cookie ~ "^ *$") {
            unset req.http.cookie;
        }
    }
}

sub vcl_backend_response {

    if (beresp.uncacheable) {
      set beresp.http.X-Cacheable = "FALSE";
    } else {
      set beresp.http.X-Cacheable = "TRUE";
    }

    # Default TTL if the backend does not send any header.
    if (!beresp.http.Cache-Control) {
        set beresp.ttl = 1d;
    }
    # Exceptions
    if (bereq.url ~ "\.(rss|xml|atom)(\?.*|)$") {
        set beresp.ttl = 2h;
    } 

    # Grace mode (Stale content delivery)
    set beresp.grace = 4h;

    # No cache for WordPress' backoffice nor connected users.
    if (bereq.url ~ "wp-(login|admin)" || bereq.http.Cookie ~ "wordpress_logged_in_" ) {
        set beresp.uncacheable = true;
        set beresp.ttl = 0s;
        return (deliver);
    }

    # Low TTL for objects with an error response code.
    if (beresp.status == 403 || beresp.status == 404 || beresp.status >= 500) {
        set beresp.ttl = 10s;
        # Could not be accidentaly overriden in client's configuration file.
        return(deliver);
    }

    # Store compressed objects in memory.
    # They would be uncompressed on the fly by Varnish if the client doesn't
    # support compression.
    #if (beresp.http.content-type ~ "(text|application)") {
    #    set beresp.do_gzip = true;
    #}
}

sub vcl_deliver {
    if (resp.http.X-Varnish ~ "[0-9]+ +[0-9]+") {
      set resp.http.X-Cache = "HIT";
    } else {
      set resp.http.X-Cache = "MISS";
    }
}

sub vcl_backend_error {
    include "/etc/varnish/error_page.vcl";
    return (deliver);
}

# Clients' configuration.
# include "/etc/varnish/latartetropezienne.vcl";
