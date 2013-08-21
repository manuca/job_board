require "cuba/test"
require_relative "../../app"

# Redefine fetch_user method to fake GitHub response

module GitHub
 def self.fetch_user(access_token)
   return { "id"=>"123456", :username=>"johndoe",
     :name=>"John Doe", :email=>"johndoe@gmail.com" }
 end
end

prepare do
  Ohm.flush

  time = Time.new.to_i

  Company.create({ name: "Punchgirls",
          email: "punchgirls@mail.com",
          url: "http://www.punchgirls.com",
          password: "1234" })

  Post.create({ date: time,
        expiration_date: time + (30 * 24 * 60 * 60),
        title: "Java developer",
        description: "Lorem ipsum dolor sit amet,
        consectetur adipiscing elit. Nulla a enim enim.
        Vestibulum nec magna neque. Suspendisse euismod metus dapibus,
        congue sem cursus, elementum urna. Integer lorem mauris,
        ornare pharetra tincidunt nec, mattis commodo diam.
        Ut id cursus felis, nec fringilla libero. Vivamus ullamcorper,
        felis non congue elementum, risus mauris vulputate leo,
        vel consequat urna lacus at tortor. Nullam auctor lorem diam,
        a fringilla felis adipiscing nec. Aliquam sed arcu facilisis,
        porta est sit amet, dapibus quam. Lorem ipsum dolor sit amet,
        consectetur adipiscing elit. Curabitur posuere.",
        company_id: "1" })

  Developer.create({ username: "johndoe",
          github_id: "123456",
          name: "John Doe",
          email: "johndoe@mail.com" })
end

scope do
  test "should inform user of successful adding of post to favorites" do
    post "/github_login/117263273765215762"

    post "/favorite/1"

    follow_redirect!

    assert last_response.body["You have added a post to your favorites!"]

    assert last_response.body["Search job posts and apply with a single click!"]

    get "/favorites"

    assert last_response.body["Java developer"]
  end

  test "should remove job post from favorites" do
    post "/github_login/117263273765215762"

    post "/favorite/1"

    post "/favorite/1"

    get "/favorites"

    assert !last_response.body["Java developer"]
  end

  test "should redirect back to origin favorites" do
    post "/github_login/117263273765215762"

    post "/favorite/1?origin=favorites"

    follow_redirect!

    assert last_response.body["Favorites"]
  end
end
