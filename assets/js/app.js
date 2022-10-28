import "phoenix_html"
import { Socket, Presence } from "phoenix"
import { Elm } from "../elm/Main.elm"

var elmProgram = document.querySelector("#elm-program")
if (elmProgram) {
  const socket = new Socket(`/socket`)
  const channel = socket.channel(`game_room:${elmProgram.dataset.gameId}`)
  let presences
  socket.connect()

  const elm = Elm.Main.init({
    node: elmProgram,
    flags: {
      gameId: elmProgram.dataset.gameId,
      host: elmProgram.dataset.gameHost
    }
  })

  const sendToElm = json => elm.ports.messageReceiver.send(json)

  channel.on("new_state", resp => sendToElm({ type: "new_state", detail: resp }))
  channel.on("common_state", resp => sendToElm({ type: "common_state", detail: resp }))
  channel.on("presence_state", resp => {
    if (presences) presences = Presence.syncState(presences, resp)
    else presences = resp

    const players = Object.values(presences).map(p => p.metas[0])
    console.log("presence_state", players)
    sendToElm({ type: "presence_state", detail: players })
  })
  channel.on("presence_diff", resp => {
    if (presences) presences = Presence.syncDiff(presences, resp)
    else presences = resp

    const players = Object.values(presences).map(p => p.metas[0])
    console.log("presence_diff", presences)
    sendToElm({ type: "presence_diff", detail: players })
  })
  channel.join()
    .receive("ok", resp => sendToElm({ type: "joined", detail: resp }))
    .receive("error", resp => { console.log("err", resp) })

  elm.ports.sendMessage.subscribe(({ type, detail }) => {
    channel.push(type, detail)
  })
}
