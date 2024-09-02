# router

## 例子

依赖库

```sh
npm install react-router-dom
```

app.tsx

```typescript
import { BrowserRouter as Router, Route, Routes, Link } from "react-router-dom";
import "./app.css";

const Home = () => <h2>Home Page</h2>;
const About = () => <h2>About Page</h2>;

const App = () => {
  return (
    <Router>
      <div>
        <nav>
          <Link to="/">Home</Link>
          <Link to="/about">About</Link>
        </nav>
      </div>

      {/* 路由切换以后重新渲染 */}
      <div id="container">
        <Routes>
          <Route path="/about" element={<About />} />
          <Route path="/" element={<Home />} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;
```

app.css

```css
nav a {
  background-color: bisque;
  margin: 5px;
}

#container {
  background-color: greenyellow;
}
```
