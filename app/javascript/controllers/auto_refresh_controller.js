import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 10000 }
  }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async refresh() {
    if (document.hidden) return

    const response = await fetch(this.urlValue, {
      headers: { "X-Requested-With": "XMLHttpRequest" }
    })

    if (response.ok) this.element.innerHTML = await response.text()
  }
}
