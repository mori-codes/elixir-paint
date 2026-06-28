const roomName = new URLSearchParams(document.location.search).get("room_name")
const socket = new WebSocket(`ws://localhost:3000/room/${roomName}`)

socket.addEventListener("open", (event) => {
  socket.send(JSON.stringify({ type: "get" }))
})

socket.addEventListener("message", (event) => {
  try {
    const data = JSON.parse(event.data)
    data.forEach((color, index) => {
      document.getElementById(`square-${index}`).style.backgroundColor = color
    })
  } catch (error) {
    console.log(error, event.data)
  }
})

let selectedButton = document.querySelector('button[data-selected="true"]')
const colorButtons = document.querySelectorAll("button")
colorButtons.forEach((button) =>
  button.addEventListener("click", (event) => {
    selectedButton.removeAttribute("data-selected")
    selectedButton = event.currentTarget
    selectedButton.setAttribute("data-selected", "true")
  }),
)

const board = document.querySelector(".board")

if (board) {
  let id = 0
  for (const i of new Array(64).fill(null)) {
    const node = document.createElement("div")
    node.id = `square-${id}`
    node.style.backgroundColor = "#ffffff"
    node.classList.add("square")

    node.addEventListener("click", (event) => {
      socket.send(
        JSON.stringify({
          type: "set_colors",
          change_color: [
            selectedButton.style.backgroundColor,
            Number(event.currentTarget.id.split("-")[1]),
          ],
        }),
      )
    })

    board.appendChild(node)
    id++
  }
}
