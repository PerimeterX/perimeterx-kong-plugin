![image](https://s.perimeterx.net/logo.png)

[PerimeterX](http://www.perimeterx.com) Kong Plugin
=============================================================

Table of Contents
-----------------

-   [Getting Started](#gettingstarted)
    *   [Dependencies](#dependencies)
    *   [Requirements](#requirements)
    *   [Installation](#installation)
    *   [Installing on Amazon Linux](#awsinstall)
    *   [Basic Usage Example](#basic-usage)
-   [Configuration](#configuration)
    *   [Blocking Score](#blocking-score)
    *   [Monitoring mode](#monitoring-mode)
    *   [Enable/Disable Captcha](#captcha-support)
    *   [Select Captcha Provider](#captcha-provider)
    *   [Enabled Routes](#enabled-routes)
    *   [Sensitive Routes](#sensitive-routes)
    *   [Extracting Real IP Address](#real-ip)
    *   [Filter Sensitive Headers](#sensitive-headers)
    *   [API Timeout](#api-timeout)
    *   [Send Page Activities](#send-page-activities)
    *   [Debug Mode](#debug-mode)
    *   [Custom Block Page](#customblockpage)    
    *   [Multiple App Support](#multipleapps)
    *   [Additional Activity Handler](#add-activity-handler)
    *   [Whitelisting](#whitelisting)

<a name="gettingstarted"></a> Getting Started
----------------------------------------

<a name="dependencies"></a> Dependencies
----------------------------------------
- [Kong](https://getkong.org/) 
- [LuaJIT](http://luajit.org/)
- [Lua CJSON](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [Lua Resty HTTP](https://github.com/pintsized/lua-resty-http)
- [Lua Resty Nettle](https://github.com/bungle/lua-resty-nettle)
- [lustache](https://github.com/Olivine-Labs/lustache)
- [GNU Nettle >= v3.2](https://www.lysator.liu.se/~nisse/nettle/)

To install package dependecies on Ubuntu run:

`sudo apt-get update && sudo apt-get install lua-cjson libnettle6 nettle-dev luarocks luajit libluajit-5.1-dev ca-certificates`

All Lua dependecies are automatically fulfilled with Luarocks.

<a name="installation"></a> Installation
----------------------------------------

Installation can be done using [luarocks](https://luarocks.org/).

```sh
$ luarocks install kong-plugin-perimeterx
```

Manual installation can accomplished by downoading the sources for this repository and running `sudo make install`.  

<a name="awsinstall"></a> Additional steps for installing on Amazon Linux
----------------------------------------  
### For Nginx+: 
Install the lua modules provided by the Nginx team via yum as shown below as well as the CA certificates bundle which will be required when you configure Nginx.

```
yum -y install nginx-plus-module-lua ca-certificates.noarch
```

Download and compile nettle. 
> Side note: Use the version neccessary for your environment. 

```
yum -y install m4 # prerequisite for nettle
cd /tmp/
wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
tar -xzf nettle-3.3.tar.gz
cd nettle-3.3
./configure
make clean && make install
cd /usr/lib64 && ln -s /usr/local/lib64/libnettle.so . 
```

Make sure to change the path shown below in the "Lua CA Certificates" section as Amazon Linux stores the CA required in a different location than shown.

If running Amazon Linux this is the trusted certificate path please use:  

```
lua_ssl_trusted_certificate "/etc/pki/tls/certs/ca-bundle.crt";
```

<a name="requirements"></a> NGINX Configuration File Requirements
-----------------------------------------------


### Resolver
Add the directive `resolver A.B.C.D;` in the HTTP section of your configuration. This is required so NGINX can resolve the PerimeterX API DNS name. `A.B.C.D` is the IP address of your DNS resolver.


### Lua CA Certificates
To support TLS to PerimeterX servers, you must point Lua to the trusted certificate location (actual location may differ between Linux distributions).

```
lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
lua_ssl_verify_depth 3;
```

In CentOS/RHEL systems, the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`.

### <a name="basic-usage"></a> Basic Usage Example

Ensure that you followed the NGINX Configuration Requirements section before proceeding.

Load the plugin by adding `perimeterx` to the `custom_plugins` list in your Kong configuration (on each Kong node):

```
custom_plugins = perimeterx
```
Note: you can also set this property via its environment variable equivalent: `KONG_CUSTOM_PLUGINS`.

To apply PerimeterX enforcement, add the perimeterx plugin to your API(s):

```bash
curl -i -X POST \
      --url http://localhost:8001/apis/<api-name>/plugins/ \
      --data 'name=perimeterx' \
      --data 'config.px_appId=PX_APP_ID' \
      --data 'config.auth_token=AUTH_TOKEN' \
      --data 'config.cookie_secret=COOKIE_KEY'
```
You can find your app ID, authentication token, and cookie key under your account's admin section in [PerimeterX Portal](https://console.perimeterx.com)


### <a name="configuration"></a> Configuration Options

#### Configuring Required Parameters

Configuration options are set via Kong's admin API, as config parameter. 

#### Required parameters:

- px_appId
- cookie_secret
- auth_token

#### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

**Default blocking value:** 100

```bash
--data 'config.blocking_score=60'
```

#### <a name="monitoring-mode"></a> Blocking Mode

**Default:** false

```bash
--data 'config.block_enabled=true'
```

The PerimeterX plugin is enabled in monitor only mode by default.

Setting the  block_enabled flag to *true* will activate the module to enforce the blocking score. The PerimeterX module will block users crossing the block score threshold that you define. If a user crosses the minimum block score then the user will receive the block page.



#### <a name="captcha-support"></a>Enable/Disable CAPTCHA on the block page

By enabling CAPTCHA support, a CAPTCHA will be served as part of the block page, giving real users the ability to identify as a human. By solving the CAPTCHA, the user's score is then cleaned up and the user is allowed to continue.

**Default: true**

```bash
--data 'config.captcha_enabled=false'
```


#### <a name="captcha-provider"></a>Select CAPTCHA Provider

The CAPTCHA part of the block page can use one of the following:
* [reCAPTCHA](https://www.google.com/recaptcha)
* [FunCaptcha](https://www.funcaptcha.com/)

**Default: 'reCaptcha'**
```bash
--data 'config.captcha_provider=funCaptcha'
```

#### <a name="enabled-routes"></a> Enabled Routes

The enabled routes variable allows you to implicitly define a set of routes which the plugin will be active on. Supplying an empty list will set all application routes as active.

**Default: Empty list (all routes)**

```bash
--data 'config.enabled_routes=/blockhere'
```

#### <a name="sensitive-routes"></a> Sensitive Routes

Lists of route prefixes and suffixes. The PerimeterX module will always match the request URI with these lists, and if a match is found will create a server-to-server call, even if the cookie is valid and its score is low.

**Default: Empty list**

```bash
--data 'config.sensitive_routes_prefix=/login,/user/profile' 
--data 'config.sensitive_routes_suffix=/download'
```

#### <a name="sensitive-headers"></a> Filter sensitive headers
A list of sensitive headers can be configured to prevent specific headers from being sent to PerimeterX servers (lower case header names). Filtering cookie headers for privacy is set by default, and can be overridden on the `pxConfig` variable.

**Default: cookie, cookies**

```bash
--data 'config.sensitive_headers=cookie,cookies,secret-header'
```

#### <a name="api-timeout"></a>API Timeout Milliseconds
> Note: Controls the timeouts for PerimeterX requests. The API is called when a Risk Cookie does not exist, or is expired or invalid.

API Timeout in milliseconds (float) to wait for the PerimeterX server API response.

**Default:** 1000

```bash
--data 'config.s2s_timeout=250'
```

#### <a name="send-page-activities"></a> Send Page Activities

A boolean flag to determine whether or not to send activities and metrics to PerimeterX, on each page request. Disabling this feature will prevent PerimeterX from receiving data populating the PerimeterX portal, containing valuable information such as the amount of requests blocked and other API usage statistics.

**Default:** true

```bash
--data 'config.send_page_requested_activity=false'
```

#### <a name="debug-mode"></a> Debug Mode

Enables debug logging mode.

**Default:** false

```bash
--data 'config.px_debug=true'
```

#### <a name="real-ip"></a> Extracting the real IP address from a request

> Note: It is important that the real connection IP is properly extracted when your NGINX server sits behind a load balancer or CDN. The PerimeterX module requires the user's real IP address.

For the PerimeterX NGINX module to see the real user's IP address, you need to set `ip_headers`, a list of headers to extract the real IP from, ordered by priority.

**Default with no predefined header: `ngx.var.remote_addr`**

Example:

```bash
--data 'config.ip_headers=X-TRUE-IP,X-Forwarded-For'
```

#### <a name="customblockpage"></a> Custom Block Page

Customizing block page can be done by 2 methods:
##### Modifying default block pages
PerimeterX default block page can be modified by injecting custom css, javascript and logo to page

**default values:** nil

Example:

```bash
--data 'config.custom_logo= http://www.example.com/logo.png'
--data 'config.css_ref=http://www.example.com/style.css'
--data 'config.js_ref=http://www.example.com/script.js'
```
##### Redirect to a custom block page url
Users can customize the blocking page to meet their branding and message requirements by specifying the URL to a blocking page HTML file. The page can also implement reCaptcha. See [NGINX plugin docs](https://github.com/PerimeterX/perimeterx-nginx-plugin/tree/master/examples) for examples of a customized Captcha page.

**default:** nil

```bash
--data 'config.custom_block_url=http://www.example.com/block.html'
```

> Note: This URI has to be whitelisted under `config.whitelist.uri_full` to avoid infinite redirects.


#### <a name="redirect_on_custom_url"></a> Redirect on Custom URL
The `_M.redirect_on_custom_url` flag provides 2 options for redirecting users to a block page.

**default:** false

```bash
--data 'config.redirect_on_custom_url=false'
```

By default, when a user crosses the blocking threshold and blocking is enabled, the user will be redirected to the block page defined by the `_M.custom_block_url` variable, responding with a 307 (Temporary Redirect) HTTP Response Code.


Setting the flag to flase will *consume* the page and serve it under the current URL, responding with a 403 (Unauthorized) HTTP Response Code.

>_Setting the flag to **false** does not require the block page to include any of the coming examples, as they are injected into the blocking page via the PerimeterX Nginx Enforcer._

Setting the flag to **true** (enabling redirects) will result with the following URL upon blocking:

```
http://www.example.com/block.html?url=L3NvbWVwYWdlP2ZvbyUzRGJhcg==&uuid=e8e6efb0-8a59-11e6-815c-3bdad80c1d39&vid=08320300-6516-11e6-9308-b9c827550d47
```
>Note: the **url** variable is comprised of URL Encoded query parameters (of the originating request) and then both the original path and variables are Base64 Encoded (to avoid collisions with block page query params). 

 

###### Custom blockpage requirements:

When captcha is enabled, and `_M.redirect_on_custom_url` is set to **true**, the block page **must** include the following:

* The `<head>` section **must** include:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
function handleCaptcha(response) {
    var vid = getQueryString("vid"); // getQueryString is implemented below
    var uuid = getQueryString("uuid");
    var name = '_pxCaptcha';
    var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
    var cookieParts = [name, '=', btoa(JSON.stringify({r: response, v:vid, u:uuid})), '; expires=', expiryUtc, '; path=/'];
    document.cookie = cookieParts.join('');
    var originalURL = getQueryString("url");
    var originalHost = window.location.host;
    window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
}

// for reference : http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript

function getQueryString(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    results[2] = decodeURIComponent(results[2].replace(/\+/g, " "));
    if(name == "url") {
      results[2] = atob(results[2]); //Not supported on IE Browsers
    }
    return results[2];
}
</script>
```
* The `<body>` section **must** include:

```
<div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
```

* And the [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt) (availabe on the PerimeterX Portal via this link) must be pasted in.

#### Configuration example:
 
```bash
--data 'config.custom_block_url=/block.html'
--data 'config.redirect_on_custom_url=true'
```


#### Block page implementation full example: 

```html
<html>
    <head>
        <script src="https://www.google.com/recaptcha/api.js"></script>
        <script>
        function handleCaptcha(response) {
            var vid = getQueryString("vid");
            var uuid = getQueryString("uuid");
            var name = '_pxCaptcha';
            var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
            var cookieParts = [name, '=', btoa(JSON.stringify({r: response, v:vid, u:uuid})), '; expires=', expiryUtc, '; path=/'];
            document.cookie = cookieParts.join('');
            // after getting resopnse we want to reaload the original page requested
            var originalURL = getQueryString("url");
            var originalHost = window.location.host;
            window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
        }
       
       // http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
    function getQueryString(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        if(name == "url") {
          results[2] = atob(results[2]); //Not supported on IE Browsers
        }
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }

        </script>
    </head>
    <body>
        <h1>You are Blocked</h1>
        <p>Try and solve the captcha</p> 
        <div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
    </body>
<html>
```

#### <a name="multipleapps"></a> Multiple App Support
The PerimeterX Enforcer allows for multiple configurations for different apps.

If your PerimeterX account contains several Applications (as defined via the portal), follow these steps to create different configurations for each Application.

Since Kong supports multiple APIs, you can also use the same PerimeterX Application with different configuration for different APIs, but for best results in our detection,
it is best to use different Applications and policies for different APIs.

#### <a name="add-activity-handler"></a> Additional Activity Handler
Adding an additional activity handler is done by setting 'additional_activity_handler' with a user defined function on the 'pxconfig.lua' file. The 'additional_activity_handler' function will be executed before sending the data to the PerimeterX portal.  
Because of technical limitations of the Kong platform, you can't set this function using the admin API. Instead, you need to edit the PerimeterX plugin's `handler.lua`
file, and add the function directly to the configuration.

Default: Only send activity to PerimeterX.

```lua
function additional_activity_handler(event_type, ctx, details)
	local cjson = require "cjson"
	if (event_type == 'block') then
		logger.warning("PerimeterX " + event_type + " blocked with score: " + ctx.score + "details " + cjson.encode(details))
	else
		logger.info("PerimeterX " + event_type + " details " +  cjson.encode(details))
	end
end

function PXHandler:init_worker(config)
    PXHandler.super.init_worker(self)
    ...
    --add function to pxconfig here
    pxconfig.additional_activity_handler = additional_activity_handler
end
```

<a name="whitelisting"></a> Whitelisting
-----------------------------------------------
Whitelisting (bypassing enforcement) is configured under in the `whitelist` table.

There are several different types of filters that can be configured.

```
whitelist = {
	uri_full = { custom_block_url },
	uri_prefixes = {},
	uri_suffixes = {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar'},
	ip_addresses = {},
	ua_full = {},
	ua_sub = {}
}
```

- **uri_full** : for value `{'/api_server_full'}` - will filter requests to `/api_server_full?data=1` but not to `/api_server?data=1`
- **uri_prefixes** : for value `{'/api_server'}` - will filter requests to `/api_server_full?data=1` but not to `/full_api_server?data=1` 
- **uri_suffixes** : for value `{'.css'}` - will filter requests to `/style.css` but not to `/style.js`
- **ip_addresses** : for value `{'192.168.99.1'}` - will filter requests coming from any of the listed ips.
- **ua_full** : for value `{'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}` - will filter all requests matching this exact UA. 
- **ua_sub** : for value `{'GoogleCloudMonitoring'}` - will filter requests containing the provided string in their UA.


<a name="contributing"></a> Contributing
----------------------------------------
The following steps are welcome when contributing to our project.

### Fork/Clone
[Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
Create a branch on your fork, preferably using a descriptive branch name.

### Pull Request
After you have completed the process, create a pull request. Please provide a complete and thorough description explaining the changes. Remember, this code has to be read by our maintainers, so keep it simple, smart and accurate.

### Thanks
After all, you are helping us by contributing to this project, and we want to thank you for it.
We highly appreciate your time invested in contributing to our project, and are glad to have people like you - kind helpers.
