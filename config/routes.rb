Rails.application.routes.draw do
  devise_for :users
  resources :users

  resources :link_lists, :param => :qualified_id, :constraints => { :qualified_id => %r|[^/]+-[^/]+| }, :path => :lists do
    collection do
      post 'import'
    end
  end

  get 'types' => 'link_lists#types'
  get 'types/:ext_id_type' => 'link_lists#index', :constraints => {:ext_id_type => /[[:alnum:]]+/}

  root :to => 'link_lists#index'
end
