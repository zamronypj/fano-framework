{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit CompositeViewParametersImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    classes,
    contnrs,
    DependencyIntf,
    ViewParametersIntf;

type

    (*!------------------------------------------------
     * class having capability to combine
     * two view parameters as one
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-------------------------------------------------*)
    TCompositeViewParameters = class(TInterfacedObject, IViewParameters, IDependency)
    private
        firstViewParam : IViewParameters;
        secondViewParam : IViewParameters;
        keys : TStrings;
    public
        constructor create(
            const firstParam : IViewParameters;
            const secondParam : IViewParameters
        );
        destructor destroy(); override;

        (*!------------------------------------------------
         * get all registered variable name as array of string
         *-----------------------------------------------
         * @return instance of TStrings
         *-----------------------------------------------
         * Note: caller MUST not modify or destroy TStrings
         * instance and should read only
         *-----------------------------------------------*)
        function vars() : TStrings;

        (*!------------------------------------------------
         * get variable value by name
         *-----------------------------------------------
         * @param varName name of variable
         * @return value of variable
         *-----------------------------------------------*)
        function getVar(const varName : shortstring) : string;

        (*!------------------------------------------------
         * set variable value by name
         *-----------------------------------------------
         * @param varName name of variable
         * @param valueData value to be store
         * @return current class instance
         *-----------------------------------------------*)
        function setVar(const varName : shortstring; const valueData :string) : IViewParameters;
    end;

implementation

uses

    EKeyNotFoundImpl;

    constructor TCompositeViewParameters.create(
        const firstParam : IViewParameters;
        const secondParam : IViewParameters
    );
    begin
        firstViewParam := firstParam;
        secondViewParam := secondParam;
        keys := TStringList.create();
    end;

    destructor TCompositeViewParameters.destroy();
    begin
        inherited destroy();
        firstViewParam := nil;
        secondViewParam := nil;
        keys.free();
    end;

    (*!------------------------------------------------
     * get all registered variable name as array of string
     *-----------------------------------------------
     * @return instance of TStrings
     *-----------------------------------------------
     * Note: caller MUST not modify or destroy TStrings
     * instance and should read only
     *-----------------------------------------------*)
    function TCompositeViewParameters.vars() : TStrings;
    var firstKeys, secondKeys : TStrings;
        indx, firstCount, secondCount : integer;
    begin
        firstKeys := firstViewParam.vars();
        secondKeys := secondViewParam.vars();
        firstCount := firstKeys.count;
        secondCount := secondKeys.count;
        keys.clear();
        keys.capacity := firstCount + secondCount;
        for indx := 0 to firstCount-1 do
        begin
            keys.add(firstKeys[i]);
        end;

        for indx := 0 to secondCount-1 do
        begin
            keys.add(secondKeys[i]);
        end;
        result := keys;
    end;

    (*!------------------------------------------------
     * get variable value by name
     *-----------------------------------------------
     * @param varName name of variable
     * @return value of variable
     *-----------------------------------------------*)
    function TCompositeViewParameters.getVar(const varName : shortstring) : string;
    begin
        try
            result := firstViewParam.getVar(varName);
        except
            on e : EKeyNotFound do
            begin
                //not found on firstViewParam, try with secondViewParam
                result := secondViewParam.getVar(varName);
            end;
        end;
    end;

    (*!------------------------------------------------
     * set variable value by name
     *-----------------------------------------------
     * @param varName name of variable
     * @param valueData value to be store
     * @return current class instance
     *-----------------------------------------------*)
    function TCompositeViewParameters.setVar(
        const varName : shortstring;
        const valueData :string
    ) : IViewParameters;
    begin
        firstViewParam.setVar(varName, valueData);
        secondViewParam.setVar(varName, valueData);
        result := self;
    end;
end.
