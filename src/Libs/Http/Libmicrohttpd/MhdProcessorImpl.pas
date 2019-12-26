{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit MhdProcessorImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    StreamAdapterIntf,
    CloseableIntf,
    RunnableIntf,
    RunnableWithDataNotifIntf,
    ProtocolProcessorIntf,
    StreamIdIntf,
    ReadyListenerIntf,
    libmicrohttpd;

type

    (*!-----------------------------------------------
     * Class which can process request from libmicrohttpd web server
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TMhdProcessor = class(TInterfacedObject, IProtocolProcessor, IRunnableWithData)
    private
        fPort : word;
        fHost : string;
        fRequestReadyListener : IReadyListener;
        fDataListener : IDataAvailListener;
        fStdIn : IStreamAdapter;

        procedure resetInternalVars();
        procedure waitUntilTerminate();

        function handle(
            connection : PMHD_Connection;
            url : pcchar;
            method : pcchar;
            version : pcchar;
            upload_data : pcchar;
            upload_data_size : psize_t;
            ptr : ppointer
        ): cint;
    public
        constructor create(const host : string; const port : word);
        destructor destroy(); override;

        (*!------------------------------------------------
         * process request stream
         *-----------------------------------------------*)
        function process(
            const stream : IStreamAdapter;
            const streamCloser : ICloseable;
            const streamId : IStreamId
        ) : boolean;

        (*!------------------------------------------------
         * get StdIn stream for complete request
         *-----------------------------------------------*)
        function getStdIn() : IStreamAdapter;

        (*!------------------------------------------------
         * set listener to be notified when request is ready
         *-----------------------------------------------
         * @return current instance
         *-----------------------------------------------*)
        function setReadyListener(const listener : IReadyListener) : IProtocolProcessor;

        (*!------------------------------------------------
         * get number of bytes of complete request based
         * on information buffer
         *-----------------------------------------------
         * @return number of bytes of complete request
         *-----------------------------------------------*)
        function expectedSize(const buff : IStreamAdapter) : int64;

        (*!------------------------------------------------
         * run it
         *-------------------------------------------------
         * @return current instance
         *-------------------------------------------------*)
        function run() : IRunnable;

        (*!------------------------------------------------
        * set instance of class that will be notified when
        * data is available
        *-----------------------------------------------
        * @param dataListener, class that wish to be notified
        * @return true current instance
        *-----------------------------------------------*)
        function setDataAvailListener(const dataListener : IDataAvailListener) : IRunnableWithDataNotif;
    end;

implementation

uses

    SysUtils,
    BaseUnix,
    TermSignalImpl;

    constructor TMhdProcessor.create(const host : string; const port : word);
    begin
        inherited create();
        fHost := host;
        fPort := port;
        fRequestReadyListener := nil;
        fDataListener := nil;
        fStdIn := nil;
    end;

    destructor TMhdProcessor.destroy();
    begin
        resetInternalVars();
        inherited destroy();
    end;

    procedure TMhdProcessor.resetInternalVars();
    begin
        fRequestReadyListener := nil;
        fDataListener := nil;
        fStdIn := nil;
    end;

    (*!------------------------------------------------
     * process request stream
     *-----------------------------------------------*)
    function TMhdProcessor.process(
        const stream : IStreamAdapter;
        const streamCloser : ICloseable;
        const streamId : IStreamId
    ) : boolean;
    begin
        result := true;
        if assigned(fRequestReadyListener) then
        begin
            fRequestReadyListener.ready(
                stream,
                getEnv(),
                getStdIn()
            );
        end;
    end;

    (*!------------------------------------------------
     * get StdIn stream for complete request
     *-----------------------------------------------*)
    function TMhdProcessor.getStdIn() : IStreamAdapter;
    begin
        result := fStdIn;
    end;

    (*!------------------------------------------------
     * set listener to be notified weh request is ready
     *-----------------------------------------------
     * @return current instance
     *-----------------------------------------------*)
    function TMhdProcessor.setReadyListener(const listener : IReadyListener) : IProtocolProcessor;
    begin
        fRequestReadyListener := listener;
        result := self;
    end;

    (*!------------------------------------------------
     * get number of bytes of complete request based
     * on information buffer
     *-----------------------------------------------
     * @return number of bytes of complete request
     *-----------------------------------------------*)
    function TMhdProcessor.expectedSize(const buff : IStreamAdapter) : int64;
    begin
        result := 0;
    end;

    procedure TMhdProcessor.waitUntilTerminate();
    var fds : TFDSet;
    begin
        fds := default(TFDSet);
        fpfd_zero(fds);
        //terminatePipeIn will be ready for IO when application is terminated
        //see TermSignalImpl unit
        fpfd_set(terminatePipeIn, FDS);
        //wait forever until terminatePipeIn changes
        fpSelect(terminatePipeIn + 1, @fds, nil, nil, nil);
    end;

    function handleRequestCallback(
        context :  pointer;
        connection : PMHD_Connection;
        url : pcchar;
        method : pcchar;
        version : pcchar;
        upload_data : pcchar;
        upload_data_size : psize_t;
        ptr : ppointer
    ): cint; cdecl;
    begin
        result := TMhdProcessor(context).handle(
            connection,
            url,
            method,
            version,
            upload_data,
            upload_data_size,
            ptr
        );
    end;

    function TMhdProcessor.handle(
        connection : PMHD_Connection;
        url : pcchar;
        method : pcchar;
        version : pcchar;
        upload_data : pcchar;
        upload_data_size : psize_t;
        ptr : ppointer
    ): cint;
    var request : IRequest;
    begin
        request := TMhdRequest.create(
            connection,
            method,
            url,
            upload_data,
            upload_data_size
        );

        MHD_get_connection_values(
            connection,
            MHD_GET_ARGUMENT_KIND,
            @getKeyValueData,
            fQuery
        );
        fDataListener.handleData(
            stream,
            self,
            self,
            self
        );
        result := MHD_YES;
    end;

    (*!------------------------------------------------
     * run it
     *-------------------------------------------------
     * @return current instance
     *-------------------------------------------------*)
    function TMhdProcessor.run() : IRunnable;
    var
        svrDaemon : PMHD_Daemon;
    begin
        svrDaemon := MHD_start_daemon(
            // MHD_USE_SELECT_INTERNALLY or MHD_USE_DEBUG or MHD_USE_POLL,
             MHD_USE_SELECT_INTERNALLY or MHD_USE_DEBUG,
            // MHD_USE_THREAD_PER_CONNECTION or MHD_USE_DEBUG or MHD_USE_POLL,
            // MHD_USE_THREAD_PER_CONNECTION or MHD_USE_DEBUG,
            fPort,
            nil,
            nil,
            @handleRequestCallback,
            self,
            MHD_OPTION_CONNECTION_TIMEOUT, cuint(120),
            MHD_OPTION_END
        );
        if svrDaemon <> nil then
        begin
            waitUntilTerminate();
            MHD_stop_daemon(svrDaemon);
        end;

    end;

    (*!------------------------------------------------
     * set instance of class that will be notified when
     * data is available
     *-----------------------------------------------
     * @param dataListener, class that wish to be notified
     * @return true current instance
     *-----------------------------------------------*)
    function TMhdProcessor.setDataAvailListener(const dataListener : IDataAvailListener) : IRunnableWithDataNotif;
    begin
        fDataListener := dataListener;
    end;
end.