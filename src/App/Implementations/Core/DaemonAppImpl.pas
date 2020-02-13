{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}
unit DaemonAppImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    RunnableIntf,
    CloseableIntf,
    DependencyContainerIntf,
    DispatcherIntf,
    EnvironmentIntf,
    ErrorHandlerIntf,
    OutputBufferIntf,
    DataAvailListenerIntf,
    RunnableWithDataNotifIntf,
    DaemonAppServiceProviderIntf,
    StdOutIntf,
    StdInIntf,
    RouteBuilderIntf,
    ProtocolProcessorIntf,
    ReadyListenerIntf,
    StreamAdapterIntf,
    StreamIdIntf,
    CoreAppConsts,
    CoreAppImpl;

type

    (*!-----------------------------------------------
     * Base web application that implements IWebApplication
     * which run as daemon
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TDaemonWebApplication = class(TCoreWebApplication, IDataAvailListener, IReadyListener)
    private
        fDaemonAppSvc : IDaemonAppServiceProvider;

        (*!-----------------------------------------------
         * attach ourself as listener and run socket server
         *-----------------------------------------------
         * Note that run keeps run until application is terminated
         *-----------------------------------------------*)
        procedure attachListenerAndRunServer();

        procedure cleanUp();
    protected
        procedure executeRequest(const env : ICGIEnvironment);
    public
        (*!-----------------------------------------------
         * constructor
         *------------------------------------------------
         * @param appSvc class provide essentials service
         * @param routeBuilder class responsible to build application routes
         *-----------------------------------------------*)
        constructor create(
            const appSvc : IDaemonAppServiceProvider;
            const routeBuilder : IRouteBuilder
        );
        destructor destroy(); override;
        function run() : IRunnable; override;

        (*!------------------------------------------------
         * called when socket stream contains data
         *-----------------------------------------------
         * @param stream, stream of socket
         * @param context, sender i.e, TSocketServer instance
         * @param streamCloser, instance that can close stream if required
         * @return true if data is handled
         *-----------------------------------------------*)
        function handleData(
            const stream : IStreamAdapter;
            const context : TObject;
            const streamCloser : ICloseable;
            const streamId : IStreamId
        ) : boolean;

        (*!------------------------------------------------
         * FastCGI request is ready
         *-----------------------------------------------
         * @param socketStream, original socket stream
         * @param env, CGI environment
         * @param stdInStream, stream contains POST-ed data
         * @return true request is handled
         *-----------------------------------------------*)
        function ready(
            const socketStream : IStreamAdapter;
            const env : ICGIEnvironment;
            const stdInStream : IStreamAdapter
        ) : boolean;
    end;

implementation

uses

    SysUtils,
    EnvironmentEnumeratorIntf,
    ERouteHandlerNotFoundImpl,
    EMethodNotAllowedImpl,
    EInvalidMethodImpl,
    ESockBindImpl,
    ESockCreateImpl,
    ESockListenImpl;

    (*!-----------------------------------------------
     * constructor
     *------------------------------------------------
     * @param appSvc class provide essentials service
     * @param routeBuilder class responsible to build application routes
     *-----------------------------------------------*)
    constructor TDaemonWebApplication.create(
        const appSvc : IDaemonAppServiceProvider;
        const routeBuilder : IRouteBuilder
    );
    begin
        inherited create(appSvc, routeBuilder);
        fDaemonAppSvc := appSvc;
    end;

    procedure TDaemonWebApplication.cleanUp();
    begin
        fDaemonAppSvc := nil;
        reset();
    end;

    destructor TDaemonWebApplication.destroy();
    begin
        cleanUp();
        inherited destroy();
    end;

    (*!-----------------------------------------------
     * attach ourself as listener and run socket server
     *-----------------------------------------------
     * Note that run keeps run until application is terminated
     *-----------------------------------------------*)
    procedure TDaemonWebApplication.attachListenerAndRunServer();
    begin
        //This is to ensure that reference count of our instance
        //properly incremented/decremented so no memory leak
        fDaemonAppSvc.protocol.setReadyListener(self);
        try
            fDaemonAppSvc.server.setDataAvailListener(self);
            try
                try
                    //execute run loop until terminated
                    fDaemonAppSvc.server.run();
                except
                    //TODO add better exception handling for ESockBind, ESockListen, ESockCreate
                    on e : ESockCreate do
                    begin
                        writeln(e.message);
                    end;
                    on e : ESockBind do
                    begin
                        writeln(e.message);
                    end;
                    on e : ESockListen do
                    begin
                        writeln(e.message);
                    end;
                end;
            finally
                fDaemonAppSvc.server.setDataAvailListener(nil);
            end;
        finally
            fDaemonAppSvc.protocol.setReadyListener(nil);
        end;
    end;

    (*!-----------------------------------------------
     * run application
     *------------------------------------------------
     * @return current instance.
     *-----------------------------------------------
     * Note that run keeps run until application is terminated
     *-----------------------------------------------*)
    function TDaemonWebApplication.run() : IRunnable;
    begin
        try
            if (initialize(fDaemonAppSvc.container)) then
            begin
                attachListenerAndRunServer();
            end;
            result := self;
        except
            cleanUp();
            raise;
        end;
    end;

    (*!-----------------------------------------------
     * execute request
     *------------------------------------------------
     * @param env, CGI environment
     *-----------------------------------------------*)
    procedure TDaemonWebApplication.executeRequest(const env : ICGIEnvironment);
    begin
        try
            execute(env);
        except
            on e : EInvalidRequest do
            begin
                fAppSvc.errorHandler.handleError(fAppSvc.env.enumerator, e, 400, sHttp400Message);
                reset();
            end;

            on e : ERouteHandlerNotFound do
            begin
                fDaemonAppSvc.errorHandler.handleError(env.enumerator, e, 404, sHttp404Message);
            end;

            on e : EMethodNotAllowed do
            begin
                fDaemonAppSvc.errorHandler.handleError(env.enumerator, e, 405, sHttp405Message);
            end;

            on e : EInvalidMethod do
            begin
                fDaemonAppSvc.errorHandler.handleError(env.enumerator, e, 501, sHttp501Message);
            end;

            on e : Exception do
            begin
                fDaemonAppSvc.errorHandler.handleError(env.enumerator, e);
            end;
        end;
    end;

    (*!-----------------------------------------------
     * called when socket contain data available to be
     * processed
     *------------------------------------------------
     * @param stream, socket stream
     * @param context, additional related data related,
     *        mostly contain sender (if any)
     * @param streamCloser, instance that can close stream if required
     * @return true if data is handled
     *-----------------------------------------------*)
    function TDaemonWebApplication.handleData(
        const stream : IStreamAdapter;
        const context : TObject;
        const streamCloser : ICloseable;
        const streamId : IStreamId
    ) : boolean;
    begin
        result := fDaemonAppSvc.protocol.process(stream, streamCloser, streamId);
    end;

    (*!------------------------------------------------
     * Request is ready
     *-----------------------------------------------
     * @param socketStream, original socket stream
     * @param env, CGI environment
     * @param stdInStream, stream contains POST-ed data
     * @return true request is handled
     *-----------------------------------------------*)
    function TDaemonWebApplication.ready(
        const socketStream : IStreamAdapter;
        const env : ICGIEnvironment;
        const stdInStream : IStreamAdapter
    ) : boolean;
    begin
        //buffer STDOUT, so any write()/writeln() will be buffered to stream
        fDaemonAppSvc.outputBuffer.beginBuffering();
        try
            //when we get here, CGI environment and any POST data are ready
            fDaemonAppSvc.stdIn.setStream(stdInStream);
            executeRequest(env);
        finally
            fDaemonAppSvc.outputBuffer.endBuffering();
            //write response back to web server (i.e FastCGI client)
            fDaemonAppSvc.stdOut.setStream(socketStream).write(fDaemonAppSvc.outputBuffer.flush());
        end;
        result := true;
    end;
end.
