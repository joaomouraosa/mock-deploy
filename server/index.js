import express from 'express'
import path from 'path'
import { fileURLToPath } from 'url';

const [app, port] = [express(), 5000]

const __dirname = path.dirname(fileURLToPath(import.meta.url));

app.get('/api/connected', (req, res) => {
    /* res.set('Access-Control-Allow-Origin', 'http://localhost:3000'); */
    res.json({ message: 'Connected!' })
});

if (process.env.NODE_ENV === 'production') {
    app.use(express.static(`${__dirname}/client/build`));
    app.get('*', (req, res) => res.sendFile(`${__dirname}/client/build/index.html`));
}
app.listen(port, () => console.log(`Example app listening on port ${port}`))
