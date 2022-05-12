
* Test the deployment of a simple express-react app

# server
1. npm init
2. npm install express
3. npx create-react-app client

## index.js
```javascript
import express from 'express'
const [app, port] = [express(), 5000]
app.get('/', (req, res) => res.json({message:'Hello World!'}))
app.listen(port, () => console.log(`Example app listening on port ${port}`))
```

## .gitignore
```
node_modules
```


# server/client
1. >npm run build
