require "test_helper"

module Admin
  class QiAdjustmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @character = characters(:one)
      @character.update!(realm: 1, star: 1, qi: 0, total_experience: 0)
    end

    test "redirects unauthenticated admin to admin sign in" do
      get new_admin_qi_adjustment_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "shows qi adjustment form" do
      sign_in_admin

      get new_admin_qi_adjustment_path(locale: :en)

      assert_response :success
      assert_select "h1", "Adjust Character Resources"
      assert_select "form[action='#{admin_qi_adjustment_path(locale: :en)}']"
      assert_select "select[name='qi_adjustment[resource]'] option[value='qi']", "Qi"
      assert_select "select[name='qi_adjustment[resource]'] option[value='wen']", "Wen"
      assert_select "select[name='qi_adjustment[resource]'] option[value='liang']", "Liang"
    end

    test "adds qi and recalculates stars" do
      with_character_qi_config do
        sign_in_admin

        post admin_qi_adjustment_path(locale: :en), params: {
          qi_adjustment: {
            character_id: @character.id,
            direction: "add",
            resource: "qi",
            amount: 250
          }
        }

        assert_redirected_to new_admin_qi_adjustment_path(locale: :en)
        @character.reload
        assert_equal 3, @character.star
        assert_equal 50, @character.qi
      end
    end

    test "removes qi and can decrease stars" do
      with_character_qi_config do
        @character.update!(realm: 1, star: 3, qi: 50, total_experience: 250)
        sign_in_admin

        post admin_qi_adjustment_path(locale: :en), params: {
          qi_adjustment: {
            character_id: @character.id,
            direction: "remove",
            resource: "qi",
            amount: 160
          }
        }

        assert_redirected_to new_admin_qi_adjustment_path(locale: :en)
        @character.reload
        assert_equal 1, @character.star
        assert_equal 90, @character.qi
      end
    end

    test "adds wen" do
      sign_in_admin

      post admin_qi_adjustment_path(locale: :en), params: {
        qi_adjustment: {
          character_id: @character.id,
          direction: "add",
          resource: "wen",
          amount: 300
        }
      }

      assert_redirected_to new_admin_qi_adjustment_path(locale: :en)
      assert_equal 300, @character.reload.currency
    end

    test "adds liang" do
      sign_in_admin

      post admin_qi_adjustment_path(locale: :en), params: {
        qi_adjustment: {
          character_id: @character.id,
          direction: "add",
          resource: "liang",
          amount: 2
        }
      }

      assert_redirected_to new_admin_qi_adjustment_path(locale: :en)
      assert_equal 2, @character.reload.donation_currency
    end

    private

    def sign_in_admin
      original_method = CredentialPassword.method(:authenticate?)
      CredentialPassword.define_singleton_method(:authenticate?) { |_| true }
      post admin_session_path(locale: :en), params: { password: "secret" }
    ensure
      CredentialPassword.define_singleton_method(:authenticate?, original_method)
    end

    def with_character_qi_config
      original_base_qi_required = Character.base_qi_required
      original_realm_qi_growth = Character.realm_qi_growth
      original_star_qi_growth = Character.star_qi_growth
      Character.base_qi_required = 100
      Character.realm_qi_growth = 1.0
      Character.star_qi_growth = 1.0
      yield
    ensure
      Character.base_qi_required = original_base_qi_required
      Character.realm_qi_growth = original_realm_qi_growth
      Character.star_qi_growth = original_star_qi_growth
    end
  end
end
