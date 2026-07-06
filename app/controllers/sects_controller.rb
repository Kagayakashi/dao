class SectsController < ApplicationController
  PER_PAGE = 10

  before_action :load_character

  def show
  end

  def leaderboard
    @sect_key = leaderboard_sect_key
    @page = [ params[:page].to_i, 1 ].max
    @total_count = Character.where(sect_key: @sect_key).count
    @total_pages = [ (@total_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = @total_pages if @page > @total_pages
    @rank_offset = (@page - 1) * PER_PAGE
    @characters = sect_leaderboard_characters.limit(PER_PAGE).offset(@rank_offset)
  end

  def join
    result = @character.join_sect!(params[:sect_key])

    if result == :joined
      redirect_to sect_path, notice: t("sects.join.notice.joined", name: @character.sect_name), status: :see_other
    else
      redirect_to sect_path, alert: t("sects.join.alert.#{result}"), status: :see_other
    end
  end

  def task
    return redirect_to sect_path, alert: t("sects.task.alert.expedition_active"), status: :see_other if @character.spirit_expedition_active?

    result = @character.perform_sect_daily_task!

    if result
      redirect_to sect_path, notice: t("sects.task.notice.completed", qi: helpers.resource_amount_with_bonus(base: result[:base_qi], bonus: result[:qi_bonus]), wen: helpers.resource_amount_with_bonus(base: result[:base_wen], bonus: result[:wen_bonus]), contribution: helpers.number_with_delimiter(result[:contribution])), status: :see_other
    else
      redirect_to sect_path, alert: t("sects.task.alert.unavailable"), status: :see_other
    end
  end

  def donate
    result = @character.donate_to_sect!(amount: donation_amount)

    if result.is_a?(Hash) && result[:status] == :donated
      redirect_to sect_path, notice: t("sects.donate.notice.donated", contribution: helpers.number_with_delimiter(result[:contribution])), status: :see_other
    else
      redirect_to sect_path, alert: t("sects.donate.alert.#{result}"), status: :see_other
    end
  end

  def promote
    result = @character.promote_sect_rank!

    if result == :promoted
      redirect_to sect_path, notice: t("sects.promote.notice.promoted", rank: @character.sect_rank_name), status: :see_other
    else
      redirect_to sect_path, alert: t("sects.promote.alert.#{result}"), status: :see_other
    end
  end

  private

  def load_character
    @character = current_character
  end

  def donation_amount
    params[:amount].presence || 1
  end

  def leaderboard_sect_key
    requested_key = params[:sect_key].to_s
    return requested_key if Character::SECTS.key?(requested_key)
    return @character.sect_key if @character.sect_joined?

    Character::SECTS.keys.first
  end

  def sect_leaderboard_characters
    Character.where(sect_key: @sect_key).order(sect_contribution: :desc, sect_rank: :desc, total_experience: :desc, id: :asc)
  end
end
