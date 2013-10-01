# coding: utf-8
class BaseMailer < ActionMailer::Base
  default :from => "no-reply@community.zirannanren.com"
  default :charset => "utf-8"
  default :content_type => "text/html"

  layout 'mailer'
  helper :topics, :users
end
