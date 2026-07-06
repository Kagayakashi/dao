class MeridiansController < ApplicationController
  before_action :load_character
  before_action :load_meridians

  def show
  end

  def open
    meridian = find_meridian
    result = meridian.open_next_subpoint!

    if result == :opened
      redirect_to meridians_path, notice: t("meridians.open.notice.opened", name: meridian.localized_name), status: :see_other
    else
      redirect_to meridians_path, alert: t("meridians.open.alert.#{result}"), status: :see_other
    end
  end

  def activate
    meridian = find_meridian

    if meridian.opened_subpoints.zero?
      redirect_to meridians_path, alert: t("meridians.activate.alert.closed"), status: :see_other
    elsif @character.character_meridians.active.where.not(id: meridian.id).count >= Character::ACTIVE_MERIDIAN_LIMIT
      redirect_to meridians_path, alert: t("meridians.activate.alert.limit"), status: :see_other
    elsif meridian.update(active: true)
      redirect_to meridians_path, notice: t("meridians.activate.notice.activated", name: meridian.localized_name), status: :see_other
    else
      redirect_to meridians_path, alert: t("meridians.activate.alert.invalid"), status: :see_other
    end
  end

  def deactivate
    meridian = find_meridian
    meridian.update!(active: false)

    redirect_to meridians_path, notice: t("meridians.deactivate.notice.deactivated", name: meridian.localized_name), status: :see_other
  end

  private

  def load_character
    @character = current_character
  end

  def load_meridians
    existing_meridians = @character.character_meridians.index_by(&:key)

    @meridians = CharacterMeridian.ordered_keys.map do |key|
      existing_meridians[key] || CharacterMeridian.new(character: @character, key:)
    end
  end

  def find_meridian
    key = params[:key].to_s
    raise ActiveRecord::RecordNotFound unless CharacterMeridian::MERIDIANS.key?(key)

    @character.character_meridians.find_or_create_by!(key:)
  end
end
