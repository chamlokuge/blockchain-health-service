import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerinax/java.jdbc;
import ballerina/runtime;
import ballerina/crypto;
import wso2/utils;
import ballerina/stringutils;
import ballerina/file;

listener http:Listener uiHolderLogin = new(9091);

map<string> sessionMap = {};
map<boolean> authenticatedMap = {};
map<string> userMap = {"alice@gmail.com": "123"};
string chatBuffer = "";
string pk = "";
string verifiableCredentialsRepositoryURL = "https://localhost:9091/vc/";
string ethereumAccount = "0x470bf46455ba1fc9544ac322386b0d965e43eeae";
string ethereumAccountPass = "123";

http:Client ethereumClient = new("http://192.168.32.1:8081");

jdbc:Client ssiDB = new({
        url: "jdbc:mysql://192.168.32.1:3306/ssidb",
        username: "test",
        password: "test",
        dbOptions: { useSSL: false }
});

type HolderRecord record {
    string id;
    string issuer;
    string name;
};

type VCRecord record {
    string vctxt;
};

type FullVCRecord record {
    string id;
    string issuer;
    string name;
};

type NameRecord record {
    string name;
};

type UserKeyData record {
    string username;
    string publicKey;
};

string holderRepo = "/var/tmp/iam/holder/alice";

