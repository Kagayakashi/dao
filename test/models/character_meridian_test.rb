require "test_helper"

class CharacterMeridianTest < ActiveSupport::TestCase
  setup do
    @original_config = {
      base_qi_required: Character.base_qi_required,
      realm_qi_growth: Character.realm_qi_growth,
      star_qi_growth: Character.star_qi_growth,
      meridian_qi_cost_multiplier: Character.meridian_qi_cost_multiplier,
      meridian_wen_base_cost: Character.meridian_wen_base_cost,
      meridian_wen_cost_growth: Character.meridian_wen_cost_growth
    }

    Character.base_qi_required = 100
    Character.realm_qi_growth = 1.0
    Character.star_qi_growth = 1.0
    Character.meridian_qi_cost_multiplier = 4
    Character.meridian_wen_base_cost = 5_000
    Character.meridian_wen_cost_growth = 1_500

    @character = characters(:one)
    @character.character_meridians.destroy_all
    @character.update!(realm: 3, star: 1, qi: 0, currency: 20_000, current_health: nil)
  end

  teardown do
    @original_config.each { |name, value| Character.public_send("#{name}=", value) }
  end

  test "opens next subpoint by spending high qi and wen costs" do
    meridian = @character.character_meridians.create!(key: "lung")
    @character.update!(realm: 1, star: 5, qi: 0, currency: 5_000)

    assert_equal :opened, meridian.open_next_subpoint!

    meridian.reload
    @character.reload
    assert_equal 1, meridian.opened_subpoints
    assert_predicate meridian, :active?
    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 0, @character.qi
    assert_equal 0, @character.currency
  end

  test "blocks subpoints above current realm" do
    meridian = @character.character_meridians.create!(key: "kidney", opened_subpoints: 3)

    assert_equal :realm_locked, meridian.open_next_subpoint!
  end

  test "limits active meridians to three" do
    %w[ lung stomach kidney ].each do |key|
      @character.character_meridians.create!(key:, opened_subpoints: 1, active: true)
    end

    fourth = @character.character_meridians.build(key: "liver", opened_subpoints: 1, active: true)

    assert_not fourth.valid?
  end

  test "active meridian bonuses affect character stats" do
    @character.character_meridians.create!(key: "kidney", opened_subpoints: 3, active: true)

    assert_equal 412, @character.cultivation_power
  end
end
