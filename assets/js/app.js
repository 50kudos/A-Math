import "phoenix_html"
import { Socket } from "phoenix"
import { Elm } from "../elm/Main.elm"

var elmProgram = document.querySelector("#elm-program")
if (elmProgram) {
  const socket = new Socket(`/socket`)
  const channel = socket.channel(`game_room:${elmProgram.dataset.gameId}`)
  socket.connect()

  channel.join()
    .receive("ok", resp => { console.log(resp) })
    .receive("error", resp => { console.log("err", resp) })


  Elm.Main.init({
    node: elmProgram,
    flags: {
      gameId: elmProgram.dataset.gameId,
      host: elmProgram.dataset.gameHost
    }
  })

  // Elm.Main.ports.sendMessage.subscribe(function(message) {
  //   console.log(message)
  // })
}
