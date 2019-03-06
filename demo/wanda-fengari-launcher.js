/*
 * fengari-web.js and wanda.lua must be loaded before this source.
 * After loading this source, call launch() to create and start the interpreter.
 */

function launch(config) {
  config.container.innerHTML = `
    <textarea id="editor" rows="10" cols="80"></textarea>
    <div id="control-panel"></div>
    <button onclick="run()">Run</button>
    <pre id="output"></pre>
  `;

  function makeSelect(container, labelText, optionsArray, fun) {
    var label = document.createElement('label');
    label.innerHTML = labelText;
    container.appendChild(label);
    var select = document.createElement("select");
    for (var i = 0; i < optionsArray.length; i++) {
      var op = document.createElement("option");
      op.value = optionsArray[i].value;
      op.text = optionsArray[i].text;
      select.options.add(op);
    }
    select.onchange = function(e) {
      fun(optionsArray[select.selectedIndex]);
    };
    select.selectedIndex = 0;
    label.appendChild(select);
    return select;
  };

  function selectOptionByText(selectElem, text) {
    var optElem;
    for (var i = 0; optElem = selectElem.options[i]; i++) {
      if (optElem.text === text) {
        selectElem.selectedIndex = i;
        selectElem.dispatchEvent(new Event('change'));
        return;
      }
    }
  }

  var controlPanel = document.getElementById('control-panel');
  var optionsArray = [];
  for (var i = 0; i < examplePrograms.length; i++) {
    optionsArray.push({
      value: examplePrograms[i][1],
      text: examplePrograms[i][0]
    });
  }

  var select = makeSelect(controlPanel, "example program:", optionsArray, function(option) {
    document.getElementById('editor').value = option.value;
  });
  selectOptionByText(select, "fact.wanda");
}

function runWandaProg(progText) {
  // loads the progText into the Lua variable `wandaProg`, then runs a short Lua script

  fengari.interop.push(fengari.L, progText);
  fengari.lua.lua_setglobal(fengari.L, "wandaProg");

  var luaProg = `
    local program = parse_program(wandaProg)
    local result = run_wanda(program, {})
    return fmt(result)
  `;

  return fengari.load(luaProg)();
}

function run() {
  var result = runWandaProg(document.getElementById("editor").value);
  document.getElementById("output").innerHTML = result;
}
