import http from 'node:http'
import { createReadStream, statSync, existsSync } from 'node:fs'
import { extname, join, normalize } from 'node:path'
const root=join(process.cwd(),'web'); const port=Number(process.env.PORT||5173)
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.ico':'image/x-icon','.webmanifest':'application/manifest+json','.xml':'application/xml; charset=utf-8'}
http.createServer((req,res)=>{
  const u=new URL(req.url||'/',`http://${req.headers.host}`); let pathname=decodeURIComponent(u.pathname)
  if(pathname==='/') pathname='/index.html'
  const file=normalize(join(root,pathname))
  if(!file.startsWith(root)||!existsSync(file)||statSync(file).isDirectory()){res.writeHead(404,{'Content-Type':'text/html; charset=utf-8'});createReadStream(join(root,'404.html')).pipe(res);return}
  res.writeHead(200,{'Content-Type':mime[extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});createReadStream(file).pipe(res)
}).listen(port,()=>console.log(`BlowerFit KR dev server: http://localhost:${port}/`))
