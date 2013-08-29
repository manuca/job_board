class Guests < Cuba
  define do
    on "signup" do
      on post, param("company") do |params|
        if !params["url"].start_with?("http")
          params["url"] = "http://" + params["url"]
        end

        signup = CompanySignup.new(params)

        on signup.valid? do
          params.delete("password_confirmation")
          company = Company.create(params)
          authenticate(company)

          session[:success] = "You have successfully signed up!"
          res.redirect "/dashboard"
        end

        on signup.errors[:name] == [:not_present] do
          session[:error] = "Company name is required"
          render("company/signup", title: "Sign up", company: params)
        end

        on signup.errors[:email] == [:not_email] do
          session[:error] = "E-mail not valid"
          render("company/signup", title: "Sign up", company: params)
        end

        on signup.errors[:email] == [:not_unique] do
          session[:error] = "This e-mail is already registered"
          render("company/signup", title: "Sign up", company: params)
        end

        on signup.errors[:url] == [:not_url] do
          session[:error] = "URL not valid"
          render("company/signup", title: "Sign up", company: params)
        end

        on signup.errors[:password] == [:not_in_range] do
          session[:error] = "The password length must be between 8 to 32 characters"
          render("company/signup", title: "Sign up", company: params)
        end

        on signup.errors[:password] == [:not_confirmed] do
          session[:error] = "Passwords don't match"
          render("company/signup", title: "Sign up", company: params)
        end

        on default do
          session[:error] = "All fields are required and must be valid"
          render("company/signup", title: "Sign up", company: params)
        end
      end

      on default do
        render("company/signup", title: "Sign up", company: {})
      end
    end

    on "login" do
      on post, param("email"), param("password") do |user, pass|
        if login(Company, user, pass)
          session[:success] = "You have successfully logged in!"
          res.redirect "/dashboard"
        else
          session[:error] = "Invalid email and/or password combination"
          render("company/login", title: "Login", user: user)
        end
      end

      on post, param("email") do |user|
        session[:error] = "No password provided"
        render("company/login", title: "Login", user: user)
      end

      on param("recovery") do
        session[:success] = "Check your e-mail and follow the instructions."
        res.redirect "/login"
      end

      on default do
        render("company/login", title: "Login", user: "")
      end
    end

    on "forgot-password" do
      on get do
        render("forgot-password", title: "Password recovery")
      end

      on post do
        company = Company.fetch(req[:email])

        on company do
          nobi = Nobi::TimestampSigner.new('my secret here')
          signature = nobi.sign(String(company.id))

          Malone.deliver(to: company.email,
            subject: "Password recovery",
            html: "Please follow this link to reset your password: " +
            RESET_URL + "/otp/%s" % signature)

          res.redirect "/login/?recovery=true", 303
        end

        on default do
          session[:error] = "Can't find a user with that e-mail."
          res.redirect("/forgot-password", 303)
        end
      end
    end

    on "otp/:signature" do |signature|
      nobi = Nobi::TimestampSigner.new('my secret here')

      company =
        begin
          company_id = nobi.unsign(signature, max_age: 7200)

          Company[company_id]
        rescue Nobi::BadData
        end

      on company do
        on post, param("company") do |params|
          reset = PasswordRecovery.new(params)

          on reset.valid? do
            company.update(password: reset.password)

            authenticate(company)

            session[:success] = "You have successfully changed
            your password and logged in!"
            res.redirect "/", 303
          end

          on reset.errors[:password] == [:not_in_range] do
            session[:error] = "The password length must be between 8 to 32 characters"
            render("otp", title: "Password recovery",
              company: company, signature: signature)
          end

          on reset.errors[:password] == [:not_confirmed] do
            session[:error] = "Passwords don't match"
            render("otp", title: "Password recovery",
              company: company, signature: signature)
          end

          on default do
            session[:error] = "The password length must be between 8 to 32 characters"
            render("otp", title: "Password recovery",
              company: company, signature: signature)
          end
        end

        on default do
          render("otp", title: "Password recovery",
            company: company, signature: signature)
        end
      end

      on default do
        session[:error] = "Invalid URL. Please try again!"
        res.redirect("/forgot-password")
      end
    end

    on "posts" do
      on default do
        render("posts", title: "Posts")
      end
    end

    on "apply/:id" do |id|
      session[:apply_id] = id

      res.redirect "/github_oauth"
    end

    on "favorite/:id" do |id|
      session[:favorite_id] = id

      res.redirect "/github_oauth"
    end

    on "github_oauth" do
      on param("code") do |code|
        access_token = GitHub.fetch_access_token(code)

        on access_token.nil? do
          session[:error] = "There were authentication problems."
          res.redirect "/"
        end

        on default do
          res.redirect GitHub.login_url(access_token)
        end
      end

      on default do
        res.redirect GitHub.oauth_authorize
      end
    end

    on "github_login/:access_token" do |access_token|
      github_user = GitHub.fetch_user(access_token)

      developer = Developer.fetch(github_user["id"])

      on developer.nil? do
        render("confirm", title: "Confirm your user details",
          github_user: github_user)
      end

      authenticate(developer)

      session[:success] = "You have successfully logged in."
      res.redirect "/dashboard"
    end

    on "confirm" do
      on post, param("developer") do |params|
        login = DeveloperLogin.new(params)

        on login.valid? do
          developer = Developer.create(github_id: params["id"],
            username: params["login"],
            name: params["name"],
            email: params["email"],
            avatar: params["gravatar_id"])

          authenticate(developer)

          session[:success] = "You have successfully logged in!"
          res.redirect "/dashboard"
        end

        on default do
          session[:error] = "All fields are required and must be valid"
          render("confirm", title: "Confirm your user details",
            github_user: params)
        end
      end

      on default do
        render("confirm", title: "Confirm your user details")
      end
    end

    on default do
      res.redirect "/"
    end
  end
end