Rails.application.routes.draw do
  root 'products#index'


  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get '/user/show', to: 'users/registrations#show'
    get '/user/order_list', to: 'users/registrations#order_list'
    get '/user/order_status_select', to: 'users/registrations#order_status_select' 
    get '/user/favorite_list', to: 'users/registrations#favorite_list'
    get '/user/pwd_field', to: 'users/registrations#pwd_field'
    patch '/user/update_field', to: 'users/registrations#update_field'
  end

  resources :products, only: [:index, :show] do
    collection do
      get :index_with_params, path: 'index_with_params/:cat/:subcat', as: 'index_with_params'
      post :heart, path: 'heart/:id', as: 'heart'
    end
  end

  resources :images, only: [:create, :destroy]

  resources :messages, only: [:index, :create]

  resource :carts, only: [:show, :destroy] do
  	collection do
  		post :add, path: 'add/:id', as: 'add'
  		post :change, path: 'change/:id', as: 'change'
		end
	end

  resources :orders, param: :process_id do
    collection do
      get :ship_method, path: 'ship_method', as: 'ship_method'
      get :to_map, path: 'to_map', as: 'to_map'
      post :from_map, path: 'from_map', as: 'from_map'
      get :get_user_data, path: 'get_user_data/:process_id', as: 'get_user_data'
      get :to_ecpay_payment, path: 'to_ecpay_payment/:process_id', as: 'to_ecpay_payment'

      post :from_ecpay_paid, path: 'from_ecpay_paid', as: 'from_ecpay_paid'

      post :payment_result, path: 'payment_result/:process_id', as: 'payment_result'
      get :atm_info, path: 'atm_info/:process_id', as: 'atm_info'
      post :ecpay_atm_account, path: 'ecpay_atm_account', as: 'ecpay_atm_account'
      get :order_revise, path: 'order_revise/:process_id', as: 'order_revise'
      patch :order_update, path: 'order_update/:process_id', as: 'order_update'
      post :order_cancel, path: 'order_cancel/:process_id', as: 'order_cancel'
    end
  end

  namespace :console do
    root 'dashboards#index'
    resources :users, only: [:index, :show, :update]
    resources :orders, only: [:index, :edit, :update] do
      collection do
        post :refund, path: 'refund/:process_id', as: 'refund'
      end
    end
    resources :products, except: [:show] do 
      collection do
        get :get_subcat, path: 'get_subcat', as: 'get_subcat'
        post :update_photo, path: 'update_photo/:id', as: 'update_photo'
      end
    end
    resources :categories, except: [:index, :show] do 
      collection do
        get :subcat_edit, path: 'subcat_edit/:id', as: 'subcat_edit'
        patch :subcat_update, path: 'subcat_update/:id', as: 'subcat_update'
        delete :subcat_destroy, path: 'subcat_destroy/:id', as: 'subcat_destroy'
      end
    end
    resources :warehouses, only: [:index, :new, :create, :edit, :update]
    resources :messages do
      collection do
        get :qanda, path: 'qanda', as: 'qanda'
        post :sort_qanda, path: 'sort_qanda', as: 'sort_qanda'
      end
    end
    resources :offers, only: [:index, :create, :destroy] do
      collection do 
        get :select_range, path: 'select_range', as: 'select_range'
        post :implement_all, path: 'implement_all', as: 'implement_all'
        post :implement_product, path: 'implement_product', as: 'implement_product'
      end
    end
  end
end


