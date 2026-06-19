require "test_helper"

module Admin
  class ItemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @character = characters(:one)
      @character.inventory_items.destroy_all
    end

    test "redirects unauthenticated admin to admin sign in" do
      get admin_root_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "creates item for selected character" do
      sign_in_admin

      assert_difference -> { @character.inventory_items.count }, 1 do
        post admin_items_path(locale: :en), params: {
          inventory_item: {
            character_id: @character.id,
            name: "iron_dao_blade",
            power: 25
          }
        }
      end

      assert_redirected_to new_admin_item_path(locale: :en)
      item = @character.inventory_items.order(:created_at).last
      assert_equal "iron_dao_blade", item.name
      assert_equal "weapon", item.equipment_kind
      assert_equal [ { "key" => "power", "value" => 25 } ], item.power_options
    end

    test "does not create item when inventory is full" do
      Character::INVENTORY_SLOTS.times do |index|
        @character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [], metadata: { "slot" => index })
      end
      sign_in_admin

      assert_no_difference -> { @character.inventory_items.count } do
        post admin_items_path(locale: :en), params: {
          inventory_item: {
            character_id: @character.id,
            name: "cloud_ring",
            power: 10
          }
        }
      end

      assert_redirected_to new_admin_item_path(locale: :en)
    end

    private

    def sign_in_admin
      with_admin_authentication(true) do
        post admin_session_path(locale: :en), params: { password: "secret" }
      end
    end

    def with_admin_authentication(result)
      original_method = CredentialPassword.method(:authenticate?)
      CredentialPassword.define_singleton_method(:authenticate?) { |_| result }
      yield
    ensure
      CredentialPassword.define_singleton_method(:authenticate?, original_method)
    end
  end
end
