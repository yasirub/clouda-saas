import './App.css';
import SignIn from './components/signIn';
import SignUp from './components/signUp';
function App() {
  return (
    <div className="App">
      <header className="App-header">
        <SignIn/>
        <SignUp/>
      </header>
    </div>
  );
}

export default App;