@http:ServiceConfig { basePath:"/",
    cors: {
        allowOrigins: ["*"], 
        allowHeaders: ["Authorization, Lang"]
    } 
}
service uiServiceHolderLogin on uiHolderLogin {

   @http:ResourceConfig {
        methods:["GET"],
        path:"/",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function displayLoginPage(http:Caller caller, http:Request req) {
       string buffer = readFile("health/index.html");
       
       http:Response res = new;

       if (caller.localAddress.host != "") {
        buffer= stringutils:replace(buffer,"localhost",caller.localAddress.host);
       }

       res.setPayload(<@untainted> buffer);
       res.setContentType("text/html; charset=utf-8");
       res.setHeader("Access-Control-Allow-Origin", "*");
       res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
       res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

       var result = caller->respond(res);
       if (result is error) {
            log:printError("Error sending response", err = result);
       }
   }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/authenticate",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function processLogin(http:Caller caller, http:Request req) returns error?{
        var requestVariableMap = check req.getFormParams();
        string username = requestVariableMap["username"]  ?: "";
        string password = requestVariableMap["pwd"]  ?: "";
        var authenticated = false;

        foreach var [k, v] in userMap.entries() {
            if (stringutils:equalsIgnoreCase(username, k) && stringutils:equalsIgnoreCase(password, v)) {
                authenticatedMap[username] = true;
                var result = caller->respond("success");
                if (result is error) {
                    log:printError("Error sending response", err = result);
                } else {
                    authenticated = true;
                }
                break;
            }
        }

        if (!authenticated) {
            var result = caller->respond("failed");
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }

        return;
   }

      @http:ResourceConfig {
        methods:["GET"],
        path:"/home/did",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function displayLoginPage2(http:Caller caller, http:Request req) returns error? {
        string username = req.getQueryParamValue("username") ?: "";
        boolean fileExists = file:exists(holderRepo + "/did.json");
        if(!fileExists) {
            if ((!(stringutils:equalsIgnoreCase(username,""))) && authenticatedMap[username] == true) {
                     var buffer = readFile("health/patient-homepage-no-did.html");
                    //var buffer = readFile("health/test.html");

                    http:Response res = new;

                    if (caller.localAddress.host != "") {
                        buffer= stringutils:replace(buffer,"localhost", caller.localAddress.host);
                        buffer= stringutils:replace(buffer,"EMPTYUNAME", username);
                    }

                    res.setPayload(<@untainted> buffer);
                    res.setContentType("text/html; charset=utf-8");
                    res.setHeader("Access-Control-Allow-Origin", "*");
                    res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                    res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

                    var result = caller->respond(res);
                    if (result is error) {
                        log:printError("Error sending response", err = result);
                    }
                } else {
                    io:println("Error login");

                    string buffer = readFile("health/error.html");
                    string hostname = "localhost";

                    if (caller.localAddress.host != "") {
                        hostname= caller.localAddress.host;
                    }
                    buffer = stringutils:replace(buffer,"MSG", "Re-try login via : <a href='http://" + caller.localAddress.host + ":9091'>Login Page</a>");


                    http:Response res = new;
                    res.setPayload(<@untainted> buffer);
                    res.setContentType("text/html; charset=utf-8");
                    res.setHeader("Access-Control-Allow-Origin", "*");
                    res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                    res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

                    var result = caller->respond(res);
                    if (result is error) {
                            log:printError("Error sending response", err = result);
                    }
                }
           } else {
                        if ((!(stringutils:equalsIgnoreCase(username,""))) && authenticatedMap[username] == true) {
                    var buffer = readFile("health/patient-homepage-with-did.html");
                    var didTxt = readFile(holderRepo + "/did.json");

                    http:Response res = new;
                    int index = (didTxt.indexOf("\"id\": \"did:ethr:") ?: 0) + 16;
                    string didmid = didTxt.substring(index, index+64);

                    if (caller.localAddress.host != "") {
                        buffer= stringutils:replace(buffer,"localhost", caller.localAddress.host);
                        buffer= stringutils:replace(buffer,"DIDTEXT", didTxt);
                        buffer= stringutils:replace(buffer,"EMPTYUNAME", username);
                        buffer = stringutils:replace(buffer,"DIDMID", didmid);
                    }

                    res.setPayload(<@untainted> buffer);
                    res.setContentType("text/html; charset=utf-8");
                    res.setHeader("Access-Control-Allow-Origin", "*");
                    res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                    res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

                    var result = caller->respond(res);
                    if (result is error) {
                            log:printError("Error sending response", err = result);
                    }
                } else {
                    io:println("Error login");

                    string buffer = readFile("health/error.html");
                    string hostname = "localhost";

                    if (caller.localAddress.host != "") {
                        hostname= caller.localAddress.host;
                    }
                     buffer = stringutils:replace(buffer,"MSG", "Re-try login via : <a href='http://" + caller.localAddress.host + ":9091'>Login Page</a>");

                    http:Response res = new;
                    res.setPayload(<@untainted> buffer);
                    res.setContentType("text/html; charset=utf-8");
                    res.setHeader("Access-Control-Allow-Origin", "*");
                    res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                    res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

                    var result = caller->respond(res);
                    if (result is error) {
                            log:printError("Error sending response", err = result);
                    }
                }
           }
   }


    @http:ResourceConfig {
        methods:["GET"],
        path:"/home/vc",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function displayLoginPage3(http:Caller caller, http:Request req) returns error? {
        string username = req.getQueryParamValue("username") ?: "";
        string did = req.getQueryParamValue("did") ?: "";

        var selectRet = ssiDB->select(<@untainted> "select id, issuer, name from ssidb.vclist where (did LIKE '"+ <@untainted> did +"');", HolderRecord);
        string tbl = "<table><tr><td>No Verifiable credentials associated with your account yet.";

        if (selectRet is table<HolderRecord>) {
            if (!selectRet.hasNext())
             {
                tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><td>No Verifiable Credentials found for this DID</td></tr></table>";
             } else {
                 tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><th>Verifiable Cerdential's DID</th><th>Name</th><th>Issuer</th></tr>";

                 while (selectRet.hasNext()) {
                         var ret = selectRet.getNext();
                         if (ret is HolderRecord) {
                            tbl = tbl + "<tr><td><a href=\"#\" onclick=\"showVC('" + ret.id.toString() + "');\">";
                            tbl = tbl + ret.id.toString();
                            tbl = tbl + "</a></td><td>";
                            tbl = tbl + ret.name;

                            tbl = tbl + "</td><td>";
                            tbl = tbl + ret.issuer;
                         } else {
                             io:println("Error in get HolderRecord from table");
                         }
                 }
                 tbl += "</td></tr></table>";
             }
        } else {
            io:println("Select data from vclist table failed");
        }

        if ((!(stringutils:equalsIgnoreCase(username,""))) && authenticatedMap[username] == true) {
            var buffer = readFile("health/patient-homepage-vc.html");
            var didTxt = "";
            boolean fileExists = file:exists(holderRepo + "/did.json");
            if(!fileExists) {
                
        	    io:println("Cannot find the DID file.");
	        } else {
                didTxt = readFile(holderRepo + "/did.json");
            }

            http:Response res = new;

            if (caller.localAddress.host != "") {
                buffer = stringutils:replace(buffer,"localhost", caller.localAddress.host);
                buffer = stringutils:replace(buffer,"EMPTYUNAME", username);

                buffer = stringutils:replace(buffer,"VCTABLE", tbl);
                buffer = stringutils:replace(buffer,"DIDMID", did);
                
                didTxt = utils:stringToBinaryString(didTxt);
                buffer = stringutils:replace(buffer,"DIDTXTVAL", didTxt);
            }

            res.setPayload(<@untainted> buffer);
            res.setContentType("text/html; charset=utf-8");
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            var result = caller->respond(res);
            if (result is error) {
                    log:printError("Error sending response", err = result);
            }
        } else {
            io:println("Error login");

            string buffer = readFile("health/error.html");
            string hostname = "localhost";

            if (caller.localAddress.host != "") {
                hostname= caller.localAddress.host;
            }

            buffer = stringutils:replace(buffer,"MSG", "Re-try login via : <a href='http://" + caller.localAddress.host + ":9091'>Login Page</a>");

            http:Response res = new;
            res.setPayload(<@untainted> buffer);
            res.setContentType("text/html; charset=utf-8");
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            var result = caller->respond(res);
            if (result is error) {
                    log:printError("Error sending response", err = result);
            }
        }
   }


    @http:ResourceConfig {
        methods:["POST"],
        path:"/vc",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function listVC(http:Caller caller, http:Request req) returns error? {
        map<string> requestVariableMap = check req.getFormParams();
        string did = requestVariableMap["did"]  ?: "";
        var selectRet = ssiDB->select(<@untainted> "select id, issuer, name from ssidb.vclist where (did LIKE '"+ <@untainted> did +"');", FullVCRecord);
        string tbl = "<table><tr><td>No Verifiable credentials associated with your account yet.";

        if (selectRet is table<FullVCRecord>) {

            if (!selectRet.hasNext()) {
                tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><td>No Verifiable Credentials found for this DID</td></tr></table>";
            } else {
                tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><th>Verifiable Cerdential's DID</th><th>Name</th><th>Issuer</th><th>&nbsp;</th></tr>";
                while (selectRet.hasNext()) {
                    var ret = selectRet.getNext();
                    if (ret is FullVCRecord) {
                        tbl = tbl + "<tr><td><a href=\"#\" onclick=\"showVC('" + ret.id.toString() + "');\">";
                        tbl = tbl + ret.id.toString();
                        tbl = tbl + "</a></td><td>";
                        tbl = tbl + ret.name;
                        tbl = tbl + "</td><td>";
                        tbl = tbl + ret.issuer;
                        tbl = tbl + "</td><td><input type=\"checkbox\" id=\"" + ret.id.toString()  + "\" name=\"vcselect\"\\>";
                    } else {
                        io:println("Error in get HolderRecord from table");
                    }
                }
                tbl += "</td></tr></table><br/><input id=\"vc-btn\" type=\"button\" value=\"Submit VC\" onclick=\"submitVC()\">";
            }
        } else {
            io:println("Select data from vclist table failed");
        }

            http:Response res = new;
            var buffer = tbl;

            res.setPayload(<@untainted> buffer);
            res.setContentType("text/html; charset=utf-8");
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            var result = caller->respond(res);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
   }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/api",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function api(http:Caller caller, http:Request req) returns error?{
        var requestVariableMap = check req.getFormParams();
        
        string publicKey = requestVariableMap["publickey"]  ?: "";
        publicKey = stringutils:replace(publicKey,"+", " ");
        publicKey = stringutils:replace(publicKey,"%2B", "+");
        publicKey = stringutils:replace(publicKey,"%2F", "/");
        publicKey = stringutils:replace(publicKey,"%3D", "=");
               
        if (requestVariableMap["command"] == "cmd1") {

            io:println(publicKey);

            UserKeyData ud= {username: "alice", publicKey: publicKey};

            json|error j = json.constructFrom(ud);
        if (j is json) {
            http:Client clientEndpoint = new("http://postman-echo.com");
            var response = clientEndpoint->post("/post", j);
            handleResponse(response,caller);
            
        }

            

            

            return;

            // string finalResult = sendTransactionAndgetHash(publicKey);

            // if (finalResult == "-1") {
            //     //If its error
            //     io:println("its is null--->"+finalResult);
            //     http:Response res = new;
            //     res.setPayload(<@untainted> "null");
            //     res.setContentType("text/html; charset=utf-8");
            //     res.setHeader("Access-Control-Allow-Origin", "*");
            //     res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            //     res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            //     var result = caller->respond(res);
            //     if (result is error) {
            //             log:printError("Error sending response", err = result);
            //     }
            // } else {
            //     io:println(finalResult);
            // finalResult = finalResult.substring(2, 66);

            // var templateDID = "{" +
            //         "\"@context\": \"https://w3id.org/did/v1\"," +
            //         "\"id\": \"did:ethr:"+ finalResult +"\"," +
            //         "\"authentication\": [{" +
            //         // used to authenticate as did:...fghi
            //         "\"id\": \"did:ethr:" + finalResult + "#keys-1\"," +
            //         "\"type\": \"RsaVerificationKey2018\"," +
            //         "\"controller\": \"did:ethr:" + finalResult + "\"," +
            //         "\"publicKeyPem\": \"" + publicKey + "\"" +
            //         "}]," +
            //         "\"service\": [{" +
            //         // used to retrieve Verifiable Credentials associated with the DID
            //         "\"type\": \"VerifiableCredentialService\"," +
            //         "\"serviceEndpoint\": \"" + verifiableCredentialsRepositoryURL + "\"" +
            //         "}]" +
            //         "}";

            //     io:println(templateDID);

            //     string path = holderRepo + "/did.json";

            //     io:WritableByteChannel wbc = check io:openWritableFile(path);

            //     io:WritableCharacterChannel wch = new(wbc, "UTF8");
            //     var wResult = wch.writeJson(templateDID);
            //     closeWc(wch);

            //     if (wResult is error) {
            //         log:printError("Error occurred while writing json: ", err = wResult);
            //     }

            //     http:Response res = new;
            //     res.setPayload(<@untainted> templateDID);
            //     res.setContentType("text/html; charset=utf-8");
            //     res.setHeader("Access-Control-Allow-Origin", "*");
            //     res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            //     res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            //     var result = caller->respond(res);
            //     if (result is error) {
            //             log:printError("Error sending response", err = result);
            //     }
            // }
        } else if (requestVariableMap["command"] == "cmd2") {
            string did = requestVariableMap["did"]  ?: "";
            string didVC = requestVariableMap["didVC"]  ?: "";
            string issuerVC = requestVariableMap["issuerVC"]  ?: "";
            string nameVC = requestVariableMap["nameVC"]  ?: "";
            string vcTxt = requestVariableMap["vcTxt"]  ?: "";
            var selectRet = ssiDB->select(<@untainted> "select name from ssidb.vclist where (did LIKE '"+ <@untainted> did +"');", NameRecord);

            string name2 = "";

            if (selectRet is table<NameRecord>) {
                if (selectRet.hasNext()) {
                    var jsonConversionRet = selectRet.getNext();
                    
                    if (jsonConversionRet is NameRecord) {
                        name2 = jsonConversionRet.name;

                        if (nameVC === name2) {
                            http:Response res = new;
                            res.setPayload(<@untainted> "vc-already-exist");
                            res.setContentType("text/html; charset=utf-8");
                            res.setHeader("Access-Control-Allow-Origin", "*");
                            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

                            var result = caller->respond(res);
                            if (result is error) {
                                    log:printError("Error sending response", err = result);
                            }

                            return;
                        }
                    }
                } else {
                    //The result is empty
                }
            }

            vcTxt = stringutils:replace(vcTxt,"'","''");
            var ret = ssiDB->update(<@untainted> ("insert into ssidb.vclist(did, id, issuer, name, vctext) " + "values ('"+ did +"', '" + didVC.substring(2, didVC.length()) + "', '" + issuerVC + "', '"+ nameVC +"', '" + vcTxt + "');"));
     
            var selectRet2 = ssiDB->select(<@untainted> "select id, issuer, name from ssidb.vclist where (did LIKE '"+ <@untainted> did +"');", HolderRecord);
                string tbl = "<table><tr><td>No Verifiable credentials associated with your account yet.";

            if (selectRet2 is table<HolderRecord>) {
                if (!selectRet2.hasNext()) {
                    tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><td>No Verifiable Credentials found for this DID</td></tr></table>";
                } else {
                    tbl = "<table border=\"1px\" cellspacing=\"0\" cellpadding=\"3\"><tr><th>Verifiable Cerdential's DID</th><th>Name</th><th>Issuer</th></tr>";

                     while (selectRet2.hasNext()) {
                             var ret2 = selectRet2.getNext();
                             if (ret2 is HolderRecord) {
                                 tbl = tbl + "<tr><td>";
                                 tbl = tbl + ret2.id;
                                 tbl = tbl + "</td><td>";
                                 tbl = tbl + ret2.name;
                                 tbl = tbl + "</td><td>";
                                 tbl = tbl + ret2.issuer;
                             } else {
                                 io:println("Error in get HolderRecord from table");
                             }
                     }
                     tbl += "</td></tr></table>";
                }
            } else {
                io:println("Select data from vclist table failed");
            }

            http:Response res = new;
            res.setPayload(<@untainted> tbl);
            res.setContentType("text/html; charset=utf-8");
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            var result = caller->respond(res);
            if (result is error) {
                    log:printError("Error sending response", err = result);
            }
        } else if (requestVariableMap["command"] == "cmd3") {
            string id = requestVariableMap["id"]  ?: "";
            var selectRet = ssiDB->select(<@untainted> "select vctext from ssidb.vclist where (id LIKE '"+ <@untainted> id +"');", VCRecord);
            
            string vcText = "no-vc-for-this-did";

            if (selectRet is table<VCRecord>) {
                if (selectRet.hasNext()) {
                     var ret2 = selectRet.getNext();
                     if (ret2 is VCRecord) {
                         vcText = ret2.vctxt;
                     }
                } else {
                    //The result is empty
                }
            }

            http:Response res = new;
            res.setPayload(<@untainted> vcText);
            res.setContentType("text/html; charset=utf-8");
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

            var result = caller->respond(res);
            if (result is error) {
                    log:printError("Error sending response", err = result);
            }

        }
   }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/logout",
        cors: {
            allowOrigins: ["*"],
            allowHeaders: ["Authorization, Lang"]
        }
    }
   resource function logout(http:Caller caller, http:Request req) {
       string username = req.getQueryParamValue("username") ?: "";

       if ((!(stringutils:equalsIgnoreCase(username,""))) && authenticatedMap[username] == true) {
           authenticatedMap[username] = false;
       }

       string buffer = readFile("health/index.html");
       
       http:Response res = new;

       if (caller.localAddress.host != "") {
         buffer= stringutils:replace(buffer,"localhost", caller.localAddress.host);
       }

       res.setPayload(<@untainted> buffer);
       res.setContentType("text/html; charset=utf-8");
       res.setHeader("Access-Control-Allow-Origin", "*");
       res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
       res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");

       var result = caller->redirect(res,  http:REDIRECT_TEMPORARY_REDIRECT_307,
            ["http://localhost:9091/"]);
       if (result is error) {
            log:printError("Error sending response", err = result);
       }
   }
 }

string ping = "ping";
byte[] pingData = ping.toBytes();

@http:WebSocketServiceConfig {
    path: "/basic/ws",
    subProtocols: ["xml", "json"],
    idleTimeoutInSeconds: 120
}

service basic on new http:Listener(9093) {

    resource function onOpen(http:WebSocketCaller caller) {
        io:println("\nNew client connected");
        io:println("Connection ID: " + caller.getConnectionId());
        io:println("Negotiated Sub protocol: " + caller.getNegotiatedSubProtocol().toString());
        io:println("Is connection open: " + caller.isOpen().toString());
        io:println("Is connection secured: " + caller.isSecure().toString());

        while(true) {
            var err = caller->pushText(pk);
            if (err is error) {
                log:printError("Error occurred when sending text", err = err);
            }
            runtime:sleep(1000);
        }
    }

    resource function onText(http:WebSocketCaller caller, string text,
                                boolean finalFrame) {
        io:println("\ntext message: " + text + " & final fragment: "
                                                        + finalFrame.toString());

        if (text == "ping") {
            io:println("Pinging...");
            var err = caller->ping(pingData);
            if (err is http:WebSocketError) {
                log:printError("Error sending ping", <error> err);
            }
        } else if (text == "closeMe") {
            error? result = caller->close(statusCode = 1001,
                            reason = "You asked me to close the connection",
                            timeoutInSeconds = 0);
            if (result is http:WebSocketError) {
                log:printError("Error occurred when closing connection", <error> result);
            }
        } else {
            var err = caller->pushText("You said: " + text);
            if (err is http:WebSocketError) {
                log:printError("Error occurred when sending text", <error> err);
            }
        }
    }

    resource function onBinary(http:WebSocketCaller caller, byte[] b) {
        io:println("\nNew binary message received");
        io:print("UTF-8 decoded binary message: ");
        io:println(b);
        var err = caller->pushBinary(b);
        if (err is http:WebSocketError) {
            log:printError("Error occurred when sending binary", <error> err);
        }
    }

    resource function onPing(http:WebSocketCaller caller, byte[] data) {
        var err = caller->pong(data);
        if (err is http:WebSocketError) {
            log:printError("Error occurred when closing the connection",
                            <error> err);
        }
    }

    resource function onPong(http:WebSocketCaller caller, byte[] data) {
        io:println("Pong received");
    }

    resource function onIdleTimeout(http:WebSocketCaller caller) {
        io:println("\nReached idle timeout");
        io:println("Closing connection " + caller.getConnectionId());
        var err = caller->close(statusCode = 1001, reason =
                                    "Connection timeout");
        if (err is http:WebSocketError) {
            log:printError("Error occurred when closing the connection", <error> err);
        }
    }

    resource function onError(http:WebSocketCaller caller, error err) {
        log:printError("Error occurred ", err);
    }

    resource function onClose(http:WebSocketCaller caller, int statusCode,
                                string reason) {
        io:println(string `Client left with ${statusCode} because
                    ${reason}`);
    }
}

function closeWc(io:WritableCharacterChannel wc) {
    var result = wc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream",
                        err = result);
    }
}

