const cluster = require('node:cluster');
const numProcess = 8;
const process = require('node:process');
  
if (cluster.isPrimary) {
  console.log(`Primary ${process.pid} is running`);
  // Fork workers.
  for (let i = 0; i < numProcess; i++) {
    cluster.fork();
  }
  cluster.on('exit', (worker, code, signal) => {
    console.log(`worker ${worker.process.pid} died`);
  });

} else {
  
  var express = require('express');
  var app = express();
  var port = %%port;
  var body = require('body-parser');
  var url = require('url');
  var fs = require('fs');
  var path = require('path');
  var www = "/var/www"
  
  const server = require('%%protocol').createServer({
      // https key: fs.readFileSync( www + '/app/privatekey.pem'),
      // https cert: fs.readFileSync( www + '/app/cert.pem'),
      // https_chain ca: fs.readFileSync( www + '/app/chain.pem')
  }, app)
  
  const execSync = require('child_process').execSync;
  // gen session 
  var random = Math.random();
  var date = new Date();
  var session = date.getTime() ;
  var session = session + random ;
  
  // handle e-cron GET request
  app.get('/cgi-bin/e-cron', (req, res)=> {
    var uri = url.parse(req.url).pathname;
    var req_path = url.parse(req.url).path;
    var params = req_path.split("/")[2];
    var remote_addr = req.ip.toString();
    var remote_addr = remote_addr.replace(/^::ffff:/g, "");
    var api_auth_key = req.headers['x-small-shell-authkey'];
  
    if (params) {
      var command = params.split("?")[0];
      var query_string = params.split("?")[1];
    }
  
    var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
    console.log( time_stamp + remote_addr + ' requested ' + params );
  
    if ( query_string.indexOf('req=get&filename=') != -1) {
      var html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remote_addr + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + www + "/cgi-bin/e-cron | %%sed -e 1,3d",{ maxBuffer: 1024000000 });
      // file contents with Content-Disposition
      res.set({'Content-Disposition': `attachment; filename=${req.query.filename}`})
      res.writeHead(200, {'Content-Type' : 'application/octet-stream'});
      res.end(html);
    } else {
      // handle general request 
      var html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remote_addr + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + www + "/cgi-bin/e-cron | %%sed -e 1,2d",{ maxBuffer: 1024000000 }).toString();
      res.writeHead(200, {'Content-Type' : 'text/html'});
      res.end(html);
    }
  })
  
  
  // handle general GET request
  app.get('/cgi-bin/*', (req, res)=> {
    var uri = url.parse(req.url).pathname;
    var req_path = url.parse(req.url).path;
    var params = req_path.split("/")[2];
    var remote_addr = req.ip.toString();
    var remote_addr = remote_addr.replace(/^::ffff:/g, "");
    var user_agent =  req.headers['user-agent'];
    var api_auth_key = req.headers['x-small-shell-authkey'];
  
    if (params) {
      var command = params.split("?")[0];
      var query_string = params.split("?")[1];
    }
  
    if ( query_string == undefined ) {
      query_string = "query=null";
    }
  
    if( fs.existsSync( www + "/cgi-bin/" + command ) ){
      if ( query_string.indexOf('req=file') != -1) {
        var html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remote_addr + "\"; export HTTP_USER_AGENT=\"" + user_agent  + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + www + "/cgi-bin/" + command + "| %%sed -e 1,3d",{ maxBuffer: 1024000000 });
        res.writeHead(200, {'Content-Type' : 'application/octet-stream'});
        res.end(html);
        var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( time_stamp + remote_addr + ' requested ' + params );
  
      } else if( query_string.indexOf('type=graph') != -1) {
        // handle graph contents
        var html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remote_addr + "\"; export HTTP_USER_AGENT=\"" + user_agent  + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + www + "/cgi-bin/" + command + "| /usr/bin/sed -e 1,2d" ,{ maxBuffer: 1024000000 });
        res.writeHead(200, {'Content-Type' : 'image/png'});
        res.end(html);
        var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( time_stamp + remote_addr + ' requested ' + params );
  
      } else {
        // normal contents
        var html = execSync("export REQUEST_METHOD=GET; export REMOTE_ADDR=\"" + remote_addr + "\"; export HTTP_USER_AGENT=\"" + user_agent  + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + www + "/cgi-bin/" + command + "| %%sed -e 1,2d",{ maxBuffer: 1024000000 }).toString();
        res.writeHead(200, {'Content-Type' : 'text/html'});
        res.end(html);
        var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
        console.log( time_stamp + remote_addr + ' requested ' + params );
      }
    } else {
      res.end("Oops wrong request");
      var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( time_stamp + remote_addr + ' requested wrong page ' + uri );
    }
   
  })
  
  //handle data as binary
  app.use(body.raw({ 
    type:'*/*',
    limit:'1024mb'
   }));
  
  //handle general POST request include e-cron req
  app.post('/cgi-bin/*', (req, res) => {
    var uri = url.parse(req.url).pathname;
    var req_path = url.parse(req.url).path;
    var params = req_path.split("/")[2];
    var remote_addr = req.ip.toString();
    var remote_addr = remote_addr.replace(/^::ffff:/g, "");
    var user_agent =  req.headers['user-agent'];
    var content_type = req.headers['content-type'];
    var api_auth_key = req.headers['x-small-shell-authkey'];
    var content_length = Buffer.byteLength(req.body);
    var dd_dump = session ;
  
    if (params) {
      var command = params.split("?")[0];
      var query_string = params.split("?")[1];
    }
  
    if ( query_string == undefined ) {
      query_string = "query=null";
    }
  
    if( fs.existsSync( www + "/cgi-bin/" + command ) ){
      fs.writeFileSync( www + '/tmp/' + dd_dump, req.body);
      var html = execSync("export REQUEST_METHOD=POST; export CONTENT_TYPE=\"" + content_type + "\";" + "export CONTENT_LENGTH=" + content_length + ";" +  "export REMOTE_ADDR=\"" + remote_addr + "\"; export HTTP_USER_AGENT=\"" + user_agent  + "\"; export QUERY_STRING=\"" + query_string + "\";" + "export HTTP_X_SMALL_SHELL_AUTHKEY="+ api_auth_key + ";" + "dd if=" + www + "/tmp/" + dd_dump + " 2>/dev/null |" + www + "/cgi-bin/" + command + "| %%sed -e 1d").toString();
  
      var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( time_stamp + remote_addr + ' requested ' + params );
  
      if ( html.indexOf('meta http-equiv=\"refresh\"') != -1) {
        var redirect_dump = session ;
        fs.writeFileSync( www + '/tmp/' + redirect_dump, html);
        var redirect_url = execSync("cat " + www + "/tmp/" + redirect_dump + "| grep url= | %%sed -r \"s/^(.*)url=//g\" | %%sed -r \"s/..$//g\"").toString();
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
      var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( time_stamp + remote_addr + ' requested wrong page ' + uri );
    }
  })
  
  app.get("/favicon.ico", (req, res) => {
   res.end(); 
  });
  
  // handle static page
  app.get("*", (req, res) => {
    var remote_addr = req.ip.toString();
    var remote_addr = remote_addr.replace(/^::ffff:/g, "");
    var uri = url.parse(req.url).pathname;
    var path = www + "/html" + uri;
  
    var index_chk = uri.match( /.*\/$/ );
    if ( index_chk != null ) {
      var path = path + "index.html";
    }
  
    if( fs.existsSync( path ) ){
      fs.stat( path, function(er,stat)  {
        if ( stat.isFile() ) {
          var html = execSync("cat " + path ,{ maxBuffer: 1024000000 });
          res.end(html);
          var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
          console.log( time_stamp + remote_addr + ' requested ' + uri );
        } else {
          // handle path as directory
          if( fs.existsSync( path + "/index.html" ) ){
            var html = execSync("cat " + path + "/index.html" ,{ maxBuffer: 1024000000 });
            res.end(html);
            var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
            console.log( time_stamp + remote_addr + ' requested ' + uri );
          } else {
            res.end("Oops wrong request");
            var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
            console.log( time_stamp + remote_addr + ' requested wrong page ' + uri );
          }
        }
      });
  
    } else {
      res.end("Oops wrong request");
      var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
      console.log( time_stamp + remote_addr + ' requested wrong page ' + uri );
    }
  });
  
  
  server.listen(port, function(){
    process.setuid('small-shell'); 
    var time_stamp = execSync("date \"+%Y-%m-%d %H:%M:%S\"").toString().replace(/\r?\n/g," ");
    console.log( time_stamp + "small-shell web srv started");
  });
  
  /* forward option start
  var http = require("http");
  http.createServer((express()).all("*", function (request, response) {
      response.redirect(`https://${request.hostname}${request.url}`);
  })).listen(80);
  option end */

}
  
