class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
      # user ||= User.new # guest user (not logged in)
      if user.present?
	      if user.role.include? 'admin'
	        can :manage, :all
	      elsif user.role.include? 'employee'
	       	can :new, Product
	      elsif user.role.include? 'member'
	       	can :read, Product
	      else
	        can :manage, Product
	      end
      end

    # can :read, :all . # permissions for every user, even if not logged in    
    # if user.present?  # additional permissions for logged in users (they can manage their posts)
    #   can :manage, Post, user_id: user.id 
    #   if user.admin?  # additional permissions for administrators
    #     can :manage, :all
    #   end
    # end
    

    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end