public function readFile(string filePath) returns string {
    string buffer = "";
    io:ReadableByteChannel | io:Error readableByteChannel = io:openReadableFile(filePath);
    if (readableByteChannel is io:ReadableByteChannel) {

        io:ReadableCharacterChannel | io:Error readableCharChannel = new io:ReadableCharacterChannel(readableByteChannel, "UTF-8");

        if (readableCharChannel is io:ReadableCharacterChannel) {
            var readableRecordsChannel = new io:ReadableTextRecordChannel(readableCharChannel, fs = ",,,", rs = "\n");
            while (readableRecordsChannel.hasNext()) {
                var result = readableRecordsChannel.getNext();
                if (result is string[]) {
                    foreach var v in result {
                        string item = <@untainted>v.toString();
                        buffer += item;
                    }
                } else {
                    io:println("Error");
                }
            }
        }
    }
    return buffer;
}

public function sendTransactionAndgetHash(string data) returns (string) {
    string finalResult2 = "";
    boolean errorFlag2 = false;
    var httpResponse2 = ethereumClient -> post("/", constructRequest("2.0", 2000, "personal_unlockAccount", [ethereumAccount, ethereumAccountPass, null]));

    if (httpResponse2 is http:Response) {
        int statusCode = httpResponse2.statusCode;
        string|error s = httpResponse2.getTextPayload();
        var jsonResponse = httpResponse2.getJsonPayload();

        if (jsonResponse is map<json>) {
            if (jsonResponse["error"] == null) {
                finalResult2 = jsonResponse.result.toString();
            } else {
                    error err = error("(wso2/ethereum)EthereumError",
                                        message="Error occurred while accessing the JSON payload of the response");
                    finalResult2 = jsonResponse["error"].toString();
                    errorFlag2 = true;
            }
        } else {
            error err = error("(wso2/ethereum)EthereumError", message="Error occurred while accessing the JSON payload of the response");
                finalResult2 = "Error occurred while accessing the JSON payload of the response";
                errorFlag2 = true;
            }
    } else {
        error err = error("(wso2/ethereum)EthereumError", message="Error occurred while invoking the Ethererum API");
        errorFlag2 = true;
    }

    string hexEncodedString = "0x" + utils:hashSHA256(data);//encoding:encodeHex(output);

    byte[] hexEncodedString2 =  crypto:hashSha256(data.toBytes());

    string finalResult = "";
    boolean errorFlag = false;

    var httpResponse = ethereumClient -> post("/", constructRequest("2.0", 2000, "eth_sendTransaction", [ {"from": ethereumAccount,  "data": hexEncodedString }]));

    if (httpResponse is http:Response) {
        int statusCode = httpResponse.statusCode;
        var jsonResponse = httpResponse.getJsonPayload();
        if (jsonResponse is map<json>) {
            if (jsonResponse["error"] == null) {
                finalResult = jsonResponse.result.toString();
            } else {
                    error err = error("(wso2/ethereum)EthereumError", message="Error occurred while accessing the JSON payload of the response");
                    finalResult = jsonResponse["error"].toString();
                    errorFlag = true;
            }
        } else {
            error err = error("(wso2/ethereum)EthereumError", message="Error occurred while accessing the JSON payload of the response");
            finalResult = "Error occurred while accessing the JSON payload of the response";
            errorFlag = true;
        }
    } else {
        error err = error("(wso2/ethereum)EthereumError", message="Error occurred while invoking the Ethererum API");
        errorFlag = true;
    }

    return finalResult;
}

