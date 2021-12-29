import * as vscode from 'vscode';

const LANGUAGE_ID: string = 'ebnf';

interface TMToken {
    range: vscode.Range;
    text: string;
    scopes: string[];
}

interface SimpleToken {
    text: string;
    range: vscode.Range;
}

interface DocumentTokens {
    definedTokens: SimpleToken[];
    consumedTokens: SimpleToken[];
}

export function activate(context: vscode.ExtensionContext) {
    const collection = vscode.languages.createDiagnosticCollection(LANGUAGE_ID);

    if (vscode.window.activeTextEditor) {
        updateDiagnostics(vscode.window.activeTextEditor.document, collection);
    }

    context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor(editor => {
        if (editor) {
            updateDiagnostics(editor.document, collection);
        }
    }));

    context.subscriptions.push(vscode.workspace.onDidChangeTextDocument(event => {
        if (event.document) {
            updateDiagnostics(event.document, collection);
        }
    }));
}

function parse(document: vscode.TextDocument, hs: vscode.Extension<any> | undefined): DocumentTokens {
    let defined: SimpleToken[] = [];
    let consumed: SimpleToken[] = [];

    for (let currentPosition: vscode.Position = new vscode.Position(0, 0);
        currentPosition.line < document.lineCount;) {

        if (document.lineAt(currentPosition.line).isEmptyOrWhitespace) {
            currentPosition = new vscode.Position(currentPosition.line + 1, 0);
            continue;
        }

        const token: TMToken = hs!.exports.getScopeAt(document, currentPosition);

        if (!token) {
            break;
        }

        if (token.range.end.isAfterOrEqual(document.lineAt(token.range.end.line).range.end)) {
            currentPosition = new vscode.Position(token.range.end.line + 1, 0);
        }
        else {
            currentPosition = token.range.end.translate(0, 1);
        }

        if (token.scopes.includes('entity.name.declaration.ebnf')) {
            defined.push({
                text: token.text,
                range: token.range
            });
        }

        if (token.scopes.includes('entity.name.ebnf')) {
            consumed.push({
                text: token.text,
                range: token.range
            });
        }
    }
    return {
        consumedTokens: consumed,
        definedTokens: defined
    };

}

function updateDiagnostics(document: vscode.TextDocument, collection: vscode.DiagnosticCollection): void {
    console.log('updateDiagnostics: [->]');
    const hs = vscode.extensions.getExtension('draivin.hscopes');
    hs?.activate();
    
    if (!hs?.isActive) {
        return;
    }

    if (document.languageId !== LANGUAGE_ID) {
        return;
    }

    let documentDiagnostics: vscode.Diagnostic[] = [];

    const parsedTokens: DocumentTokens = parse(document, hs);

    for (let index: number = 1; index < parsedTokens.definedTokens.length; ++index) {
        const token = parsedTokens.definedTokens[index];
        const previousDefinition: SimpleToken | undefined = parsedTokens.definedTokens.slice(0, index - 1).find(i => i.text === token.text);
        if (previousDefinition) {
            documentDiagnostics.push({
                message: 'Token redefinition: '.concat(token.text),
                severity: vscode.DiagnosticSeverity.Error,
                range: token.range,
                relatedInformation: [
                    new vscode.DiagnosticRelatedInformation(new vscode.Location(document.uri, previousDefinition.range), 'previously defined here')
                ]
            });
        }
    }

    parsedTokens.consumedTokens.forEach(token => {
        const definition: SimpleToken | undefined = parsedTokens.definedTokens.find(i => i.text === token.text);
        if (!definition) {
            documentDiagnostics.push({
                message: 'Token undefined: '.concat(token.text),
                severity: vscode.DiagnosticSeverity.Warning,
                range: token.range
            });
        }
    });

    collection.set(document.uri, documentDiagnostics);
    console.log('updateDiagnostics: [<-]');
}

export function deactivate() { }
