import { useEffect, useState } from "react";

const TimerDisplay = (props: {speed: number}) => {
  const [animate, setAnimate] = useState(true);

  useEffect(() => {
    setAnimate(true);
    const t = setTimeout(() => setAnimate(false), 5000);
    return () => { clearTimeout(t); }
  }, [props.speed])

  return <div>
    <div className="controls">
      <button>-</button>
      <button>+</button>
      <button>On / Off</button>
    </div>
    <div className={`timer-display ${animate ? 'timer-animate' : ''}`}>
      <span className="time">{props.speed.toFixed(2)}</span>
      <span className="unit">m/s</span>
    </div>
  </div>
};

export default TimerDisplay;