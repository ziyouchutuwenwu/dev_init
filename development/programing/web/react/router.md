# router

## 例子

依赖库

```sh
npm install react-router-dom
```

route.tsx

```typescript
import { BrowserRouter as Router, Route, Routes, Link } from "react-router-dom";
import LoginPage from "./login";
import ContentPage from "./content";
import AboutPage from "./about";
import "./route.css";

const RouterDemo = () => (
  <Router>
    <div>
      <nav>
        <Link to="/content">content</Link>
        <Link to="/about">about</Link>
      </nav>
    </div>

    {/* 路由切换以后重新渲染 */}
    <div id="container">
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/content" element={<ContentPage />} />
      </Routes>
    </div>
  </Router>
);

export default RouterDemo;
```

login.tsx

```typescript
import React from "react";

class LoginPage extends React.Component {
  constructor(props: any) {
    super(props);
  }

  render() {
    return (
      <>
        <h2>this is login page</h2>
      </>
    );
  }
}

export default LoginPage;
```

content.tsx

```typescript
import AuthChecker from "./auth";

class ContentPage extends AuthChecker {
  constructor(props: any) {
    super(props);
  }

  render() {
    super.render();

    if (this.isAuthed()) {
      console.log("content authed");
      return (
        <>
          <div> 这是内容页。</div>
        </>
      );
    }
  }
}

export default ContentPage;
```

about.tsx

```typescript
import React from "react";

class AboutPage extends React.Component {
  constructor(props: any) {
    super(props);
  }

  render() {
    return (
      <>
        <h2>this is about page</h2>
      </>
    );
  }
}

export default AboutPage;
```

auth.tsx

```typescript
import React from "react";

class AuthChecker extends React.Component {
  constructor(props: any) {
    super(props);
  }

  isAuthed() {
    const isLoggedIn = localStorage.getItem("token") ? true : false;
    return isLoggedIn;
  }

  render() {
    if (!this.isAuthed()) {
      window.location.href = "/login";
    } else {
      return <></>;
    }
  }
}

export default AuthChecker;
```

route.css

```css
nav a {
  background-color: bisque;
  margin: 5px;
}

#container {
  background-color: greenyellow;
}
```
