Rails.application.routes.draw do
  root 'products#index'

  devise_for :users

  resources :products
  resources :images, only: [:create, :destroy]

  resource :carts, only: [:show, :destroy] do
  	collection do
  		post :add, path: 'add/:id'
  		post :change, path: 'change/:id'
		end
	end

  resources :orders do
    collection do
      post :ezship, path: 'ezship', as: 'ezship'
    end
  end
end
