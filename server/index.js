import express from 'express'
const [app, port] = [express(), 5000]
app.get('/', (req, res) => res.json({message:'Hello World!'}))
app.listen(port, () => console.log(`Example app listening on port ${port}`))
