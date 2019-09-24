{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit SessionFactoryIntf;

interface

{$MODE OBJFPC}
{$H+}

uses

    SessionIntf;

type

    (*!------------------------------------------------
     * interface for any class having capability to
     * create session object
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    ISessionFactory = interface
        ['{CA38E991-6A66-4BE5-89DF-540885088F76}']

        function createSession(
            const sessName : shortstring;
            const sessId : shortstring;
            const sessData : string
        ) : ISession;
    end;

implementation
end.
