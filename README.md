* Test the deployment of a simple express-react app

# server
- npm init
- npm install express

## index.js
{
    import express from 'express'
    const [app, port] = [express(), 5000]
    app.get('/', (req, res) => res.send('Hello World!'))
    app.listen(port, () => console.log(`Example app listening on port ${port}`))
}

## .gitignore
{
    node_modules
}