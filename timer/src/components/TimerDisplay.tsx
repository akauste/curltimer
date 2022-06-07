const TimerDisplay = (props: {speed: number}) => {
  return <div>
    <div className="controls">
      <button>-</button>
      <button>+</button>
      <button>On / Off</button>
    </div>
    <div className="timer-display">
      <span className="time">{props.speed.toFixed(2)}</span>
      <span className="unit">m/s</span>
    </div>
  </div>
};

export default TimerDisplay;