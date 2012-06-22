Joosy.Router.consume window.joosy.routes
Joosy.Router.map
  404             : (path) -> alert "Page '#{path}' was not found :("
# '/resources'    :
#   '/'           : Resource.IndexPage
#   '/:id'        : Resource.ShowPage
#   '/:id/edit'   : Resource.EditPage
#   '/new'        : Resource.EditPage