function constructRequest(string jsonRPCVersion, int networkId, string method, json pars) returns http:Request {
    http:Request request = new;
    request.setHeader("Content-Type", "application/json");
    json payload = {};
    if (pars == "[]") {
        payload = {
            jsonrpc: jsonRPCVersion, 
            method: method, 
            params: [], 
            id: networkId
        };
    } else {
        payload = {
            jsonrpc: jsonRPCVersion, 
            method: method, 
            params: pars,
            id: networkId
        };
    }

    request.setJsonPayload(payload);
    return request;
}

function handleResponse(http:Response|error response, http:Caller caller) {
    if (response is http:Response) {

        

        http:Response res = new;
        res.setPayload(<@untainted> "success");
        res.setContentType("text/html; charset=utf-8");
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
        res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");
        var result = caller->respond(res);
        if (result is error) {
                log:printError("Error sending response", err = result);
        }

        
    } else {
        io:println("Error when calling the backend: ", response.reason());

        http:Response res = new;
                            
                            res.setPayload(<@untainted> "fail");
                            res.statusCode=400;
                            res.setContentType("text/html; charset=utf-8");
                            res.setHeader("Access-Control-Allow-Origin", "*");
                            res.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
                            res.setHeader("Access-Control-Allow-Headers", "Authorization, Lang");
                            

                            var result = caller->respond(res);
                            if (result is error) {
                                    log:printError("Error sending response", err = result);
                            }
    }
}