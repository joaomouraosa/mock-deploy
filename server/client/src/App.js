import axios from 'axios';
import React from 'react';

function App() {
  const [connected, setConnected] = React.useState('Not connected');

  React.useEffect(() => {
    getRequest().then((response) => setConnected(response))
  }, []
  );

  const getRequest = async () => {
    try {
      const { data: { message } } = await axios.get("api/connected");
      return message;
    } catch (error) {
      console.log(error);
    }
  }

  return (
    <div className="App">
      <span> {connected} </span>
    </div>
  );
}

export default App;
