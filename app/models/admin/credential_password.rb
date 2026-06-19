module Admin
  class CredentialPassword
    def self.authenticate?(password)
      return false if password.blank? || password_digest.blank?

      BCrypt::Password.new(password_digest).is_password?(password)
    rescue BCrypt::Errors::InvalidHash
      false
    end

    def self.configured?
      password_digest.present?
    end

    def self.password_digest
      Rails.application.credentials.dig(:admin, :password_digest)
    end
  end
end
