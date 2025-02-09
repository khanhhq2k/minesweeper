import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Minesweeper controller connected")
    // Prevent context menu on right click for the game board
    this.element.addEventListener('contextmenu', (e) => {
      e.preventDefault()
    })
  }

  handleClick(event) {
    event.preventDefault()
    const button = event.currentTarget
    const row = button.dataset.row
    const col = button.dataset.col
    this.makeMove(row, col, false)
  }

  handleRightClick(event) {
    event.preventDefault()
    event.stopPropagation()
    const button = event.currentTarget
    const row = button.dataset.row
    const col = button.dataset.col
    console.log("Right click detected:", row, col)
    this.makeMove(row, col, true)
  }

  makeMove(row, col, flag) {
    console.log(`Making move: row=${row}, col=${col}, flag=${flag}`)
    const gameId = window.location.pathname.split('/')[2]
    
    fetch(`/games/${gameId}/click`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ row, col, flag })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      console.log("Move response:", data)
      window.location.reload()
    })
    .catch(error => {
      console.error('Error:', error)
    })
  }
}