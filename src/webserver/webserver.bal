import ballerina/config;
import ballerina/file;
import ballerina/filepath;
import ballerina/http;
import ballerina/lang.'string as lstring;
import ballerina/log;
import ballerina/mime;
import ballerina/system;

//// Configuration related properties.
string WEBSERVER_APP_FOLDER = config:getAsString("WEBSERVER_APP_FOLDER", checkpanic filepath:build(system:getUserHome(), "git", "blockchain-iam-group-chat/web"));
listener http:Listener webServerEP = new(config:getAsInt("WEBSERVER_SERVICE_PORT", 8080), config = {
});

// file extension mapping to content types
final map<string> MIME_MAP = {
    "json": mime:APPLICATION_JSON,
    "xml": mime:TEXT_XML,
    balo: mime:APPLICATION_OCTET_STREAM,
    css: "text/css",
    gif: "image/gif",
    html: mime:TEXT_HTML,
    ico: "image/x-icon",
    jpeg: "image/jpeg",
    jpg: "image/jpeg",
    js: "application/javascript",
    png: "image/png",
    svg: "image/svg+xml",
    txt: mime:TEXT_PLAIN,
    woff2: "font/woff2",
    zip: "application/zip"
};

@http:ServiceConfig {
    basePath: "/",
    chunking: http:CHUNKING_NEVER
}
service webServerSvc on webServerEP {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/*"
    }
    resource function serveHtmlFiles(http:Caller caller, http:Request request) {
        http:Response res = new;
        string requestedFilePath = <@untainted> request.extraPathInfo;
        // if no path mentioned, then use index.html
        if ("" == filepath:extension(requestedFilePath)) {
            requestedFilePath = "/index.html"; // resolve to index.html if not file it found.
        }

        res = getFileAsResponse(checkpanic filepath:build(WEBSERVER_APP_FOLDER, requestedFilePath));

        error? clientResponse = caller->respond(res);
        if (clientResponse is error) {
            log:printError("unable respond back", err = clientResponse);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/static/*"
    }
    resource function serveStaticFiles(http:Caller caller, http:Request request) {
        // TODO: properly untaint the request.rawPath
        string|error requestedFilePath = filepath:build(WEBSERVER_APP_FOLDER, <@untainted> request.rawPath);
        http:Response res = new;
        if (requestedFilePath is string) {
            res = getFileAsResponse(requestedFilePath);
        } else {
            res.setTextPayload("server error occurred.");
            res.statusCode = 500;
            log:printError("unable to resolve file path", err = requestedFilePath);
        }

        error? clientResponse = caller->respond(res);
        if (clientResponse is error) {
            log:printError("unable respond back", err = clientResponse);
        }
    }
}

# Serve a file as a http response.
#
# + requestedFile - The path of the file to server.
# + return - The http response.
function getFileAsResponse(string requestedFile) returns (http:Response) {
    http:Response res = new;
    string contentType = mime:APPLICATION_OCTET_STREAM;

    string fileExtension = checkpanic filepath:extension(requestedFile);
    if (fileExtension != "") {
        contentType = getMimeTypeByExtension(fileExtension);
    }

    if (file:exists(requestedFile)) {
        res.setFileAsPayload(requestedFile, contentType = contentType);
    } else {
        log:printError("unable to find file: " + requestedFile);
        res.setTextPayload("the server was not able to find what you were looking for.");
        res.statusCode = http:STATUS_NOT_FOUND;
    }
    return res;
}

# Get the content type using a file extension.
#
# + extension - The file extension.
# + return - The content type if a match is found, else application/octet-stream.
function getMimeTypeByExtension(string extension) returns (string) {
    var contentType = MIME_MAP[lstring:toLowerAscii(extension)];
    if (contentType is string) {
        return contentType;
    } else {
        return mime:APPLICATION_OCTET_STREAM;
    }
}