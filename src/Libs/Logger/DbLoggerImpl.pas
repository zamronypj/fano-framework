{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit DbLoggerImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    SerializeableIntf,
    LoggerIntf,
    RdbmsIntf,
    AbstractLoggerImpl;

type

    (*!------------------------------------------------
     * logger class that log to RDBMS
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    TDbLogger = class(TAbstractLogger)
    private
        fRdbms : IRdbms;
        fTableName : string;
        fLevelField : string;
        fMsgField : string;
        fCreatedAtField : string;
        fContextField : string;
    public
        constructor create(
            const rdbms : IRdbms;
            const tableName : string;
            const levelField : string;
            const msgField : string;
            const createdAtField : string;
            const contextField : string
        );

        destructor destroy(); override;

        (*!--------------------------------------
         * log message
         * --------------------------------------
         * @param level type of log
         * @param msg log message
         * @param context data related to log message
         *               (if any)
         * @return current instance
         *---------------------------------------*)
        function log(
            const level : string;
            const msg : string;
            const context : ISerializeable = nil
        ) : ILogger; override;
    end;

implementation

uses

    sysutils,
    RdbmsStatementIntf;

    constructor TDbLogger.create(
        const rdbms : IRdbms;
        const tableName : string = DEFAULT_TABLE_NAME;
        const levelField : string = DEFAULT_LEVEL_COLUMN_NAME;
        const msgField : string = DEFAULT_MSG_COLUMN_NAME;
        const createdAtField : string = DEFAULT_CREATED_AT_COLUMN_NAME;
        const contextField : string  = DEFAULT_CONTEXT_COLUMN_NAME
    );
    begin
        fRdbms := rdbms;
        fTableName := tableName;
        fLevelField := levelField;
        fMsgField := msgField;
        fCreatedAtField := createdAtField;
        fContextField := contextField;
    end;

    destructor TDbLogger.destroy();
    begin
        fRdbms := nil;
        inherited destroy();
    end;

    (*!--------------------------------------
     * log message
     * --------------------------------------
     * @param level type of log
     * @param msg log message
     * @param context data related to log message
     *               (if any)
     * @return current instance
     *---------------------------------------*)
    function TDbLogger.log(
        const level : string;
        const msg : string;
        const context : ISerializeable = nil
    ) : ILogger;
    var statement : IRdbmsStatement;
    begin
        statement := fRdbms.prepare(
            'INSERT INTO ' + fTableName +
            ' (' +
                '`' + fLevelField + '`,' +
                '`' + fMsgField + '`,' +
                '`' + fCreatedAtField + '`,' +
                '`' +fContextField + '`' +
            ') VALUES (:level, :msg, :createdAt, :context)'
        );
        statement.paramStr('level', level)
            .paramStr('msg', msg)
            .paramStr('createdAt', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now))
            .paramStr('context', context.serialize())
            .execute();
        result := self;
    end;

end.
