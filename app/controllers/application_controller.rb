require './config/environment'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    set :session_secret, "chris_Perkins_ftw"
    register Sinatra::Flash
  end

  get "/" do
    if logged_in?
      redirect to '/user_profile'
    else
    erb :welcome
    end
  end

  get '/signup' do
    erb :signup
  end


  get '/login' do
    redirect to '/'
  end

  post "/login" do
		user = User.find_by(:username => params[:username])
    if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect to '/user_profile'
    else
    flash[:error] = "User details invalid, please retry"
    redirect to "/login"
    end
  end

  post "/signup" do
    if params[:password] == params[:confirm_password]
      if params[:storyteller] == 'on'
      user = User.new(username: params[:username], password: params[:password], storyteller: true)
      if !user.username.empty? && user.save
        session[:user_id] = user.id
        redirect to '/user_profile'
      else
        flash[:error] = "User details invalid, please retry"
        redirect to "/signup"
      end
    else 
      ser = User.new(username: params[:username], password: params[:password])
        if !user.username.empty? && user.save
          session[:user_id] = user.id
          redirect to '/user_profile'
        else
          flash[:error] = "User details invalid, please retry"
          redirect to "/signup"
        end
    end
    else
      flash[:error] = "Password does not match confirm password, please retry"
      redirect to "/signup" 
    end
  end

  get '/user_profile' do
    if logged_in?
      erb :user_profile
    else 
    login_error
    end
  end

  get '/posts' do 
    if logged_in?
      @posts = Post.all
      erb :posts
    else 
      login_error
    end
  end

  get '/posts/new' do
    if logged_in?
      if current_user.storyteller == true
        erb :new_post_storyteller
      else 
        erb :new_post
      end
    else
      login_error
    end
  end

  post '/posts' do
  post = current_user.posts.build(title: params[:title], content: params[:content])
  if params[:player_access] == "on"
    post.player_access = false
    post.save
  end
  post.save
  redirect to '/posts'
  end

  get '/logout' do
    if logged_in?
      session.clear
      redirect "/"
    else
      login_error
    end
  end

  get '/post/:id' do
    if Post.find(params[:id])
      @post = Post.find(params[:id])
      if @post.player_access== false && current_user.storyteller == false
      flash[:error] = "Sorry, can only be viewed by Storytellers"
      redirect to '/posts'
      else
      erb :show 
      end
    else
      no_post
    end
  end

  get "/post/:id/edit" do
    if logged_in?
      if Post.find(params[:id])
        @post = Post.find(params[:id])
        user = current_user
          if user.id == @post.user_id
          erb :'edit'
          else 
            flash[:error] = "Sorry you do not have permission to do that"
            redirect to '/posts'
          end
      else 
        no_post
      end
    else redirect to '/login'
    end
  end

  patch "/post/:id" do
    @post = Post.find(params[:id])
    binding.pry
    if !params[:post][:content].empty?
    @post.update(title: params[:post][:title].strip, content: params[:post][:content].strip)
    redirect to "/post/#{ @post.id }"
    else redirect to "/post/#{@post.id}/edit"
    end
  end

  delete "/post/:id" do
    post = Post.find(params[:id])
    user = current_user
    if user.id == post.user_id
    post.delete
    redirect to '/posts'
    else 
      flash[:error] = "Sorry you do not have permission to do that"
      redirect to '/posts'
    end
  end


  helpers do
    def logged_in?
      !!session[:user_id]
    end
    
    def current_user
      User.find(session[:user_id])
    end

    def login_error
      flash[:error] = "Please Login"
      redirect to "/"
    end

    def no_post
      flash[:error] = "Sorry, that post does not exist"
      redirect to '/posts'
    end

  end

end
