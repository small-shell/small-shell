const cluster = require('cluster');
const numProcess = 8;
const process = require('process');
const mime = require('mime-types');
  
if (%%cluster) {
  console.log(`Primary ${process.pid} is running`);
  // Fork workers.
  for (let i = 0; i < numProcess; i++) {
    cluster.fork();
  }
  cluster.on('exit', (worker, code, signal) => {
    console.log(`worker ${worker.process.pid} died`);
  });

} else {
  
  const express = require('express');
  const app = express();
  const port = %%port;
  const body = require('body-parser');
  const url = require('url');
  const fs = require('fs');
  const www = "/var/www";
  
  const server = require('%%protocol').createServer({
      // https key: fs.readFileSync( www + '/app/privatekey.pem'),
      // https cert: fs.readFileSync( www + '/app/cert.pem'),
      // https_chain ca: fs.readFileSync( www + '/app/chain.pem')
  }, app);
  
  const execSync = require('child_process').execSync;
  // gen session 
  let random = Math.random();
  let date = new Date();
  let getTime = date.getTime() ;
  let session = getTime + random ;
  
  // handle e-cron GET request
  app.get('/cgi-bin/e-cron', (req, res)=> {

    let uri = req.originalUrl;
    let queryString = uri.split("?")[1];
    let remoteAddr = req.ip.toString();
    let proxyClientAddr = req.headers['x-real-ip'];
    if ( proxyClientAddr != undefined ) {
      remoteAddr = proxyClientAddr;
    }
    remoteAddr = remoteAddr.replace(/^::ffff:/g, "");
    let apiAuthKey = req.headers['x-small-shell-authkey'];
    let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");

    if ( queryString == undefined ) {
      res.end("Oops please set params for e-cron");
      console.log( timeStamp + remoteAddr + ' requested e-cron without any param' );

    } else {

      console.log( timeStamp + remoteAddr + ' requested ' + uri );
      if ( queryString.indexOf('req=get&filename=') != -1 ) {
        let content = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remoteAddr + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + www + "/cgi-bin/e-cron | %%sed -e 1,3d",{ maxBuffer: 1024000000 });
        // file contents with Content-Disposition
        res.set({'Content-Disposition': `attachment; filename=${req.query.filename}`})
        res.writeHead(200, {'Content-Type' : 'application/octet-stream'});
        res.end(content);
      } else {
        // handle general request 
        let content = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remoteAddr + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + www + "/cgi-bin/e-cron | %%sed -e 1,2d",{ maxBuffer: 1024000000 }).toString();
        res.writeHead(200, {'Content-Type' : 'text/html'});
        res.end(content);

      }
    }
  })
  
  
  // handle general GET request
  app.get('/cgi-bin/:name', (req, res)=> {
    let uri = req.originalUrl;
    let command = req.params.name;
    let queryString = uri.split("?")[1];
    let remoteAddr = req.ip.toString();

    let proxyClientAddr = req.headers['x-real-ip'];
    if ( proxyClientAddr != undefined ) {
      remoteAddr = proxyClientAddr;
    }

    remoteAddr = remoteAddr.replace(/^::ffff:/g, "");
    let userAgent =  req.headers['user-agent'];
    let apiAuthKey = req.headers['x-small-shell-authkey'];
  
    if ( queryString == undefined ) {
      queryString = "query=null";
    }
  
    if( fs.existsSync( www + "/cgi-bin/" + command ) ){
      if ( queryString.indexOf('req=file') != -1 ) {
        let content = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remoteAddr + "\"; export HTTP_USER_AGENT=\"" + userAgent  + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + www + "/cgi-bin/" + command + "| %%sed -e 1,3d",{ maxBuffer: 1024000000 });
        res.writeHead(200, {'Content-Type' : 'application/octet-stream'});
        res.end(content);
        let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( timeStamp + remoteAddr + ' requested ' + uri );

      } else if( queryString.indexOf('type=graph') != -1) {
        // handle graph contents
        let graph = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remoteAddr + "\"; export HTTP_USER_AGENT=\"" + userAgent  + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + www + "/cgi-bin/" + command + "| %%sed -e 1,2d" ,{ maxBuffer: 1024000000 });
        res.writeHead(200, {'Content-Type' : 'image/png'});
        res.end(graph);
        let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( timeStamp + remoteAddr + ' requested ' + uri );
  
      } else {
        // handle general request
        let html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remoteAddr + "\"; export HTTP_USER_AGENT=\"" + userAgent  + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + www + "/cgi-bin/" + command + "| %%sed -e 1,2d",{ maxBuffer: 1024000000 }).toString();
        res.writeHead(200, {'Content-Type' : 'text/html'});
        res.end(html);
        let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( timeStamp + remoteAddr + ' requested ' + uri );
      }

    } else {
      res.end("Oops wrong request");
      let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( timeStamp + remoteAddr + ' requested wrong page ' + uri );
    }
   
  })
  
  //handle data as binary
  app.use(body.raw({ 
    type:'*/*',
    limit:'1024mb'
   }));
  
  //handle general POST request include e-cron req
  app.post('/cgi-bin/:name', (req, res) => {
    let uri = req.originalUrl;
    let command = req.params.name;
    let queryString = uri.split("?")[1];
    let remoteAddr = req.ip.toString();

    let proxyClientAddr = req.headers['x-real-ip'];
    if ( proxyClientAddr != undefined ) {
      remoteAddr = proxyClientAddr;
    }

    remoteAddr = remoteAddr.replace(/^::ffff:/g, "");
    let userAgent =  req.headers['user-agent'];
    let contentType = req.headers['content-type'];
    let apiAuthKey = req.headers['x-small-shell-authkey'];
    let contentLength = Buffer.byteLength(req.body);
    let ddDump = session ;
  
    if ( queryString == undefined ) {
      queryString = "query=null";
    }
  
    if( fs.existsSync( www + "/cgi-bin/" + command ) ){
      fs.writeFileSync( www + '/tmp/' + ddDump, req.body);
      let html = execSync("export REQUEST_METHOD=POST; export CONTENT_TYPE=\"" + contentType + "\";" + "export CONTENT_LENGTH=" + contentLength + ";" +  "export REMOTE_ADDR=\"" + remoteAddr + "\"; export HTTP_USER_AGENT=\"" + userAgent  + "\"; export QUERY_STRING=\"" + queryString + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ apiAuthKey + ";" + "dd if=" + www + "/tmp/" + ddDump + " 2>/dev/null |" + www + "/cgi-bin/" + command + "| %%sed -e 1d").toString();
  
      let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( timeStamp + remoteAddr + ' requested ' + uri );
  
      if ( html.indexOf('meta http-equiv=\"refresh\"') != -1) {
        let redirectDump = session ;
        fs.writeFileSync( www + '/tmp/' + redirectDump, html);
        let redirect_url = execSync("cat " + www + "/tmp/" + redirectDump + "| grep url= | %%sed -r \"s/^(.*)url=//g\" | %%sed -r \"s/..$//g\"").toString();
        redirect_url = redirect_url.replace(/\r?\n/g, '');
        res.writeHead(302, {
       'Location': redirect_url
        });
        res.end();
      } else {
        res.writeHead(200, {'Content-Type' : 'text/html'});
        res.end(html);
      }
      fs.unlinkSync( www + "/tmp/" + session);
    } else {
      res.end("Oops wrong request");
      let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( timeStamp + remoteAddr + ' requested wrong page ' + uri );
    }
  })
  
  app.get("/favicon.ico", (req, res) => {
   res.end(); 
  });
  
  // handle static page
  app.get('%%any_routing', (req, res) => {
    let remoteAddr = req.ip.toString();
    let proxyClientAddr = req.headers['x-real-ip'];
    if ( proxyClientAddr != undefined ) {
      remoteAddr = proxyClientAddr;
    }
    remoteAddr = remoteAddr.replace(/^::ffff:/g, "");
    let uri = url.parse(req.url).pathname;
    let path = www + "/html" + uri;
  
    let indexChk = uri.match( /.*\/$/ );
    if ( indexChk != null ) {
      path = path + "index.html";
    }
  
    if( fs.existsSync( path ) ){
      fs.stat( path, function(er,stat)  {
        if ( stat.isFile() ) {
          let content = execSync("dd if=" + path + " 2>/dev/null" ,{ maxBuffer: 1024000000 });
          let mimeType = mime.lookup( path );
          res.writeHead(200, {'Content-Type' : mimeType});
          res.end(content);
          let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
          console.log( timeStamp + remoteAddr + ' requested ' + uri );
        } else {
          // handle path as directory
          if( fs.existsSync( path + "/index.html" ) ){
            let html = execSync("cat " + path + "/index.html" ,{ maxBuffer: 1024000000 });
            res.end(html);
            let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
            console.log( timeStamp + remoteAddr + ' requested ' + uri );
          } else {
            res.end("Oops wrong request");
            let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
            console.log( timeStamp + remoteAddr + ' requested wrong page ' + uri );
          }
        }
      });
  
    } else {
      res.end("Oops wrong request");
      let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( timeStamp + remoteAddr + ' requested wrong page ' + uri );
    }
  });
  
  
  server.listen(port, function(){
    process.setuid('small-shell'); 
    let timeStamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
    console.log( timeStamp + "PID " + process.pid + " small-shell web srv is started ");
  });
  
  /* forward option start
  const http = require("http");
  http.createServer((express()).all('/{*any}', function (request, response) {
      response.redirect(`https://${request.hostname}${request.url}`);
  })).listen(80);
  option end */

}
  
