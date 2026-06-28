const PIXEL_SIZE = 20
const content = document.querySelector(".content")

const createRoomInput = document.getElementById("create-room-input")
const createRoomSubmit = document.getElementById("create-room")

createRoomSubmit.addEventListener("click", () => {
  console.log("click")
  const roomName = createRoomInput.value

  navigation.navigate(`/room?room_name=${roomName}`)
})

const results = await fetch("http://localhost:3000")
const data = await results.json()

function drawMap(map, ctx) {
  // Check ImageData
  let currentColor = map[0]
  ctx.fillStyle = currentColor

  map.forEach((color, index) => {
    if (color !== currentColor) {
      currentColor = color
      ctx.fillStyle = currentColor
    }

    const row = Math.floor(index / 8)
    const col = index % 8
    console.log(row, col)
    ctx.fillRect(col * PIXEL_SIZE, row * PIXEL_SIZE, PIXEL_SIZE, PIXEL_SIZE)
  })
}

function createRoomCard(roomName, playerCount, map) {
  const card = document.createElement("div")
  card.classList.add("room-card")

  const mapPreview = document.createElement("canvas")
  mapPreview.height = PIXEL_SIZE * 8
  mapPreview.width = PIXEL_SIZE * 8
  const ctx = mapPreview.getContext("2d")
  drawMap(map, ctx)
  card.appendChild(mapPreview)

  const title = document.createElement("h3")
  const link = document.createElement("a")
  link.textContent = roomName
  link.href = `http://localhost:8000/room?room_name=${encodeURI(roomName)}`

  title.appendChild(link)
  card.appendChild(title)

  const players = document.createElement("p")
  players.textContent = `Players: ${playerCount}`
  card.appendChild(players)

  return card
}

Object.entries(data).forEach(([roomName, data]) => {
  console.log(data)
  content.appendChild(createRoomCard(roomName, data.players, data.map))
})
