class ApplicationController < ActionController::Base
  include Authentication
  before_action :redirect_to_default_locale
  before_action :load_global_header_character
  around_action :switch_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale

    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def current_character
    Current.user.character || Current.user.create_character!
  end

  def redirect_to_default_locale
    return if params[:locale].present?
    return unless request.get? && request.format.html?

    redirect_to url_for(request.path_parameters.merge(request.query_parameters).merge(locale: I18n.default_locale, only_path: true))
  end

  def load_global_header_character
    return unless authenticated?

    @global_header_character = Current.user.character
    @global_header_character&.recover_sparring_points!
  end
end
