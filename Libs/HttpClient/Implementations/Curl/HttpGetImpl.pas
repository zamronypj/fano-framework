{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit GetImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    InjectableObjectImpl,
    HttpClientIntf;

type

    (*!------------------------------------------------
     * class that send HTTP GET to server
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    THttpGet = class(TInjectableObject, IHttpClient)
    private
        (*!------------------------------------------------
         * build URL with query string appended
         *-----------------------------------------------
         * @param url url to send request
         * @param data data related to this request
         * @return url with query string appended
         *-----------------------------------------------*)
        function buildUrlWithQueryParams(
            const url : string;
            const data : ISerializeable = nil
        ) : string;
    public

        (*!------------------------------------------------
         * send HTTP request
         *-----------------------------------------------
         * @param url url to send request
         * @param data data related to this request
         * @return current instance
         *-----------------------------------------------*)
        function send(
            const url : string;
            const data : ISerializeable = nil
        ) : IResponse;

    end;

implementation

uses

    libcurl;

    (*!------------------------------------------------
     * build URL with query string appended
     *-----------------------------------------------
     * @param url url to send request
     * @param data data related to this request
     * @return url with query string appended
     *-----------------------------------------------*)
    function THttpGet.buildUrlWithQueryParams(
        const url : string;
        const data : ISerializeable = nil
    ) : string;
    var params : string;
    begin
        result := url;
        if (data <> nil) then
        begin
            params := data.serialize();
            if (pos('?', result) > 0) then
            begin
                //if we get here URL already contains query parameters
                result := result + params;
            end else
            begin
                //if we get here, URL has no query parameters
                result := result + '?' + params;
            end;
        end;
    end;

    (*!------------------------------------------------
     * send HTTP request
     *-----------------------------------------------
     * @param url url to send request
     * @param data data related to this request
     * @return current instance
     *-----------------------------------------------
     * @credit: https://github.com/graemeg/freepascal/blob/master/packages/libcurl/examples/testcurl.pp
     *-----------------------------------------------*)
    function THttpGet.send(
        const url : string;
        const data : ISerializeable = nil
    ) : IResponse;
    var hCurl : pCurl;
        fullUrl : string;
    begin
        hCurl:= curl_easy_init();
        if assigned(hCurl) then
        begin
            fullUrl := buildUrlWithQueryParams(url, data);
            curl_easy_setopt(hCurl,CURLOPT_URL, [ fullUrl ]);
            curl_easy_perform(hCurl);
            curl_easy_cleanup(hCurl);
        end;
        result := self;
    end;

end.