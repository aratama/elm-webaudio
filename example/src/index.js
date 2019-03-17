import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import "../../src/elm-webaudio.js";

Elm.Main.init({
  node: document.getElementById('root')
});

// registerServiceWorker();
