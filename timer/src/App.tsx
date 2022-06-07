import React, { useEffect } from 'react';
import './App.css';
import {useState} from 'react';
import useWebSocket, { ReadyState } from 'react-use-websocket';

import TimerHistory, {TimerData} from './components/TimerHistory';
import TimerDisplay from './components/TimerDisplay';

function App() {
  const [timerData, setTimerData] = useState<TimerData[]>([]);
  const { /* sendMessage, */ lastJsonMessage, readyState } = useWebSocket('ws://localhost:8888/update');

  useEffect(() => {
    if (lastJsonMessage !== null) {
      setTimerData(prev => [lastJsonMessage, ...prev]);
    }
  }, [lastJsonMessage, setTimerData]);

  useEffect(() => {
    fetch('/timer_latest')
      .then(res => {
        if(res.ok) {
          return res.json();
        }
      })
      .then((data: TimerData[]) => {
        setTimerData(data);
      });
  }, []);

  if(timerData.length === 0) {
    return <p>Loading data...</p>;
  }

  const connectionStatus = {
    [ReadyState.CONNECTING]: 'Connecting',
    [ReadyState.OPEN]: 'Open',
    [ReadyState.CLOSING]: 'Closing',
    [ReadyState.CLOSED]: 'Closed',
    [ReadyState.UNINSTANTIATED]: 'Uninstantiated',
  }[readyState];

  return (
    <div className="App">
      <header className="App-header">
        CurlTimer ({connectionStatus})
      </header>
      <main>
        <TimerDisplay speed={timerData[0].speed} />
        <TimerHistory timerData={timerData} />
      </main>
    </div>
  );
}

export default App;
