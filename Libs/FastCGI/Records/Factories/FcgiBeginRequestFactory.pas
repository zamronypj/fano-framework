{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit FcgiBeginRequestFactory;

interface

{$MODE OBJFPC}
{$H+}

uses

    FcgiRecordIntf,
    FcgiRecordFactory;

type

    (*!-----------------------------------------------
     * Begin Request record factory (FCGI_BEGIN_REQUEST)
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TFcgiBeginRequestFactory = class(TFcgiRecordFactory)
    public
        (*!------------------------------------------------
         * build fastcgi record from stream
         *-----------------------------------------------
         * @return instance IFcgiRecord of corresponding fastcgi record
         *-----------------------------------------------*)
        function build() : IFcgiRecord; override;
    end;

implementation

uses

    fastcgi,
    classes,
    FcgiBeginRequest,
    StreamAdapterImpl;


    (*!------------------------------------------------
     * build fastcgi record from stream
     *-----------------------------------------------
     * @return instance IFcgiRecord of corresponding fastcgi record
     *-----------------------------------------------*)
    function TFcgiBeginRequestFactory.build() : IFcgiRecord;
    var rec : PFCGI_BeginRequestRecord;
    begin
        rec := tmpBuffer;
        result := TFcgiBeginRequest.create(
            TStreamAdapter.create(TMemoryStream.create()),
            rec^.header.requestID,
            rec^.body.role,
            rec^.body.flags
        );
    end;
end.
