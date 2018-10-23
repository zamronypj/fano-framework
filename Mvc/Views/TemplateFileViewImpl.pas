{*!
 * Fano Web Framework (https://fano.juhara.id)
 *
 * @link      https://github.com/zamronypj/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/fano/blob/master/LICENSE (GPL 2.0)
 *}

unit TemplateFileViewImpl;

interface

{$H+}

uses
    ResponseIntf,
    ViewParametersIntf,
    ViewIntf,
    OutputBufferIntf,
    TemplateViewImpl,
    TemplateParserIntf;

type
    {------------------------------------------------
     View that can render from a HTML template file
     @author Zamrony P. Juhara <zamronypj@yahoo.com>
    -----------------------------------------------}
    TTemplateFileView = class(TTemplateView)
    public
        constructor create(
            const outputBufferInst : IOutputBuffer;
            const templateParserInst : ITemplateParser;
            const templatePath : string
        ); override;
    end;

implementation

    constructor TTemplateFileView.create(
        const outputBufferInst : IOutputBuffer;
        const templateParserInst : ITemplateParser;
        const templatePath : string
    );
    begin
        inherited create(
            outputBufferInst,
            templateParserInst,
            readFileToString(templatePath)
        );
    end;

end.
