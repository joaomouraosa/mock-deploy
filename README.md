### Express server

#### /server

1. > npm init
2. > npm install express
3. > echo "node_modules" > .gitignore
4. > package.json

```json
{
  "type": "module",
  "scripts": {
    "start": "node index.js",
    "production": "npm run build --prefix client && NODE_ENV=production npm start"
  }
}
```

5. > index.js

```javascript
import express from "express";
import path from "path";
import { fileURLToPath } from "url";
const [app, port] = [express(), 5000];
const __dirname = path.dirname(fileURLToPath(import.meta.url));
app.get("/api/connected", (req, res) => res.json({ message: "Connected!" }));

if (process.env.NODE_ENV === "production") {
  app.use(express.static(`${__dirname}/client/build`));
  app.get("*", (req, res) =>
    res.sendFile(`${__dirname}/client/build/index.html`)
  );
}
app.listen(port, () => console.log(`Listening on ${port}`));
```


### React client

#### /server

1. > npx create-react-app client

#### /server/client

2. > npm run build

3. > package.json

```json
{
  "proxy": "http://localhost:5000"
}
```
