{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit JsonFileSessionManagerFactoryImpl;

interface

{$MODE OBJFPC}

uses

    DependencyIntf,
    DependencyContainerIntf,
    FactoryImpl,
    SessionConsts;

type
    (*!------------------------------------------------
     * TJsonFileSessionManager factory class
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TJsonFileSessionManagerFactory = class(TFactory)
    private
        fCookieName : string;
        fBaseDir : string;
        fPrefix : string;
    public
        constructor create(
            const cookieName : string = FANO_COOKIE_NAME;
            const baseDir : string = '/tmp';
            const prefix : string = ''
        );

        (*!---------------------------------------------------
         * build class instance
         *----------------------------------------------------
         * @param container dependency container instance
         *----------------------------------------------------
         * This is implementation of IDependencyFactory
         *---------------------------------------------------*)
        function build(const container : IDependencyContainer) : IDependency; override;
    end;

implementation

uses

    StringFileReaderImpl,
    JsonFileSessionManagerImpl,
    GuidSessionIdGeneratorImpl;

    constructor TJsonFileSessionManagerFactory.create(
        const cookieName : string = FANO_COOKIE_NAME;
        const baseDir : string = '/tmp';
        const prefix : string = ''
    );
    begin
        fCookieName := cookieName;
        fBaseDir := baseDir;
        fPrefix := prefix;
    end;

    (*!---------------------------------------------------
     * build class instance
     *----------------------------------------------------
     * @param container dependency container instance
     *---------------------------------------------------*)
    function TJsonFileSessionManagerFactory.build(const container : IDependencyContainer) : IDependency;
    begin
        result := TJsonFileSessionManager.create(
            TGuidSessionIdGenerator.create(),
            fCookieName,
            TStringFileReader.create(),
            fBaseDir,
            fPrefix
        );
    end;
end.
