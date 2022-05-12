
* Test the deployment of a simple express-react app

# Server
## /server
1. >npm init
2. >npm install express
3. >echo "node_modules" > .gitignore
4. package.json
```json
    ...
  "type": "module",
    "scripts": {
    "start": "node index.js",
  },
  ...
```

5. index.js 
```javascript
import express from 'express'
const [app, port] = [express(), 5000]
app.get('/', (req, res) => res.json({message:'Hello World!'}))
app.listen(port, () => console.log(`Example app listening on port ${port}`))
```
6. >npm run start

# Client
## /server
1. >npx create-react-app client

## /server/client
2. >npm run build
