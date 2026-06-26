module ApplicationHelper
  def alternate_locale
    I18n.locale == :ru ? :en : :ru
  end

  def language_switch_path(locale = alternate_locale)
    url_for(request.path_parameters.merge(request.query_parameters).merge(locale:, only_path: true))
  rescue ActionController::UrlGenerationError
    root_path(locale:)
  end

  def cultivation_icon(name, class_name: "thematic-icon")
    paths = cultivation_icon_paths.fetch(name.to_sym)

    tag.svg(
      class: class_name,
      viewBox: "0 0 24 24",
      role: "img",
      aria: { hidden: true },
      focusable: "false"
    ) do
      safe_join(paths)
    end
  end

  def sparring_recovery_countdown(character)
    due_at = character.sparring_recovery_due_at
    return "00:00" unless due_at

    seconds = [ (due_at - Time.current).ceil, 0 ].max
    format("%02d:%02d", seconds / 60, seconds % 60)
  end

  def expedition_countdown(character)
    return unless character.spirit_expedition_active?

    seconds = [ (character.spirit_expedition_ends_at - Time.current).ceil, 0 ].max
    format("%02d:%02d", seconds / 3600, (seconds % 3600) / 60)
  end

  def unread_news?(character)
    NewsPost.unread_by(character).exists?
  end

  private

  def cultivation_icon_paths
    @cultivation_icon_paths ||= {
      scroll: [
        icon_path("M7 5.5h10a2 2 0 0 1 2 2v10.5H8a3 3 0 0 1-3-3V7.5a2 2 0 0 1 2-2Z"),
        icon_path("M8 18a3 3 0 0 0 0-6H5"),
        icon_path("M10 9h5M10 12h6")
      ],
      qi: [
        icon_path("M12 3c2.4 2.1 3.6 4.3 3.6 6.6 0 2.2-1.2 4-3.6 5.4-2.4-1.4-3.6-3.2-3.6-5.4C8.4 7.3 9.6 5.1 12 3Z"),
        icon_path("M7 17.5c1.2 1 2.9 1.5 5 1.5s3.8-.5 5-1.5"),
        icon_path("M12 8v4")
      ],
      mountain: [
        icon_path("M3 19 9.5 8.5 13 14l2-3 6 8H3Z"),
        icon_path("M9.5 8.5 10.5 13l2.5 1")
      ],
      star: [
        icon_path("m12 3 2.3 5.1 5.5.6-4.1 3.8 1.2 5.5L12 15.2 7.1 18l1.2-5.5-4.1-3.8 5.5-.6L12 3Z")
      ],
      trophy: [
        icon_path("M8 4h8v4a4 4 0 0 1-8 0V4Z"),
        icon_path("M8 6H5.5A2.5 2.5 0 0 0 8 10"),
        icon_path("M16 6h2.5A2.5 2.5 0 0 1 16 10"),
        icon_path("M12 12v4M9 20h6M10 16h4")
      ],
      satchel: [
        icon_path("M7 8h10l1 11H6L7 8Z"),
        icon_path("M9 8a3 3 0 0 1 6 0"),
        icon_path("M9 12h6")
      ],
      coin: [
        icon_path("M12 5a7 3 0 1 1 0 6 7 3 0 0 1 0-6Z"),
        icon_path("M5 8v5c0 1.7 3.1 3 7 3s7-1.3 7-3V8"),
        icon_path("M5 13v3c0 1.7 3.1 3 7 3s7-1.3 7-3v-3")
      ],
      jade: [
        icon_path("M12 3 19 8.5 16.4 18H7.6L5 8.5 12 3Z"),
        icon_path("M5 8.5h14M9 8.5l3 9.5 3-9.5"),
        icon_path("M9 8.5 12 3l3 5.5")
      ],
      sword: [
        icon_path("M14 4h6v6L9 21l-6-6L14 4Z"),
        icon_path("m14 4 6 6M7 17l3-3M5 13l6 6")
      ],
      lantern: [
        icon_path("M9 4h6M8 7h8l-1 9H9L8 7Z"),
        icon_path("M10 16h4M12 4v3M9 20h6"),
        icon_path("M10 10c.7.7 1.3 1.4 2 2 .7-.6 1.3-1.3 2-2")
      ],
      key: [
        icon_path("M14.5 8.5a4 4 0 1 1-2.2 3.6L4 20.5V17h3v-3h3l2.3-2.3"),
        icon_path("M15.5 7.5h.1")
      ],
      spark: [
        icon_path("M12 3v5M12 16v5M3 12h5M16 12h5"),
        icon_path("M7.8 7.8 5.5 5.5M16.2 16.2l2.3 2.3M16.2 7.8l2.3-2.3M7.8 16.2l-2.3 2.3")
      ],
      clock: [
        icon_path("M12 4a8 8 0 1 1 0 16 8 8 0 0 1 0-16Z"),
        icon_path("M12 8v4l2.5 1.5")
      ],
      bell: [
        icon_path("M6.5 17h11"),
        icon_path("M9 17a3 3 0 0 0 6 0"),
        icon_path("M7.5 17c1-1.2 1.5-2.7 1.5-4.5V10a3 3 0 0 1 6 0v2.5c0 1.8.5 3.3 1.5 4.5"),
        icon_path("M12 5V3.5")
      ]
    }
  end

  def icon_path(d)
    tag.path(
      d: d,
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "1.7",
      "stroke-linecap": "round",
      "stroke-linejoin": "round"
    )
  end
end
