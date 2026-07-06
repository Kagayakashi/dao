class RecalculateCharacterCultivationFromTotalQi < ActiveRecord::Migration[8.1]
  class MigrationCharacter < ActiveRecord::Base
    self.table_name = "characters"
  end

  BASE_QI_REQUIRED = 5_845
  REALM_QI_GROWTH = 30**(1.0 / 4)
  STAR_QI_GROWTH = 1.12
  STARS_PER_REALM = 9

  def up
    MigrationCharacter.find_each do |character|
      realm, star, qi = cultivation_from_total_qi(character.total_experience)

      character.update_columns(level: realm, sublevel: star, experience: qi, updated_at: Time.current)
    end
  end

  def down
    # This repair is intentionally one-way; previous inconsistent cultivation
    # state cannot be reconstructed after recalculation.
  end

  private

  def cultivation_from_total_qi(total_qi)
    realm = 1
    star = 1
    remaining_qi = total_qi.to_i

    loop do
      required_qi = qi_required_for(realm, star)
      break if remaining_qi < required_qi

      remaining_qi -= required_qi
      star += 1

      if star > STARS_PER_REALM
        realm += 1
        star = 1
      end
    end

    [ realm, star, remaining_qi ]
  end

  def qi_required_for(realm, star)
    (BASE_QI_REQUIRED * (REALM_QI_GROWTH**(realm - 1)) * (STAR_QI_GROWTH**(star - 1))).ceil
  end
end
