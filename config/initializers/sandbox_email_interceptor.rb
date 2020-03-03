if Rails.env.staging?
  class SandboxEmailInterceptor
    def self.delivering_email(message)
      message.to = [$EMAIL_OVERRIDE]
      message.subject = "(#{Rails.env}) #{message.subject}"
    end
  end

  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end
