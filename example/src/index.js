import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import "../../src/elm-webaudio.js";

Elm.Main.init({
  node: document.getElementById('root')
});

// registerServiceWorker();

function update() {
  const connections = document.querySelectorAll("svg path");

  Array.prototype.forEach.call(connections, connection => {
    const from = document.getElementById(connection.getAttribute("data-from"));
    const to = document.getElementById(connection.getAttribute("data-to"));
    if (from && to) {
      const fromStyle = window.getComputedStyle(from);
      const toStyle = window.getComputedStyle(to);
      const x1 = parseInt(fromStyle.cx) - 24;
      const y1 = parseInt(fromStyle.cy);
      const x2 = parseInt(toStyle.cx) + 24 + 7;
      const y2 = parseInt(toStyle.cy)
      connection.setAttribute("d", `M ${x1} ${y1} C ${x1 - 20} ${y1} ${x2 + 20} ${y2}  ${x2} ${y2}`);
    };



    if (connection.getAttribute("data-initialized")) {

    } else {
      connection.style.opacity = 1.0;
      connection.setAttribute("data-initialized", "");
    }
  });


  const circles = document.querySelectorAll("svg circle");
  Array.prototype.forEach.call(circles, circle => {
    if (circle.getAttribute("data-initialized")) {

    } else {
      circle.style.opacity = 1.0;
      circle.setAttribute("data-initialized", "");
    }
  });

  window.requestAnimationFrame(update);
}

update();
