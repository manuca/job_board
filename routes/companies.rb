class Companies < Cuba
  define do
    on "dashboard" do
      render("company/dashboard", title: "Dashboard")
    end

    on "profile" do
      render("company/profile", title: "Profile")
    end

    on "edit/:id" do |id|
      on post, param("company") do |params|
        edit = EditCompanyAccount.new(params)

        if edit.password.empty?
          edit.password = Company[id].crypted_password
          edit.password_confirmation = Company[id].crypted_password
        end

        if edit.valid?
          params.delete("password_confirmation")

          if Company[id].email != edit.email &&
            Company.with(:email, edit.email)
              session[:error] = "E-mail is already registered"
              render("company/edit",
                title: "Edit profile", id: id)
          else
              Company[id].update(params)
              session[:success] = "Your account was successfully updated!"
              res.redirect "/profile"
          end
        else
          if edit.errors == { :password=>[:not_confirmed] }
            session[:error] = "Passwords don't match"
            render("company/edit",
                title: "Edit profile", id: id)
          else
            session[:error] = "Name, E-mail and URL are required and must be valid"
            render("company/edit",
                title: "Edit profile", id: id)
          end
        end
      end

      on default do
        render("company/edit", title: "Edit profile", id: id)
      end
    end

    on "jobs/new" do
      on post, param("post") do |params|
        job = PostJobOffer.new(params)

        if job.valid?
          params[:company_id] = Company[session["Company"]].id
          post = Post.create(params)

          session[:success] = "You have successfully posted a job offer!"
          res.redirect "/dashboard"
        else
          session[:error] = "All fields are required"
          render("company/jobs/new", title: "Post job offer")
        end
      end

      on default do
        render("company/jobs/new", title: "Post job offer")
      end
    end

    on "jobs/remove/:id" do |id|
      Post[id].delete
      session[:success] = "Post successfully removed!"
      res.redirect "/dashboard"
    end

    on "jobs/edit/:id" do |id|
      on post, param("post") do |params|
        job = PostJobOffer.new(params)

        if job.valid?
          Post[id].update(params)

          session[:success] = "Post successfully edited!"
          res.redirect "/dashboard"
        else
          session[:error] = "All fields are required"
          render("company/jobs/edit", title: "Edit post")
        end
      end

      on default do
        render("company/jobs/edit", title: "Edit post", id: id)
      end
    end

    on "jobs" do
      render("jobs", title: "Jobs")
    end

    on "logout" do
      logout(Company)
      session[:success] = "You have successfully logged out!"
      res.redirect "/"
    end

    on default do
      render("company/dashboard", title: "Dashboard")
    end
  end
end