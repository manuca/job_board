Job Board Auto-notice
=====================

{{ company.name }} just sent you this message:

-----------------------------------------------------------------

{{ body }}

-----------------------------------------------------------------

This message was sent regarding the following job position:

-----------------------------------------------------------------

{{ post.title }}
Company: {{ post.company.name }} ({{ post.company.url }})
Tags: {{ post.tags }}
Location: {{ post.location }}
% if post.remote == "true"
(Work from anywhere)
% else
(On-site only)
% end
Description:
{{ post.description }}

-----------------------------------------------------------------

To respond to this e-mail click on "Reply".
Good luck!

Job Board Team