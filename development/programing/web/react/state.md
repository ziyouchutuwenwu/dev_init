# state

## 例子

```typescript
import "./App.css";
import React from "react";

interface State {
  count: number;
}

class App extends React.Component {
  state: State = {
    count: 0,
  };

  constructor(props: any) {
    super(props);

    this.increment = this.increment.bind(this);
  }

  increment() {
    this.setState((prevState: State) => ({ count: prevState.count + 1 }));
  }

  decrement = () => {
    this.setState((prevState: State) => ({ count: prevState.count - 1 }));
  };

  render() {
    return (
      <>
        <div>
          <button onClick={this.increment}>inc</button>
        </div>
        <div>count is {this.state.count}</div>
        <div>
          <button onClick={this.decrement}>dec</button>
        </div>
      </>
    );
  }
}

export default App;
```
