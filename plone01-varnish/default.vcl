# VCL file optimized for Plone with a webserver in front.  See vcl(7) for details

backend default {
    .host = "127.0.0.1";
    .port = "5021";
}

backend ploneorg {
    .host = "127.0.0.1";
    .port = "5021";
}

backend stagingploneorg {
    .host = "127.0.0.1";
    .port = "6021";
}

acl purge {
    "localhost";
    "127.0.0.1";
}

sub normalize_accept_encoding {
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpe?g|png|gif|swf|pdf|gz|tgz|bz2|tbz|zip)$" || req.url ~ "/image_[^/]*$") {
            # No point in compressing these
            remove req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else {
            remove req.http.Accept-Encoding;
        }
    }
}

sub annotate_request {
    if (!(req.http.Authorization || req.http.cookie ~ "(^|; )__ac=")) {
        set req.http.X-Anonymous = "true";
    }
}

sub rewrite_age {
    if (resp.http.Age) {
        # By definition we have a fresh object
        set resp.http.X-Varnish-Age = resp.http.Age;
        set resp.http.Age = "0";
    }
}

sub rewrite_s_maxage {
    # rewrite s-maxage as intermediary proxies cannot be purged
    if (resp.http.Cache-Control ~ "s-maxage") {
        set resp.http.Cache-Control = regsub(resp.http.Cache-Control, "s-maxage=[0-9]+", "s-maxage=0");
    }
}

sub vcl_recv {
    set req.grace = 120s;
    if (!req.http.host || req.http.host ~ "(^media\.|^dist\.|^manage\.|^old\.|^www\.|^)staging.plone.org") {
        set req.backend = stagingploneorg;
        return(pipe);
    } else if (!req.http.host || req.http.host ~ "(^manage\.|^old\.|^)plone.org") {
        set req.backend = ploneorg;
    } else {
        set req.backend = default;
        if (req.http.host == "media.plone.org" || req.http.host == "dist.plone.org") {
            return(pipe);
        }
    }
    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
                error 405 "Not allowed.";
        }
        purge_url(req.url);
        error 200 "Purged";
    }
    if (req.request != "GET" && req.request != "HEAD") {
        # We only deal with GET and HEAD by default
        return(pass);
    }
    call normalize_accept_encoding;
    call annotate_request;
    return(lookup);
}

sub vcl_fetch {
    if (!beresp.cacheable) {
        set beresp.http.X-Varnish-Action = "FETCH (pass - not cacheable)";
        return(pass);
    }
    if (beresp.http.Set-Cookie) {
        set beresp.http.X-Varnish-Action = "FETCH (pass - response sets cookie)";
        return(pass);
    }
    if (!beresp.http.Cache-Control ~ "s-maxage=[1-9]" && beresp.http.Cache-Control ~ "(private|no-cache|no-store)") {
        set beresp.http.X-Varnish-Action = "FETCH (pass - response sets private/no-cache/no-store token)";
        return(pass);
    }
    if (req.http.Authorization && !beresp.http.Cache-Control ~ "public") {
        set beresp.http.X-Varnish-Action = "FETCH (pass - authorized and no public cache control)";
        return(pass);
    }
    if (!req.http.X-Anonymous && !beresp.http.Cache-Control ~ "public") {
        set beresp.http.X-Varnish-Action = "FETCH (pass - authorized and no public cache control)";
        return(pass);
    }
    return(deliver);
}

sub vcl_deliver {
    call rewrite_s_maxage;
    call rewrite_age;
}

sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html>
  <head>
    <title>plone.org is undergoing maintenance</title>
    <style>body {font-family: "Helvetica Neue", Arial; width: 28em; margin: 3em auto 0 auto;}</style>
  </head>
  <body>
     <a href="http://plone.org"><img src="data:image/png,%89PNG%0D%0A%1A%0A%00%00%00%0DIHDR%00%00%00%F5%00%00%00%40%08%03%00%00%00%F5h%C1%91%00%00%00%09pHYs%00%00%0B%13%00%00%0B%13%01%00%9A%9C%18%00%00%003PLTE%00%83%BE%10%8B%C2%20%93%C60%9A%CA%40%A2%CEP%AA%D2%60%B2%D6p%B9%DB%7F%C1%DE%8F%C9%E2%9F%D0%E7%AF%D8%EB%BF%E0%EF%CF%E8%F3%DF%EF%F7%EF%F7%FB%FF%FF%FF%D3P%3A%CE%00%00%058IDATh%DE%E5%9B%D7%9A%AB%20%10%80)%23%22R%E6%FD%9F%F6%5C%C4B%19%8AIN%DC%2F%E1r%D7%20%3FLgdH%8F%60%F5%24%D96%60%D2%16%BFi0%12y%01V%8C%C9%84o%A6%B6%8A%D1%83%2B%FF%AD%D4%16Xc%7C%09wF%1D%14%EB%8C9%7C%1D%F5%CAYw%08%FBe%D4%F9As%00%00%80%7C%2B%F47Q%07%19%A3Im%0FY%0E%EB%2C%12s%1E%BE%86%DAE%D0%5C%17V%CB%CD%D1%91%CB%0E%B6-%07%15%12Xk%AD%F5wR%BB%13%8A%2Ft%E0%A2%F9(6i%10%20%DBJ%7B%9F%BE%B0R%BC%EBV%3AL%83%D85K%08%F6oQ%1F%D0%7C%5B%98%D7%000%99%EC%F1%D3%C8%ABg%A8%93-%BD%9FZ%E5g%B8lx%C2e%EA-G%2Cy%C3%F1%9DBr%3B%F5z%9C%E0%B6%A6%F9T%F2%0C%FBT%05%F7%14%F5%89%7D7u%E0%99%D8%DA8*%C1%0A%B6x%8E%3A%7F%C9m%D4*%3F%86)%5E%A5%A9a%EB%1E%F5r%3A.%13y%7C%7B'%B5%D5%EB%83z%3FY%1E%C8%B3%9A%0A%D7%BD%89%06%F7%1D%EA%D4I%9B%5D%A2%E0%3E%EA%00%CA%CC%D21D%84%7C%916u7%C5oM%CF%8E%93%D4gH%E0n%A3%9E%17%06%D2%02%3B%19g%1C%A5%3E%F6%C9_%A2%3E%E6%D5%B7Q%0BdV%20%B0C%ABO%F9F%DF%A3%F6%1D%CD%AEP%EF%BB%05%B7QKd0!0%0C%BB%E9%89%B7%24%A6%A6%E2%D3%B9m%C6k%D4%BBj%DCF%3DY%E6%B9%97l_%09%8FCL%1D%A7%9B%94%18%EF%87%BD%5E%A3v%C3%D4n%D5Z%9Bf*%EFV%ADu%3Dy%B1Fkm%F3%20K%A8%A0%C5%CAv%2F%95%BE%5C%B6%8F%FAP%0Bu%8D%1A%C7%A8%AD%E2g%8D%92%F8%3D%20%FA%E3%11i%88%05%98%A9R%EC%F33%CC%1E%19%92%86)%F4%02%CF%B5)%E25%EA0B%ED%A1%5E%BB%D9%A9u%B3%BAcE%1A%16%15%99%12%DB%DE-%F3%7FhQ%24I%C9%E0-%2B%5E%A3%B6%03%D4%B6%A8b%E9%7Cb)%B3'%0Ci%3D%AAQ52%5D%3DRo%CFj%8AU%9C11%FBB%C4%CD%25%EA%C4%08%D2%D4k%23%86%AD%87%BA%B6%05%5Db%B3%A9%A6%82%C4j%197%F9%DC%FA%0A%F5%1E%EFOujG%D6%2BM%8FZ%84%E6%B6%A5%B6%1A%91m%C2%D2%2C%12DU%C453%C7p%85Z%25%10%245%9C%95J%05%A2%F0%231(%A8%A8%8E%A9%F3%9DeR%5B%BB%1E6o%A2%D6%C7%9B%01%3B%B9i%97%A9%8FZ%FB6%07EmR%A1%B22%93%F13_%7D%CC%BD%8A%3C%01%DC4%96%AFY%F9%C7%12%EB%83%A6k'c%16%1E%19%A6%01j%BF%88%EC%5C(j%C8%05v%DF%A9%90RO%85%B3%F1%C9QG%8A%AC%88%C3%1E%A1%A6%E3S%E8SK8%06!.%04%B5%2F%B6%2B%88D%B3K5v%A9%EA%9B%D2%C8%8A%D2%DB%0CP%A7%B9%08%BF%40%DD%B6%B7%04%B5)%CF%C5%24%22NDNi%945%95a%04%B1%11%9F%A76%8D%BA%D9%5C.0%24zK%84TK2M%9E%3E%9E3%A8OI8%E5BL%ABF%0AD%E8%23%E3%F7%B0%F2%A5%C94%8E2%A3P%C4a%23%D4%F0%AC5%23%0A%E2%1E%07%A8%A9%B7%FB86%ABR%AF%14%F5T%CC%FA_%3DW%D1%EE%60%3Bw%1FTt%ACc%10%E2%A5%C94%DB%C3J%C7%A3%DC%CB%ABQ%8A%B9%12%A5D6%1Cf%5D%A9%ACh*%A5z%91%9A%1C%E1jD%AA%DE%13%91%DEKm%87%B2%0F%8C2v%3B%E5%A9%EAS%D9%C7%9F%A1%AEe%9AF%B6%FBo%9E%CA4%FF%0Cu%A5%AA%00%B5%3B%80%97%AA%0A%9F%A2%5E%88%0Bt%1B%EBu%B7%82d%DEYA%EAPs%C2%A1%A8'%A8%7B%AD3t%B5%D0%D4S%D3%97%AA%85%3D%EA%86%BF%C6!j%DB%5CVD%FDTeX%3DW%19%EEQS%0E%85_%A1%F6DDJ%DF%EE%7D%F0%16%A0G%AD%CBE%A7qA%8Fz%DB%23%D1%A7%FE%DC%8DO%97%DA%16%89%E4~%26%F3%20%B5%22%E53%107%B9%9F%BA%DD%A3%A9gB%9C%E7%A2%0A%E6%06%A9W%A2%3C%18d%DEEC%DE%E4%86%FFr%93%5B%B9%08I%AC%A5%CA%F6s%EF%83%118H%BD%9B%24~%BE%DB%C9%A2HJ%DF%DA%CB%F7%DC%DAw%1C%08%DF%2F%2F%AC%DDof%0E%8B%22%16%87%CE%14QC%9F%FAp%3FjED%0C%AB%22j%C3t%87%C6%FA%9E%0E%8D%0E%B5%22%D4%88%0E%AE%00%87%A9QV%12%7B%9FS%97%DD8%EA-%DD8%1Dj%D7(VTV%3C%40MW%D4%D3%06%B9Z%E7%D5%5E%F7%7F%A9%F3%AA%17%22%CD%04u%90%AD%9B%8B%01j%1A%5B%95z%8DT%97%9D%92%8C%C1%92%19%BFk%5Dv%DD%9EjE9%8A%B9Q%7F%19%A1F_l%5C%DE%23%FA_%3B*%FB%9D%E4G%15%3F%06I%3EG%10%06%F1%225%A2%11%E9%97%1B%94%BF%CE%E5%E2%F5%EE%D9%ADt3%D2%0E%EC%16%AD%B5%D6%A9%A3p%1A%04c%8C%C3%EC%A8%89%93%87%FD%E3oy%E7%8F%06%F9%B88%9A%D7%40%C5f%85%C6%BE%DE)%FD%D7%C7%AFw%C5%E3o~%01%81%3F%FA%B5%CB%8F~%D9%84%BF%F9%15%1B%E2o~%B1%88%F8%9B_%A7%3E%C0%BF%FAK%E4%7F'%96%C6b%AFC%BB%0F%00%00%00%00IEND%AEB%60%82" /></a>
        <p>We couldn't reach the plone.org backend server, which probably means it's undergoing maintenance, and will be back in a bit.</p>

        <p>In the meantime, you can:</p>
        <ul>
            <li><a href="https://launchpad.net/plone/+download">Download Plone</a></li>
            <li><a href="http://n2.nabble.com/Plone-f293351.subapps.html">Read/post to the Plone forums</a> using Nabble</li>
            <li>Find <a href="http://plone.net/">Plone companies and sites at plone.net</a></li>
            <li>See <a href="http://www.google.com/search?q=cache:plone.org">Google's cached version</a> of the site (if you search for Plone content via Google, there's always a link to a cached version)</li>

            <li>Follow <a href="http://twitter.com/plone" >Plone on Twitter</a> for the latest updates.</li>
        </ul>
        
       <p>We should be back shortly, sorry about the inconvenience.</p>
       <i>&mdash;The Plone Team</i>

      <small>If you are only getting this message on certain pages, but the rest of plone.org works fine, let us know in the <a href="http://dev.plone.org/plone.org">plone.org issue tracker</a>, and we'll take a look.</small>
  </body>

</html>
"};
    return(deliver);
}
