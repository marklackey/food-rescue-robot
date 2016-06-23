if Rails.env.development? || Rails.env.test?
  Webapp::Application.config.secret_token = 'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
else
  Webapp::Application.config.secret_token = ENV['SECRET_KEY_BASE']
end

