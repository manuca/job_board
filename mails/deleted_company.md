Dear {{ developer.name }},
We are sorry to inform you that {{ post.company.name }} removed their profile and because of that the following post has been deleted:


{{ post.title }}

Tags: {{ post.tags }}

Location: {{ post.location }}
% if post.remote == "true"
(Work from anywhere)
% else
(On-site only)
% end

Description:
{{ post.description }}


Remember that there are a lot more jobs waiting at http://jobs.punchgirls.com !

Cecilia & Mayn
Punchgirls
team@punchgirls.com
http://twitter.com/punchgirls