defmodule AMath.Web.Router do
  use AMath.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AMath.Web do
    pipe_through :browser

    get "/", PageController, :index
    get "/game/:id", PageController, :show
    post "/game", PageController, :create
  end

  
  scope "/api", AMath.Web do
    pipe_through :api
    
    resources "/items", ItemController, only: [:show, :update]
  end
end
