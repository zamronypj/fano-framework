{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 - 2020 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit JwtTokenImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    ListIntf,
    TokenVerifierIntf,
    JwtAlgIntf,
    InjectableObjectImpl;

type

    TAlg = record
        alg : shortString;
        inst : IJwtAlg;
    end;
    PAlg = ^TAlg;

    (*!------------------------------------------------
     * class having capability to verify JWT token validity
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-------------------------------------------------*)
    TJwtToken = class (TInjectableObject, ITokenVerifier)
    private
        fIssuer : string;
        fSecretKey : string;
        fAlgorithms : IList;
        procedure cleanUpAlgo();
    public
        constructor create(
            const algorithms : IList;
            const issuer : string;
            const secretKey : string;
            const algos: array of TAlg
        );
        destructor destroy(); override;

        (*!------------------------------------------------
         * verify token
         *-------------------------------------------------
         * @param token token to verify
         * @return boolean true if token is verified
         *-------------------------------------------------*)
        function verify(const token : string) : boolean;

    end;

implementation

uses

    sysutils,
    dateutils,
    fpjson,
    fpjwt;

    constructor TJwtToken.create(
        const algorithms : IList;
        const issuer : string;
        const secretKey : string;
        const algos: array of TAlg
    );
    var i : integer;
        alg : PAlg;
    begin
        fSecretKey := secretKey;
        fAlgorithms := algorithms;
        for i := low(algos) to high(algos) do
        begin
            new(alg);
            alg^.alg := algos[i].alg;
            alg^.inst := algos[i].inst;
            fAlgorithms.add(alg^.alg, alg);
        end;
    end;

    destructor TJwtToken.destroy();
    begin
        cleanUpAlgo();
        fAlgorithms := nil;
        inherited destroy();
    end;

    procedure TJwtToken.cleanUpAlgo();
    var i : integer;
        alg : PAlg;
    begin
        for i := fAlgorithms.count-1 downto 0 do
        begin
            alg := fAlgorithms.get(i);
            alg^.inst := nil;
            dispose(alg);
            fAlgorithms.delete(i);
        end;
    end;

    (*!------------------------------------------------
     * verify token
     *-------------------------------------------------
     * @param token token to verify
     * @return boolean true if token is verified,
     *         not expired and issuer match
     *-------------------------------------------------*)
    function TJwtToken.verify(const token : string) : boolean;
    var jwt : TJwt;
        alg : PAlg;
    begin
        jwt := TJwt.create();
        try
            try
                //this may raise EJSON when token is not well-formed JWT
                jwt.asEncodedString := token;

                //if we get here, token is well-formed JWT
                alg := fAlgorithms.find(jwt.JOSE.alg);

                //test if signing algorithm is known, if not, then token is
                //definitely not generated by us or token has been tampered.
                result := (alg <> nil) and

                    //if algorithm is known, check signature
                    alg^.alg.verify(
                        jwt.JOSE.AsEncodedString + '.' + jwt.Claims.AsEncodedString,
                        jwt.Signature,
                        fSecretKey
                    ) and

                    //if signature valid, check if expired
                    (jwt.Claims.exp > DateTimeToUnix(Now)) and

                    //if not expired, check if issuer match
                    (jwt.Claims.iss = fIssuer);
            except
                on e : EJSON do
                begin
                    //if we get here, token is not valid JWT
                    result := false;
                end;
            end;
        finally
            jwt.free();
        end;
    end;

end.
