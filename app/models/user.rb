

class User < AMEE::Authentication::User

  has_and_belongs_to_many :projects
  
  def is_admin?
    admin
  end
  
end
