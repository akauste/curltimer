import { useState } from 'react';

export type TimerData = {
  date: string;
  time: string;
  global_id: number;
  speed: number;
  data: { 
    boot_id: number; 
    raw_speed: number;
    ldr_min: number;
    ldr_max: number;
    shot_start: number;
    shot_end: number;
  };

}

const TimerHistory = (props: {timerData: TimerData[]}) => {
  const [showHistory, setShowHistory] = useState(true);
  const [showDebug, setShowDebug] = useState(false);
  const { timerData } = props;

  return <div className="timer-history">
    <button onClick={() => setShowHistory(prev => !prev)}>{showHistory ? 'Hide' : 'Show'} history</button>
    {showHistory && <button onClick={() => setShowDebug(prev => !prev)}>{showDebug ? 'Hide' : 'Show'} debug data</button> }
    {showHistory && <table>
      <thead>
        <tr>
          <th>Time stamp</th>
          <th>GID</th>
          <th>Boot</th>
          <th>Speed m/s</th>
          {showDebug && <>
            <th>Raw speed m/s</th>
            <th>LDR min ... max</th>
            <th>Shot start ... end = duration</th>
          </>}
        </tr>
      </thead>
      <tbody>
        { timerData.map(t => (<tr key={t.global_id}>
          <td>{t.date}  {t.time}</td>
          <td>{t.global_id}</td>
          <td>
            <a href={`/api/timer_set/${ t.data.boot_id }.html`}>{ t.data.boot_id }</a>
				    <a href={`/api/timer_set/${ t.data.boot_id }.xlsx`}><i className="fa fa-file-excel-o" /></a>
          </td>
          <td>{t.speed.toFixed(4)}</td>
          {showDebug && <>
            <td>{t.data.raw_speed}</td>
            <td>{t.data.ldr_min}...{t.data.ldr_max}</td>
            <td>{t.data.shot_start}...{t.data.shot_end} = { t.data.shot_end - t.data.shot_start }</td>
          </>}
        </tr>)) }
      </tbody>
    </table>}
  </div>
}

export default TimerHistory;