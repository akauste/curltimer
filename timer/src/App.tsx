import React, { useEffect, useRef } from 'react';
import './App.css';
import {useState} from 'react';
import useWebSocket, { ReadyState } from 'react-use-websocket';

import TimerHistory, {TimerData} from './components/TimerHistory';
import TimerDisplay from './components/TimerDisplay';

function App() {
  const [timerData, setTimerData] = useState<TimerData[]>([]);
  const didUnmount = useRef(false);

  const { /* sendMessage, */ lastJsonMessage, readyState } = useWebSocket('ws://localhost:8888/update',  {
    shouldReconnect: (closeEvent) => {
      /*
      useWebSocket will handle unmounting for you, but this is an example of a 
      case in which you would not want it to automatically reconnect
    */
      return didUnmount.current === false;
    },
    reconnectAttempts: 10,
    reconnectInterval: 1000,
  });

  useEffect(() => {
    if (lastJsonMessage !== null && lastJsonMessage.speed && (!timerData || lastJsonMessage.global_id !== timerData[0].global_id)) {
      setTimerData(prev => [lastJsonMessage, ...prev]);
    }
  }, [lastJsonMessage, setTimerData, timerData]);

  useEffect(() => {
    fetch('http://localhost:8888/timer_latest')
      .then(res => {
        if(res.ok) {
          return res.json();
        }
      })
      .then((data: TimerData[]) => {
        setTimerData(data);
      });
  }, []);

  useEffect(() => {
    return () => {
      didUnmount.current = true;
    };
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
